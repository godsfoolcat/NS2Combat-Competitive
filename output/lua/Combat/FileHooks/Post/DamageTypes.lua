
function NS2Gamerules_GetUpgradedDamage(attacker, doer, damage, damageType)
	
	local damageScalar = 1
	
	if attacker then
		
		-- Damage upgrades only affect weapons, not ARCs, Sentries, MACs, Mines, etc.
		if doer:isa("Weapon") or doer:isa("Grenade") or doer:isa("Minigun") or doer:isa("Railgun") then
			
			if(GetHasTech(attacker, kTechId.Weapons3, true)) then
				
				damageScalar = kWeapons3DamageScalar
			
			elseif(GetHasTech(attacker, kTechId.Weapons2, true)) then
				
				damageScalar = kWeapons2DamageScalar
			
			elseif(GetHasTech(attacker, kTechId.Weapons1, true)) then
				
				damageScalar = kWeapons1DamageScalar
			
			end
		
		end
	
	end
	
	return damage * damageScalar

end

function Dump(variable, name, maxdepth, depth)
	if name == nil then
		name = '(this)'
	end
	
	if maxdepth == nil then
		maxdepth = 5
	end
	
	if depth == nil then
		depth = 0
	end
	
	if type(variable) == 'nil' then
		Print(name .. ' = (nil)')
	elseif type(variable) == 'number' then
		Print(name .. ' = ' .. variable)
	elseif type(variable) == 'boolean' then
		if variable then
			Print(name .. ' = true')
		else
			Print(name .. ' = false')
		end
	elseif type(variable) == 'string' then
		Print(name .. ' = "' .. variable .. '"')
	elseif type(variable) == 'table' then
		Print(name .. ' = (' .. type(variable) .. ')')
		
		for i, v in pairs(variable) do
			if type(i) ~= 'userdata' then
				if v == _G then -- because _G._G == _G
					Print(name .. '.' .. i)
				elseif v ~= variable then
					if depth >= maxdepth then
						Print(name .. '.' .. i .. ' (...)')
					else
						Dump(v, name .. '.' .. i, maxdepth, depth + 1)
					end
				else
					Print(name .. '.' .. i .. ' = ' .. name)
				end
			end
		end
	else -- function, userdata, thread, cdata
		Print(name .. ' = (' .. type(variable) .. ')')
		
		if getmetatable(variable) and getmetatable(variable).__towatch then
			Dump(getmetatable(variable).__towatch, name .. ' (' .. type(variable) .. ')', maxdepth, depth + 1)
		end
	end
end

local upgradedDamageScalars
function NS2Gamerules_GetUpgradedDamageScalar( attacker, weaponTechId )
	
	-- kTechId gets loaded after this, and i don't want to load it. :T
	if not upgradedDamageScalars then
		
		upgradedDamageScalars =
		{
			[kTechId.Shotgun]         = { kShotgunWeapons1DamageScalar,         kShotgunWeapons2DamageScalar,         kShotgunWeapons3DamageScalar },
			[kTechId.GrenadeLauncher] = { kGrenadeLauncherWeapons1DamageScalar, kGrenadeLauncherWeapons2DamageScalar, kGrenadeLauncherWeapons3DamageScalar },
			[kTechId.Flamethrower]    = { kFlamethrowerWeapons1DamageScalar,    kFlamethrowerWeapons2DamageScalar,    kFlamethrowerWeapons3DamageScalar },
			["Default"]               = { kWeapons1DamageScalar,                kWeapons2DamageScalar,                kWeapons3DamageScalar },
		}
	
	end
	
	local scalar = 1.0
	local upgradeScalars = upgradedDamageScalars["Default"]
	if upgradedDamageScalars[weaponTechId] then
		upgradeScalars = upgradedDamageScalars[weaponTechId]
	end
	
	if GetHasTech(attacker, kTechId.Weapons3, true) then
		scalar = upgradeScalars[3]
	elseif GetHasTech(attacker, kTechId.Weapons2, true) then
		scalar = upgradeScalars[2]
	elseif GetHasTech(attacker, kTechId.Weapons1, true) then
		scalar = upgradeScalars[1]
	end
	
	if not scalar then
		return 1.0
	else
		return scalar
	end


end
