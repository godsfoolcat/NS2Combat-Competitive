function PlayingTeam:GetHasTeamLost()
    -- Don't bother with the original - we just set our own logic here.
	-- You can lose with cheats on (testing purposes)
	if(GetGamerules():GetGameStarted()) then
    
        -- Team can't respawn or last Command Station or Hive destroyed
        local numCommandStructures = self:GetNumAliveCommandStructures()
        
        if  ( numCommandStructures == 0 ) or
            ( self:GetNumPlayers() == 0 ) or
            self:GetHasConceded()  then

            return true
            
        end
            
    end

    return false

end

function PlayingTeam:SpawnInitialStructures(techPoint)
    -- Dont Spawn RTS or Cysts
        
    ASSERT(techPoint ~= nil)

    -- Spawn hive/command station at team location
    local commandStructure = techPoint:SpawnCommandStructure(self:GetTeamNumber())
    assert(commandStructure ~= nil)
    commandStructure:SetConstructionComplete()
    
    -- Use same align as tech point.
    local techPointCoords = techPoint:GetCoords()
    techPointCoords.origin = commandStructure:GetOrigin()
    commandStructure:SetCoords(techPointCoords)
    
    --if commandStructure:isa("Hive") then
      --  commandStructure:SetFirstLogin()
    --end
	
	-- Set the command station to be occupied.
	if commandStructure:isa("CommandStation") then
		commandStructure.occupied = true
		--commandStructure:UpdateCommanderLogin(true)
	end
	
	return tower, commandStructure
    
end

local kSpawnWiggleRoom = 0.5
function PlayingTeam:RespawnAllDeadWaitingPlayers()
    local deadPlayers = self:GetSortedRespawnQueue()
    local time = Shared.GetTime()
    for i = 1, #deadPlayers do
        local deadPlayer = deadPlayers[ i ]
        if deadPlayer.nextRespawnTime and deadPlayer.nextRespawnTime - kSpawnWiggleRoom <= time then
            self:RemovePlayerFromRespawnQueue( deadPlayer )
            local success, newPlayer = self:SpawnPlayer( deadPlayer)
            if success then newPlayer:SetCameraDistance( 0 ) end
        end
    end
end

-- Respawn timers.
function PlayingTeam:Update(timePassed)

	if self.lastRespawnTime == nil then 
		self:ResetSpawnTimer()
	end
	
    self:UpdateVotes()
	
    -- this was using Spectators, which aparently fixed a spawn bug...?
	local players = self:GetSortedRespawnQueue()
	
	-- Spawn all players that are ready in waves
    local respawnTime = self:GetNextSpawnTime()
    local timeToSpawn = (respawnTime <= Shared.GetTime())
    
    self:GetInfoEntity():SetNextRespawn(respawnTime)
    
    if timeToSpawn then
        
        self:RespawnAllDeadWaitingPlayers()
        
        self:ResetSpawnTimer()
        
        
    else
        -- Send any 'waiting to respawn' messages (normally these only go to AlienSpectators)
        for _, player in ipairs(self:GetPlayers()) do
            if not player.waitingToSpawnMessageSent then
                if player:GetIsAlive() == false then
                    SendPlayersMessage({ player }, kTeamMessageTypes.SpawningWait)
                    player.waitingToSpawnMessageSent = true
                    player.timeWaveSpawnEnd = self.nextSpawnTime
                end
            end
        end
    end

    
end


local oldPutPlayerInRespawnQueue = PlayingTeam.PutPlayerInRespawnQueue
function PlayingTeam:PutPlayerInRespawnQueue(player)
    oldPutPlayerInRespawnQueue(self, player)
    player:SetRespawnTime(self:GetNextSpawnTime() + self:GetSpawnInterval())
end

function PlayingTeam:ResetSpawnTimer()

	-- Reset the spawn timer
	self.lastRespawnTime = Shared.GetTime()
			
end


