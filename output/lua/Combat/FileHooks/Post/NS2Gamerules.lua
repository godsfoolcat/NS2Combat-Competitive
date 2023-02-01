function NS2Gamerules:GetHasTimelimitPassed()
	if self:GetGameStarted() then
		return Shared.GetTime() - self:GetGameStartTime() >= kCombatTimeLimit
	end

	return false
end

function UpdateUpgradeCountsForTeam(gameRules, teamIndex)

	--Seems these are occasionally invalid? idk..
	if teamIndex < 0 or teamIndex > 3 then
		--Invalid
		return
	end

	-- Get the number of players on the team who have the upgrade
	local oldCounts = gameRules.UpgradeCounts[teamIndex]
	local teamPlayers = GetEntitiesForTeam("Player", teamIndex)

	-- Reset the upgrade counts
	gameRules.UpgradeCounts[teamIndex] = {}
	for _, upgrade in ipairs(GetAllUpgrades(teamIndex)) do
		gameRules.UpgradeCounts[teamIndex][upgrade:GetId()] = 0
	end

	-- Recalculate the upgrade counts.
	for _, teamPlayer in ipairs(teamPlayers) do

		-- Skip dead players
		if (teamPlayer:GetIsAlive()) then

			local playerTechTree = teamPlayer:GetCombatTechTree()
			for _, upgrade in ipairs(playerTechTree) do
				-- Update the count for this upgrade.
				gameRules.UpgradeCounts[teamIndex][upgrade:GetId()] = gameRules.UpgradeCounts[teamIndex][upgrade:GetId()] + 1
			end

		end

	end

	-- Updates for each player.
	for _, upgrade in ipairs(GetAllUpgrades(teamIndex)) do
		local upgradeId = upgrade:GetId()
		local upgradeCount = gameRules.UpgradeCounts[teamIndex][upgradeId]

		-- Send any updates to all players
		if upgradeCount ~= oldCounts[upgradeId] then
			for _, teamPlayer in ipairs(teamPlayers) do
				SendCombatUpgradeCountUpdate(teamPlayer, upgradeId, upgradeCount)
			end
		end

	end

end

-- Don't do this too often - it is expensive!
local function UpdateUpgradeCounts(gameRules)

	UpdateUpgradeCountsForTeam(gameRules, kTeam1Index)
	UpdateUpgradeCountsForTeam(gameRules, kTeam2Index)

	-- Return true to keep the loop going.
	return true

end

local oldOnCreate = NS2Gamerules.OnCreate
function NS2Gamerules:OnCreate()

	oldOnCreate(self)

	self.UpgradeCounts = {}
	self.UpgradeCounts[kTeam1Index] = {}
	for _, upgrade in ipairs(GetAllUpgrades(kTeam1Index)) do
		self.UpgradeCounts[kTeam1Index][upgrade:GetId()] = 0
	end

	self.UpgradeCounts[kTeam2Index] = {}
	for _, upgrade in ipairs(GetAllUpgrades(kTeam2Index)) do
		self.UpgradeCounts[kTeam2Index][upgrade:GetId()] = 0
	end

	-- Recalculate these every half a second.
	self:AddTimedCallback(UpdateUpgradeCounts, kCombatUpgradeUpdateInterval)
	
	if self.gameInfo:GetIsDedicated() then
		self:SetMaxBots(kCombatFillerBots, false)
	end

end

-- Free the lvl when changing Teams
local oldJoinTeam = NS2Gamerules.JoinTeam
function NS2Gamerules:JoinTeam(player, newTeamNumber, ...)

	local success, newPlayer = oldJoinTeam(self, player, newTeamNumber, ...)

	if not success then
		return success, newPlayer
	end

	-- Only reset things like techTree, scan, camo etc.
	newPlayer:CheckCombatData()
	local lastTeamNumber = newPlayer.combatTable.lastTeamNumber
	newPlayer:Reset_Lite()

	--newPlayer.combatTable.xp = player:GetXp()
	-- if the player joins the same team, subtract one level
	if lastTeamNumber == newTeamNumber then
		if newPlayer:GetLvl() >= kCombatPenaltyLevel + 1 then
			local newXP = Experience_XpForLvl(newPlayer:GetLvl()-1)
			newPlayer.score = newXP
			newPlayer.combatTable.lvl = newPlayer:GetLvl()
			newPlayer:SendDirectMessage( "You lost " .. kCombatPenaltyLevel .. " level for rejoining the same team!")
		end
	end
	newPlayer:AddLvlFree(newPlayer:GetLvl() - 1 + kCombatStartUpgradePoints)

	--set spawn protect
	newPlayer:SetSpawnProtect()

	-- Send upgrade updates for each player.
	if newTeamNumber == kTeam1Index or newTeamNumber == kTeam2Index then
		for _, upgrade in ipairs(GetAllUpgrades(newTeamNumber)) do
			local upgradeId = upgrade:GetId()
			local upgradeCount = self.UpgradeCounts[newTeamNumber][upgradeId]

			SendCombatUpgradeCountUpdate(newPlayer, upgradeId, upgradeCount)

		end
	end

	return success, newPlayer
end

