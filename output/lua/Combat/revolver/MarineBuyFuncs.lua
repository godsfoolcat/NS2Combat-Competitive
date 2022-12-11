
local oldCombatMarineBuy_GUISortUps = CombatMarineBuy_GUISortUps
function CombatMarineBuy_GUISortUps(upgradeList)
	
	local revolverUpgrade
	for _, upgrade in ipairs(upgradeList) do
		if upgrade:GetTechId() == kTechId.Revolver then
			revolverUpgrade = upgrade
			break
		end
	end
	
	local oldList = oldCombatMarineBuy_GUISortUps(upgradeList)
	
	if revolverUpgrade then
		for index, entry in ipairs(oldList) do
			if entry.GetTechId and entry:GetTechId() == kTechId.Shotgun  then
				table.insert(oldList, index, revolverUpgrade)
				break
			end
		end
	end
	
	return oldList

end

local oldDescFunc = CombatMarineBuy_GetWeaponDescription
function CombatMarineBuy_GetWeaponDescription(techId)
	if techId == kTechId.Revolver then
		return "You get a Revolver."
	end
	return oldDescFunc(techId)
end