
function SprintMixin:UpdateSprintingState(input)

    PROFILE("SprintMixin:UpdateSprintingState")
    
    local velocity = self:GetVelocity()
    local speed = velocity:GetLength()
    
    local weapon = self:GetActiveWeapon()
    local deployed = not weapon or not weapon.GetIsDeployed or weapon:GetIsDeployed()
    local sprintingAllowedByWeapon = not deployed or not weapon or (weapon.GetSprintAllowed and weapon:GetSprintAllowed())

    local attacking = false
    if weapon and weapon.GetTryingToFire then
        attacking = weapon:GetTryingToFire(input)    
    end
    
    local buttonDown = (bit.band(input.commands, Move.MovementModifier) ~= 0)
    if not weapon or (not weapon.GetIsReloading or not weapon:GetIsReloading()) then
        self:UpdateSprintMode(buttonDown)
    end
    
    -- Allow small little falls to not break our sprint (stairs)
    self.desiredSprinting = (buttonDown or self.sprintMode) and sprintingAllowedByWeapon and speed > 1 and not self.crouching and self:GetIsOnGround() and not attacking and not self.requireNewSprintPress
    
    if input.move.z < kEpsilon then
        self.desiredSprinting = false
    else
    
        -- Only allow sprinting if we're pressing forward and moving in that direction
        local normMoveDirection = GetNormalizedVectorXZ(self:GetViewCoords():TransformVector(input.move))
        local normVelocity = GetNormalizedVectorXZ(velocity)
        local viewFacing = GetNormalizedVectorXZ(self:GetViewCoords().zAxis)
        
        if normVelocity:DotProduct(normMoveDirection) < 0.3 or normMoveDirection:DotProduct(viewFacing) < 0.2 then
            self.desiredSprinting = false
        end
        
    end
    
    if self.desiredSprinting ~= self.sprinting then
    
        -- Only allow sprinting to start if we have some minimum energy (so we don't start and stop constantly)
        --if not self.desiredSprinting or (self:GetSprintTime() >= SprintMixin.kMinSprintTime) then
    
            self.sprintTimeOnChange = self:GetSprintTime()
            local sprintDuration = math.max(0, Shared.GetTime() - self.timeSprintChange)
            self.timeSprintChange = Shared.GetTime()
            self.sprinting = self.desiredSprinting
            
            if self.sprinting then
            
                if self.OnSprintStart then
                    self:OnSprintStart()
                end
            
            else
            
                if self.OnSprintEnd then
                    self:OnSprintEnd(sprintDuration)
                end
                
            end
            
        --end
        
    end
    
    -- Some things break us out of sprint mode
    if self.sprintMode and (attacking or speed <= 1 or not self:GetIsOnGround() or self.crouching) then
        self.sprintMode = false
        self.requireNewSprintPress = attacking
    end
    
    if self.desiredSprinting then
        local sprintTime = self:GotFastSprint() and kFastSprintTime or SprintMixin.kSprintTime
        self.sprintingScalar = Clamp((Shared.GetTime() - self.timeSprintChange) / sprintTime, 0, 1) -- * self:GetSprintTime() / SprintMixin.kMaxSprintTime
    else
        self.sprintingScalar = 1 - Clamp((Shared.GetTime() - self.timeSprintChange) / SprintMixin.kUnsprintTime, 0, 1)
    end
            
end