-- If the client connects, send him the welcome Message
-- Also grant average XP.
local oldOnClientConnect = NS2Gamerules.OnClientConnect
function NS2Gamerules:OnClientConnect(client)

	oldOnClientConnect(self, client)

	local player = client:GetControllingPlayer()
	player:CheckCombatData()

	for _, message in ipairs(combatWelcomeMessage) do
		player:SendDirectMessage(message)
	end

	-- Give the player the average XP of all players on the server.
	if GetGamerules():GetGameStarted() then
		player.combatTable.setAvgXp = true
		local avgXp = Experience_GetAvgXp(player)
		-- Send the avg as a message to the player (%d doesn't work with SendDirectMessage)
		if avgXp > 0 then
			player:SendDirectMessage("You joined the game late... you will get some free Xp when you join a team!")
		end
	end

end

function NS2Gamerules:UpdateWarmUp()
	-- Just make warmup and notStarted the same thing
	local gameState = self:GetGameState()
	if gameState == kGameState.NotStarted then
		self:SetGameState(kGameState.WarmUp)
	end
end

local lastTimeXPRebalanced = 0
local overTimeMessageSent = false
-- After a certain amount of time the aliens need to win (except if it's marines vs marines).
local oldOnUpdate = NS2Gamerules.OnUpdate
function NS2Gamerules:OnUpdate(timePassed)
	oldOnUpdate(self, timePassed)

	if self:GetGameState() == kGameState.Started then
		if self:GetHasTimelimitPassed() then
			if not kCombatAllowOvertime then
				local winner = self:GetTeam(kCombatDefaultWinner)
				self:EndGame(winner)
			elseif not overTimeMessageSent then
			-- Send the last stand sound to every player
				for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
					Server.PlayPrivateSound(player, CombatEffects.kLastStandAnnounce, player, 1.0, Vector(0, 0, 0))
					player:SendDirectMessage("OVERTIME!!")
					player:SendDirectMessage("Structures cannot be repaired!")
					player:SendDirectMessage("Spawn times have been increased!")
				end
				overTimeMessageSent = true
			end
		end

		-- Periodic events...
		local gameLength = Shared.GetTime() - self:GetGameStartTime()
		if gameLength ~= lastTimeXPRebalanced then
			-- Balance the teams once every 5 minutes or so...
			if gameLength % kCombatRebalanceInterval == 0 then
				local avgXp = Experience_GetAvgXp()
				for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
					-- Ignore players that are not on a team.
					if player:GetIsPlaying() then
						player:BalanceXp(avgXp)
					end
				end
			end

			lastTimeXPRebalanced = gameLength
		end
	else
		lastTimeXPRebalanced = 0
		overTimeMessageSent = false
	end


end

local kCombatPregameLength = 15
function NS2Gamerules:GetPregameLength()

    local preGameTime = kCombatPregameLength
    if Shared.GetCheatsEnabled() then
        preGameTime = 0
    end
    
    return preGameTime
    
end


function NS2Gamerules:SpawnedARC()
	if not self.notified_about_arcs then
		self.notified_about_arcs = true
		SendGlobalChatMessage("The Marines have spawned an ARC!")
	end
end

function NS2Gamerules:GetNumConnecting()

	local numTotalPlayers = Server.GetNumPlayersTotal and Server.GetNumPlayersTotal() or 0
	local numPlaying = Server.GetNumPlayers and Server.GetNumPlayers() or 0
	
	return numTotalPlayers - numPlaying
	
end

local kWaitForConnectingTime = 30
function NS2Gamerules:CheckGameStart()

	
	if self:GetGameState() <= kGameState.PreGame then

		-- Start pre-game when both teams have players or when once side does if cheats are enabled
		local team1Players = self.team1:GetNumPlayers()
		local team2Players = self.team2:GetNumPlayers()
		
		local waitingForConnecting = false
		if self:GetNumConnecting() > 0 and Shared.GetTime() < kWaitForConnectingTime then
			waitingForConnecting = true
		end
		
		if waitingForConnecting and team1Players > 0 and team2Players > 0 and not self.sentWaitingForConnectingMessage then
			self.sentWaitingForConnectingMessage = true
			local extraTime = math.ceil(kWaitForConnectingTime - Shared.GetTime())
			SendGlobalChatMessage(string.format("Players still connecting. Waiting %s seconds for them to connect.", extraTime))
		end
		
		if (not waitingForConnecting and team1Players > 0 and team2Players > 0) or 
		   (Shared.GetCheatsEnabled() and (team1Players > 0 or team2Players > 0)) then
			-- Prevent auto round start if CompMode set
			if kCombatCompMode then
				if self:GetGameState() >= kGameState.PreGame then
					self:SetGameState(kGameState.WarmUp)
				end
			else
				if self:GetGameState() < kGameState.PreGame then
				   self:SetGameState(kGameState.PreGame)
				
                -- TODO: Put this on the client side so we can translate it
                SendGlobalChatMessage(string.format("Game is starting in %s seconds!", self:GetPregameLength()))
			end

		else
			if self:GetGameState() == kGameState.PreGame then
				self:SetGameState(kGameState.WarmUp)
                SendGlobalChatMessage("Game start aborted. Join teams to start the game.")
			end
		end

	end

end

-- Fix for certain combat maps not assigning the techpointsorrectly
local oldChooseTechPoint = NS2Gamerules.ChooseTechPoint
function NS2Gamerules:ChooseTechPoint(techPoints, teamNumber)
	-- special case for combat maps
	if #techPoints == 1 then
		return techPoints[1]
	end

	if #techPoints == 2 then
		for i = 1, 2 do
			local currentTechPoint = techPoints[i]
			if currentTechPoint:GetTeamNumberAllowed() == teamNumber then
				table.removevalue(techPoints, currentTechPoint)
				return currentTechPoint
			end
		end
	end

	return oldChooseTechPoint(self, techPoints, teamNumber)
end
