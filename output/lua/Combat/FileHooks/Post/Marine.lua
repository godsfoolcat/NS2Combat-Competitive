-- Weapons can't be dropped anymore
function Marine:Drop()

	-- just do nothing

end


local networkVars =
{
    timeCatpackboost = "private time", -- remove compensated so we can do it outside of moves
    lastScan = "private time",
    lastResupply = "private time",
    lastCatPack = "private time",
    hasFastSprint = "boolean",
    hasFastReload = "boolean",
}

local oldMarineOnCreate = Marine.OnCreate
function Marine:OnCreate()
    oldMarineOnCreate(self)
    self.hasFastSprint = false
    self.hasFastReload = false
end

function Marine:GetMaxSpeed(possible)
    if possible then
        return Marine.kRunMaxSpeed
    end

    local sprintingScalar = self:GetSprintingScalar()
    local fastSprintBonus = self:GotFastSprint() and kSprintSpeedUpgradeScalar or 0
    local maxSprintSpeed = Marine.kWalkMaxSpeed + ( Marine.kRunMaxSpeed - Marine.kWalkMaxSpeed + fastSprintBonus) * sprintingScalar
    local maxSpeed = ConditionalValue( self:GetIsSprinting(), maxSprintSpeed, Marine.kWalkMaxSpeed )
        
    -- Take into account our weapon inventory and current weapon. Assumes a vanilla marine has a scalar of around .8.
    local inventorySpeedScalar = self:GetInventorySpeedScalar() + .17
    local useModifier = 1

    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon and self.isUsing and activeWeapon:GetMapName() == Builder.kMapName then
        useModifier = 0.5
    end

    if self:GetHasCatPackBoost() then
        maxSpeed = maxSpeed + kCatPackMoveAddSpeed
    end
    
    return maxSpeed * self:GetSlowSpeedModifier() * inventorySpeedScalar * useModifier
end

local oldMarineOnSprintStart = Marine.OnSprintStart
function Marine:OnSprintStart()
    if oldMarineOnSprintStart then
        oldMarineOnSprintStart(self)
    end
    
    if Server then
		self:CheckCombatData()
        self.hasFastSprint = self.combatTable.hasFastSprint
    elseif Client then
        local upgrades = self:GetPlayerUpgrades()
        for _, upgradeTechId in ipairs(upgrades) do
            if upgradeTechId == kTechId.PhaseTech then
                self.hasFastSprint = true
                break
            end
        end
    end
    
end

Shared.LinkClassToMap("Marine", Marine.kMapName, networkVars, true)
