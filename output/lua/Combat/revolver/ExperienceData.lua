local upgrade = CombatMarineUpgrade()

upgrade:Initialize(kCombatUpgrades.Revolver, "revolver", "Revolver", kTechId.Revolver, nil, nil, 1, kCombatUpgradeTypes.Weapon, false, 0, { kCombatUpgrades.Exosuit, kCombatUpgrades.RailGunExosuit, kCombatUpgrades.DualMinigunExosuit })

table.insert(UpsList, upgrade)