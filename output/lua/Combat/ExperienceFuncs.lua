Script.Load("lua/Combat/CombatUpgrade.lua")
Script.Load("lua/Combat/CombatAlienUpgrade.lua")
Script.Load("lua/Combat/CombatMarineUpgrade.lua")

-- Todo: Level should be a player value
-- Returns the average XP of all active players.
function Experience_GetAvgXp(ignorePlayer)

    local avgXp = 0
    local allXp = 0
    local playerNumbers = 0
    
    for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
		-- Ignore players that are not on a team.
		if (player ~= ignorePlayer) and (player:GetTeamNumber() >= 1) and (player:GetTeamNumber() <= 2) then
			allXp = allXp + player:GetXp()
			playerNumbers = playerNumbers + 1
		end
    end
    
    if allXp > 0 and playerNumbers > 0 then
        avgXp = math.floor((allXp / playerNumbers) * avgXpAmount)
    end
    
    return avgXp

end

function GetXpValue(entity)

	if entity:isa("Player") then
		return XpList[entity.combatTable.lvl] and XpList[entity.combatTable.lvl]["GivenXP"] or 0
	else
		return XpValues[entity:GetClassName()] or 0
	end
	
end

function GetXpLevelDiff(killedPlayer, nearbyPlayer)
	if killedPlayer:isa("Player") and nearbyPlayer:isa("Player") and
		killedPlayer.combatTable and nearbyPlayer.combatTable then
		local levelDiff = killedPlayer.combatTable.lvl - nearbyPlayer.combatTable.lvl
		return math.max(0, levelDiff * extraXpPerLevelDiff)
	end
	return 0
end

-- Used to check whether an entity should deliver Xp on death or on damage
function GetTrickleXp(entity)
	if entity:isa("Hive") or entity:isa("CommandStation") or entity:isa("Armory") then
		return true
	else
		return false
	end
end

function GetAllUpgrades(team)
	
	local upgradeList = {}
	local className = ""
	
	-- hack to support marine vs marine
	if team == kTeam1Index or team == kTeam2Index then
		local teamType = GetGamerules():GetTeam(team):GetTeamType()
		if teamType == kMarineTeamType then
		    team = "Marine" 
		else
		    team = "Alien" 
		end
	end
	
	if team == "Marine" then
		className = "CombatMarineUpgrade"
	else
		className = "CombatAlienUpgrade"
	end
	
	-- Extract all the upgrades for this kind of team (Alien vs. Marine).
	for _, upgrade in ipairs(UpsList) do
		if upgrade:isa(className) then
			table.insert(upgradeList, upgrade)
		end
	end
	
	return upgradeList
	
end

function GetUpgradeFromId(upgradeId)

	-- Find the upgrade that matches this Id.
	for _, upgrade in ipairs(UpsList) do
		if upgrade:GetId() == upgradeId then
			return upgrade
		end
	end
	return nil

end

function GetUpgradeFromTechId(upgradeTechId)

	-- Find the upgrade that matches this Id.
	for _, upgrade in ipairs(UpsList) do
		if upgradeTechId == upgrade:GetTechId() then
			return upgrade
		end
	end
	return nil

end

function GetUpgradesOfType(upgradeList, upgradeType)

	local typeList = {}

	-- Extract all the upgrades of this type.
	for _, upgrade in ipairs(upgradeList) do
		if upgrade:GetType() == upgradeType then
			table.insert(typeList, upgrade)
		end
	end
	
	return typeList

end

function GetUpgradeFromTextCode(textCode)

	for _, upgrade in ipairs(UpsList) do
		if (textCode == upgrade:GetTextCode()) then
			return upgrade
		end
	end
	
	return nil

end

function GetUpgradeFromTechId(techId)

	for _, upgrade in ipairs(UpsList) do
		if (techId == upgrade:GetTechId()) then
			return upgrade
		end
	end
	
	return nil

end