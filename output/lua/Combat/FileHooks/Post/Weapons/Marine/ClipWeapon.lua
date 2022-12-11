-- for fast reloading
function ClipWeapon:GetCatalystSpeedBase()
    if self:GetIsReloading() then
        local player = self:GetParent()
        if player then
            return player:GotFastReload() and 1.75 or 1
        end
    end
    return 1
end

local function CheckFastReload(self, player)
    if Server then
		player:CheckCombatData()
        player.hasFastReload = player.combatTable.hasFastReload
    elseif Client then
        local upgrades = player:GetPlayerUpgrades()
        for _, upgradeTechId in ipairs(upgrades) do
            if upgradeTechId == kTechId.AdvancedWeaponry then
                player.hasFastReload = true
                break
            end
        end        
    end
end
 
local oldClipWeaponOnReload = ClipWeapon.OnReload
function ClipWeapon:OnReload(player)
    CheckFastReload(self, player)
    oldClipWeaponOnReload(self, player)    
end
