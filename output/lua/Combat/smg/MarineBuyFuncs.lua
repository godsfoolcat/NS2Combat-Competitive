
local oldCombatMarineBuy_GUISortUps = CombatMarineBuy_GUISortUps
function CombatMarineBuy_GUISortUps(upgradeList)
	
	local smgUpgrade
	for _, upgrade in ipairs(upgradeList) do
		if upgrade:GetTechId() == kTechId.Submachinegun then
			smgUpgrade = upgrade
			break
		end
	end
	
	local oldList = oldCombatMarineBuy_GUISortUps(upgradeList)
	
	if smgUpgrade then
		for index, entry in ipairs(oldList) do
			if entry.GetTechId and entry:GetTechId() == kTechId.Shotgun  then
				table.insert(oldList, index+1, smgUpgrade)
				break
			end
		end
	end
	
	return oldList

end

local oldDescFunc = CombatMarineBuy_GetWeaponDescription
function CombatMarineBuy_GetWeaponDescription(techId)
	if techId == kTechId.Submachinegun then
		return "You get a Submachinegun, but you need a Shotgun first."
	end
	return oldDescFunc(techId)
end