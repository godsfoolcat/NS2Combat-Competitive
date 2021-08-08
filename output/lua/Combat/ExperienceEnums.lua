-- List of all upgrades available.
if kProwlerCost and kChangelingCost then
	kCombatUpgrades = enum({-- Marine upgrades
		'Mines', 'Welder', 'Shotgun', 'Flamethrower', 'GrenadeLauncher', 'HeavyMachineGun',
		'Weapons1', 'Weapons2', 'Weapons3', 'Armor1', 'Armor2', 'Armor3',
		'MotionDetector', 'Scanner', 'Catalyst', 'Resupply', 'ImprovedResupply', 'EMP', 'FastSprint',
		'Jetpack', 'Exosuit', 'DualMinigunExosuit', 'FastReload',
		'RailGunExosuit', 'ClusterGrenade', 'GasGrenade', 'PulseGrenade',
		
		-- Alien upgrades
		'Gorge', 'Prowler', 'Changeling', 'Lerk', 'Fade', 'Onos',
		'TierTwo', 'TierThree',
		'Carapace', 'Regeneration', 'Vampirism', 'Camouflage', 'Celerity',
		'Adrenaline', 'Feint', 'ShadeInk', 'Focus', 'Aura', 'Crush' })
elseif kProwlerCost then
	kCombatUpgrades = enum({-- Marine upgrades
		'Mines', 'Welder', 'Shotgun', 'Flamethrower', 'GrenadeLauncher', 'HeavyMachineGun',
		'Weapons1', 'Weapons2', 'Weapons3', 'Armor1', 'Armor2', 'Armor3',
		'MotionDetector', 'Scanner', 'Catalyst', 'Resupply', 'ImprovedResupply', 'EMP', 'FastSprint',
		'Jetpack', 'Exosuit', 'DualMinigunExosuit', 'FastReload',
		'RailGunExosuit', 'ClusterGrenade', 'GasGrenade', 'PulseGrenade',
		
		-- Alien upgrades
		'Gorge', 'Prowler', 'Lerk', 'Fade', 'Onos',
		'TierTwo', 'TierThree',
		'Carapace', 'Regeneration', 'Vampirism', 'Camouflage', 'Celerity',
		'Adrenaline', 'Feint', 'ShadeInk', 'Focus', 'Aura', 'Crush' })
elseif kChangelingCost then
	kCombatUpgrades = enum({-- Marine upgrades
		'Mines', 'Welder', 'Shotgun', 'Flamethrower', 'GrenadeLauncher', 'HeavyMachineGun',
		'Weapons1', 'Weapons2', 'Weapons3', 'Armor1', 'Armor2', 'Armor3',
		'MotionDetector', 'Scanner', 'Catalyst', 'Resupply', 'ImprovedResupply', 'EMP', 'FastSprint',
		'Jetpack', 'Exosuit', 'DualMinigunExosuit', 'FastReload',
		'RailGunExosuit', 'ClusterGrenade', 'GasGrenade', 'PulseGrenade',
		
		-- Alien upgrades
		'Gorge', 'Changeling', 'Lerk', 'Fade', 'Onos',
		'TierTwo', 'TierThree',
		'Carapace', 'Regeneration', 'Vampirism', 'Camouflage', 'Celerity',
		'Adrenaline', 'Feint', 'ShadeInk', 'Focus', 'Aura', 'Crush' })
else
	kCombatUpgrades = enum({-- Marine upgrades
		'Mines', 'Welder', 'Shotgun', 'Flamethrower', 'GrenadeLauncher', 'HeavyMachineGun',
		'Weapons1', 'Weapons2', 'Weapons3', 'Armor1', 'Armor2', 'Armor3',
		'MotionDetector', 'Scanner', 'Catalyst', 'Resupply', 'ImprovedResupply', 'EMP', 'FastSprint',
		'Jetpack', 'Exosuit', 'DualMinigunExosuit', 'FastReload',
		'RailGunExosuit', 'ClusterGrenade', 'GasGrenade', 'PulseGrenade',
		
		-- Alien upgrades
		'Gorge', 'Lerk', 'Fade', 'Onos',
		'TierTwo', 'TierThree',
		'Carapace', 'Regeneration', 'Vampirism', 'Camouflage', 'Celerity',
		'Adrenaline', 'Feint', 'ShadeInk', 'Focus', 'Aura', 'Crush' })
end
-- The order of these is important...
kCombatUpgradeTypes = enum({ 'Class', 'Tech', 'Weapon' })