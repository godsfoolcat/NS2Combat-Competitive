class 'CombatMarineUpgrade' (CombatUpgrade)

function CombatMarineUpgrade:Initialize(...)

	CombatUpgrade.Initialize(self, "Marine", ...)

end

function CombatMarineUpgrade:TeamSpecificLogic(player)
	
	local techId = self:GetTechId()
	local kMapName = LookupTechData(techId, kTechDataMapName)
	
	-- Apply weapons upgrades to a marine.
	if (player:GetIsAlive() and self:GetType() == kCombatUpgradeTypes.Weapon) then
		--Player.InitWeapons(player)
		if player:isa("Exo") then
            
            local newWeapon = CreateEntity(kMapName, player:GetEyePos(), player:GetTeamNumber(), nil, false)
            
            -- if this is a primary weapon, destroy the old primary
            if player.storedWeaponsIds then
            
                -- MUST iterate backwards, as "DestroyEntity()" causes the ids to be removed as they're hit.
                for i=#player.storedWeaponsIds, 1, -1 do
                    local weaponId = player.storedWeaponsIds[i]
                    local oldWeapon = Shared.GetEntity(weaponId)
                    if oldWeapon and oldWeapon.GetHUDSlot and oldWeapon:GetHUDSlot() == newWeapon:GetHUDSlot() then
                        DestroyEntity(oldWeapon)
                    end
                end
                
            end
		
            
            player:StoreWeapon(newWeapon)
            
        else
            -- if this is a primary weapon, destroy the old one.
			
			if kRevolverCost and kMapName == Revolver.kMapName then
				local weapon = player:GetWeaponInHUDSlot(2)
				if (weapon) then
					player:RemoveWeapon(weapon)
					DestroyEntity(weapon)
				end
			elseif GetIsPrimaryWeapon(kMapName) then
                local weapon = player:GetWeaponInHUDSlot(1)
                if (weapon) then
                    player:RemoveWeapon(weapon)
                    DestroyEntity(weapon)
                end
            end
			
            self:GiveItem(player)
        end
	end
	
	return true
end