
-- Gestate Times
kGestateTime = {}
kGestateTime[kTechId.Skulk] = 1
kGestateTime[kTechId.Gorge] = 3
if kProwlerCost then
	kGestateTime[kTechId.Prowler] = 3
end
if kChangelingCost then
	kGestateTime[kTechId.Changeling] = 3
end
kGestateTime[kTechId.Lerk] = 4
kGestateTime[kTechId.Fade] = 5
kGestateTime[kTechId.Onos] = 8
kSkulkGestateTime = kGestateTime[kTechId.Skulk]

-- Power points
kPowerPointHealth = 1200
kPowerPointArmor = 500
kPowerPointPointValue = 0
kCombatPowerPointAutoRepairTime = 300

-- Grenade Launcher nerf
kGrenadeLauncherGrenadeDamage = 70 -- vanilla is 90, but we allow for damage upgrades

-- kill hydras if the player is not a gorge after 30 seconds
kKillHydrasWhenNotGorge = true

-- Ammo for mines
kNumMines = 1
kMaxNumMines = 3

-- number of handgrenaeds
kMaxHandGrenades = 1

-- Health values
-- Make the marine structures slightly less squishy...
kArmoryHealth = 3500
kCommandStationHealth = 6000

-- nerf range of xeno
kXenocideRange = 9

-- EMP energy drain
kEMPBlastEnergyDamage = 75

-- Timers for Scan, Resupply and Catalyst packs.
kScanTimer = 14
kResupplyTimer = 5
kImprovedResupplyExtra = 5
AmmoPack.kNumClips = 1
kCatalystTimer = 14

-- Scan Duration, maybe we need to tune it a bit
kScanDuration = 7

-- Make these less "spammy"
kEMPTimer = 30
kInkTimer = 30
-- reduce ink amount a bit
ShadeInk.kShadeInkDisorientRadius = 9
kCombatTauntCheckInterval = 4

kSprintSpeedUpgradeScalar = 3.25

kARCSpawnFrequency = 60

kShadeInkDuration = 2.5