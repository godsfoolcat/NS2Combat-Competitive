-- Helper functions for the marine buy menu

-- headlines for the Buymenu
function CombatMarineBuy_GetHeadlines()

    local headlines = {
        "Support",
        "Weapons",        
        "Weapon Ups",
        "Armor Ups",
        "Class Ups",
        "Grenades",
    }
    
    return headlines
    
end

-- costum sort function that the ups to look good
function CombatMarineBuy_GUISortUps(upgradeList)

-- max 4 rows per column
    local layoutList = {
        -- 0, Support
        "nextRow",
        kTechId.MedPack,
        kTechId.AmmoPack,
        kTechId.CatPack,
        kTechId.Scan,
        kTechId.LayMines,
        kTechId.Welder,
        "nextRow",

        -- 1, Weapons
        kTechId.Shotgun,
        kTechId.GrenadeLauncher,
        kTechId.Flamethrower,
        kTechId.HeavyMachineGun,
        "nextRow",
        
        -- 2, Weapon Upgrades
        kTechId.Weapons1,
        kTechId.Weapons2,
        kTechId.Weapons3,
        kTechId.AdvancedWeaponry,
        "nextRow",

        -- 3, Armor Upgrades
        kTechId.Armor1,
        kTechId.Armor2,
        kTechId.Armor3,
        "nextRow",

        -- 4, Class Upgrades
        kTechId.Jetpack,
        kTechId.DualMinigunExosuit,
        kTechId.DualRailgunExosuit,
        kTechId.PhaseTech,
        "nextRow",

        -- 5, grenades
        kTechId.ClusterGrenade,
        kTechId.GasGrenade,
        kTechId.PulseGrenade,

    }
    
    local sortedList = {}    
    -- search the techID in the Uplist and copy it to its correct place
    for _, entry in ipairs(layoutList) do
        if (entry  == "nextRow") then
            table.insert(sortedList, "nextRow")
        else
            for _, upgrade in ipairs(upgradeList) do
                if upgrade:GetTechId() == entry then
                    table.insert(sortedList, upgrade)
                    break
                end
            end
        end
    end
    
    return sortedList
end

-- Todo: Move these into the locale file
local combatWeaponDescription
function CombatMarineBuy_GetWeaponDescription(techId)

    if not combatWeaponDescription then
    
        combatWeaponDescription = {}

        combatWeaponDescription[kTechId.MedPack] ={ "COMBAT_RESUPPLY_DESCRIPTION", kResupplyTimer }
        combatWeaponDescription[kTechId.AmmoPack] =  {"COMBAT_IMPROVED_RESUPPLY_DESCRIPTION", kImprovedResupplyExtra}
        combatWeaponDescription[kTechId.Scan] = { "COMBAT_SCAN_DESCRIPTION", kScanTimer }
        combatWeaponDescription[kTechId.Welder] = { "COMBAT_WELDER_DESCRIPTION" }
        combatWeaponDescription[kTechId.LayMines] = {"COMBAT_MINES_DESCRIPTION"}
        combatWeaponDescription[kTechId.CatPack] =  {"COMBAT_CATALYST_DESCRIPTION", kCatalystTimer}

        combatWeaponDescription[kTechId.Axe] = {"COMBAT_AXE_DESCRIPTION"}
        combatWeaponDescription[kTechId.Pistol] = {"COMBAT_PISTOL_DESCRIPTION"}
        combatWeaponDescription[kTechId.Rifle] = {"COMBAT_RIFLE_DESCRIPTION"}
        combatWeaponDescription[kTechId.Shotgun] = {"COMBAT_SHOTGUN_DESCRIPTION"}
        combatWeaponDescription[kTechId.Flamethrower] = {"COMBAT_FLAMETHROWER_DESCRIPTION"}
        combatWeaponDescription[kTechId.GrenadeLauncher] = {"COMBAT_GRENADELAUNCHER_DESCRIPTION" }
        combatWeaponDescription[kTechId.HeavyMachineGun] = {"COMBAT_MACHINE_GUN_DESCRIPTION"}


        combatWeaponDescription[kTechId.Weapons1] = {"COMBAT_WEAPON1_DESCRIPTION"}
        combatWeaponDescription[kTechId.Weapons2] = {"COMBAT_WEAPON2_DESCRIPTION"}
        combatWeaponDescription[kTechId.Weapons3] = {"COMBAT_WEAPON3_DESCRIPTION"}
        combatWeaponDescription[kTechId.AdvancedWeaponry] = {"COMBAT_RELOAD_DESCRIPTION"}

        combatWeaponDescription[kTechId.Armor1] = {"COMBAT_ARMOR1_DESCRIPTION"}
        combatWeaponDescription[kTechId.Armor2] = {"COMBAT_ARMOR2_DESCRIPTION"}
        combatWeaponDescription[kTechId.Armor3] = {"COMBAT_ARMOR3_DESCRIPTION"}
        combatWeaponDescription[kTechId.PhaseTech] = {"COMBAT_SPRINT_DESCRIPTION"}

        combatWeaponDescription[kTechId.Jetpack] = {"COMBAT_JETPACK_DESCRIPTION"}
        combatWeaponDescription[kTechId.Exosuit] = {"COMBAT_EXOSUIT_DESCRIPTION"}
        combatWeaponDescription[kTechId.DualMinigunExosuit] = {"COMBAT_EXOSUIT_DUALMINIGUN_DESCRIPTION"}
        combatWeaponDescription[kTechId.ClawRailgunExosuit] = {"COMBAT_EXOSUIT_RAILGUN_DESCRIPTION"}
        combatWeaponDescription[kTechId.DualRailgunExosuit] = {"COMBAT_EXOSUIT_DUALRAILGUN_DESCRIPTION"}

        combatWeaponDescription[kTechId.ClusterGrenade] = {"COMBAT_CLUSTERGRENADE_DESCRIPTION"}
        combatWeaponDescription[kTechId.GasGrenade] = {"COMBAT_GASGRENADE_DESCRIPTION"}
        combatWeaponDescription[kTechId.PulseGrenade] = {"COMBAT_PULSEGRENADE_DESCRIPTION"}
    
    end
    
    local description = combatWeaponDescription[techId]
    local desc = Combat_ResolveString(description[1])
    if description[2] then
        desc = string.format(desc, description[2])
    end
    
    return desc

end