function PlayingTeam:GetSpawnInterval()

    if GetHasTimelimitPassed() then
        return kCombatOvertimeRespawnTimer
    end
    return kCombatRespawnTimer
    
end
function PlayingTeam:GetNextSpawnTime()
    if not self.lastRespawnTime then return 0 end
    
    return self.lastRespawnTime + self:GetSpawnInterval()
    
end


function PlayingTeam:SpawnPlayer(player)

    local success = false
	local newPlayer

	player.isRespawning = true
	SendPlayersMessage({ player }, kTeamMessageTypes.Spawning)

    if Server then
        
        if player.SetSpectatorMode then
            player:SetSpectatorMode(kSpectatorMode.Following)
        end
  
    end

    if player.combatTable and player.combatTable.giveClassAfterRespawn then
        success, newPlayer  = self:ReplaceRespawnPlayer(player, nil, nil, player.combatTable.giveClassAfterRespawn)
    else
		-- Spawn normally
        success, newPlayer = self:ReplaceRespawnPlayer(player, nil, nil)
    end
	
	if success then
		self:RemovePlayerFromRespawnQueue(player)

		-- Give any upgrades back
        newPlayer:GiveUpsBack()    
	
        -- Make a nice effect when you spawn.
		-- Aliens hatch due the CoEvolve function
        if newPlayer:isa("Marine") or newPlayer:isa("Exo") then
            newPlayer:TriggerEffects("infantry_portal_spawn")
        end
		newPlayer:TriggerEffects("spawnSoundEffects")
		
		-- Remove the third-person mode (bug introduced in 216).
		newPlayer:SetCameraDistance(0)
		
		--give him spawn Protect (dont set the time here, just that spawn protect is active)
		newPlayer:SetSpawnProtect()
		
		-- always switch to first weapon
		newPlayer:SwitchWeapon(1)
    end

    return success, newPlayer

end

-- Another copy job I'm afraid...
-- The default spawn code just isn't strong enough for us. Give it a dose of coffee.
-- Call with origin and angles, or pass nil to have them determined from team location and spawn points.
function PlayingTeam:RespawnPlayer(player, origin, angles)

    local success = false
    local initialTechPoint = Shared.GetEntity(self.initialTechPointId)
    
    if origin ~= nil and angles ~= nil then
        success = Team.RespawnPlayer(self, player, origin, angles)
    elseif initialTechPoint ~= nil then
    
        -- Compute random spawn location
        local capsuleHeight, capsuleRadius = player:GetTraceCapsule()
		local spawnOrigin

	    -- Try it 10 times here
		for index = 1, 10 do
			spawnOrigin = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, initialTechPoint:GetOrigin(), kSpawnMinDistance, 15, EntityFilterAll())
			if spawnOrigin ~= nil then
				break
			end
		end
		
        if spawnOrigin ~= nil then
        
            -- Orient player towards tech point
            local lookAtPoint = initialTechPoint:GetOrigin() + Vector(0, 5, 0)
            local toTechPoint = GetNormalizedVector(lookAtPoint - spawnOrigin)
            success = Team.RespawnPlayer(self, player, spawnOrigin, Angles(GetPitchFromVector(toTechPoint), GetYawFromVector(toTechPoint), 0))

            if success then
                SetPlayerStartingLocation(player)
            end
        else
        
			player:SendDirectMessage("No room to spawn. You should spawn in the next wave instead!")
            Print("PlayingTeam:RespawnPlayer: Couldn't compute random spawn for player. Will retry at next wave...\n")
			-- Escape the player's name here... names like Sandwich% cause a crash to appear here!
			local escapedPlayerName = string.gsub(player:GetName(), "%%", "")
			Print("PlayingTeam:RespawnPlayer: Name: " .. escapedPlayerName .. " Class: " .. player:GetClassName())
            
        end
        
    else
        Print("PlayingTeam:RespawnPlayer(): No initial tech point.")
    end

    return success

end
