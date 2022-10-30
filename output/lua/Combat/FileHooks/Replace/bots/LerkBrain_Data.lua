
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

local kLerkBrainActionTypesOrderScale = 10
local kLerkBrainObjectiveTypesOrderScale = 100

local kLerkRetreatStartEnergy = 0.35
local kLerkRetreatStopEnergy = 0.65

local kLerkRetreatStartHealth = 0.45
local kLerkRetreatStopHealth = 0.9

local kLerkBrainMinSporeRateTime = 8
local kLerkBrainNearbyEnemyThreshold = 16
local kLerkBrainMaxSporeDist = 20 -- limit to within relevancy range

local kLerkBrainPheromoneWeights =
{
    [kTechId.ThreatMarker] = 5.0,
    [kTechId.ExpandingMarker] = 2.0,
}

local kLerkBrainActionTypes = enum({
    "UmbraInCombatAllies",
    "SporeHostiles",
    "Attack",
})

local function GetLerkActionBaselineWeight( actionId )
    assert(kLerkBrainActionTypes[kLerkBrainActionTypes[actionId]], "Error: Invalid LerkBrain action-id passed")

    local totalActions = #kLerkBrainActionTypes
    local actionOrderId = kLerkBrainActionTypes[kLerkBrainActionTypes[actionId]] --numeric index, not string

    --invert numeric index value and scale, the results in lower value, the higher the index. Which means
    --the Enum of actions is shown and used in a natural order (i.e. order of enum value declaration IS the priority)
    local actionWeightOrder = totalActions - (actionOrderId - 1)

    --final action base-line weight value
    return actionWeightOrder * kLerkBrainActionTypesOrderScale
end

------------------------------------------
--  Handles things like using tunnels, walljumping, leaping etc
------------------------------------------
local function PerformMove( alienPos, targetPos, bot, brain, move )

    local postIgnore, targetDist, targetMove, entranceTunel = HandleAlienTunnelMove( alienPos, targetPos, bot, brain, move )
    if postIgnore then return end -- We are waiting for a tunnel pass-through, which requires staying still

    local time = Shared.GetTime()
    local player = bot:GetPlayer()
    local targetMoveDist = (targetMove - alienPos):GetLengthSquared()
    local isEnteringTunnel = entranceTunel ~= nil and targetMoveDist < 25

    if not brain.isPancaking and brain.kLerkPancakeTime + brain.lastPancakeTime < time then

        local inRetreat = (brain.goalAction and brain.goalAction.name == "Retreat") and player:GetIsInCombat()
        local flapDelay = inRetreat and 0.25 or 0.45
        local disiredDiff = (targetMove - alienPos)

        local flapSpeedPercent = 0.8
        if not isEnteringTunnel and targetMoveDist > 16 and not player.flapPressed  then
            if player:GetVelocity():GetLength() / player:GetMaxSpeed() < flapSpeedPercent or player:GetIsOnGround() and Math.DotProduct(player:GetVelocity():GetUnit(), disiredDiff:GetUnit()) > 0.2 then
                if brain.timeOfJump + flapDelay < Shared.GetTime() then
                    --Log("jumping to accelerate")
                    move.commands = AddMoveCommand( move.commands, Move.Jump )
                    brain.timeOfJump = Shared.GetTime()
                end
            end
        end

        if not isEnteringTunnel then

            if not bot:GetPlayer():GetIsOnGround() and player:GetVelocity():GetLength() / player:GetMaxSpeed() > flapSpeedPercent then
                move.commands = AddMoveCommand( move.commands, Move.Jump ) -- gotta glide
                --Log("gliding fast")
            end

            if bot:GetPlayer():GetIsOnGround() and not player.flapPressed then
                move.commands = AddMoveCommand( move.commands, Move.Jump ) -- gotta get off the ground!
            end

        end

    else
    --pancake is defined set in LerkBrain.lua, only meant to help unstuck when Lerk goes up/down rapidly
    --tends to jam itself into ceilings when that occurs.
        bot:GetMotion():SetDesiredMoveDirection( Vector(0,-1,0) )
        local nearPath = Pathing.GetClosestPoint( alienPos )
        bot:GetMotion():SetDesiredMoveTarget( nearPath )
        move.commands = RemoveMoveCommand( move.commands, Move.Jump )
        move.commands = AddMoveCommand( move.commands, Move.Crouch )
    end
     
end

-- Return an estimate of how well this bot is able to respond to a target based on its distance
-- from the target. Linearly decreates from 1.0 at 30 distance to 0.0 at 150 distance
local function EstimateLerkResponseUtility(lerk, target)
    PROFILE("LerkBrain - EstimateLerkResponseUtility")

    local mloc = lerk:GetLocationName()
    local tloc = target:GetLocationName()

    if mloc == tloc then
        return 1.0
    end

    local dist = GetTunnelDistanceForAlien(lerk, target)
    return Clamp(1.0 - ( ( dist - 30.0 ) / 75.0 ), 0.0, 1.0)
end

------------------------------------------
--  More urgent == should really attack it ASAP
------------------------------------------
local function GetAttackUrgency(bot, mem)       --TODO This should be moved to a CommonAlien file...it's basically the same for all lifeforms, why duplicate it?

    -- See if we know whether if it is alive or not
    local ent = Shared.GetEntity(mem.entId)
    if not HasMixin(ent, "Live") or not ent:GetIsAlive() or (ent.GetTeamNumber and ent:GetTeamNumber() == bot:GetTeamNumber()) then
        return 0.0
    end
    
    local botPos = bot:GetPlayer():GetOrigin()
    local targetPos = ent:GetOrigin()

    -- Don't calculate tunnel distance for every single target memory, gets very expensive very quickly
    --local distance = select(2, GetTunnelDistanceForAlien(bot:GetPlayer(), ent))
    local distance = botPos:GetDistance(targetPos)

    -- Don't attack power points, not worth it without special-case heuristics (e.g. baserush)
    --[[
    if mem.btype == kMinimapBlipType.PowerPoint then
        local powerPoint = ent
        if powerPoint ~= nil and powerPoint:GetIsSocketed() then
            return 0.65
        else
            return 0
        end    
    end
    --]]
        
    local immediateThreats = {
        [kMinimapBlipType.Marine] = true,
        [kMinimapBlipType.JetpackMarine] = true,
        [kMinimapBlipType.Exo] = true,
    }
    
    if distance < 10 and immediateThreats[mem.btype] then
        -- Attack the nearest immediate threat (urgency will be 1.1 - 2)
        return 1 + 1 / math.max(distance, 1)
    end
    
    -- No immediate threat - load balance!
    local numOthers = bot.brain.teamBrain:GetNumAssignedTo( mem,
            function(otherId)
                if otherId ~= bot:GetPlayer():GetId() then
                    return true
                end
                return false
            end)
                    
    local urgencies = {
        -- Active threats
        [kMinimapBlipType.Marine] =             numOthers >= 2 and 0.6 or 1,
        [kMinimapBlipType.JetpackMarine] =      numOthers >= 2 and 0.7 or 1.1,
        [kMinimapBlipType.Exo] =                numOthers >= 2 and 0.8 or 1.2,
        
        -- Structures
        [kMinimapBlipType.Sentry] =             numOthers >= 2 and 0.5 or 0.95,
        [kMinimapBlipType.ARC] =                numOthers >= 4 and 0.4 or 0.9,
        [kMinimapBlipType.CommandStation] =     numOthers >= 8 and 0.3 or 0.85,
        [kMinimapBlipType.PhaseGate] =          numOthers >= 4 and 0.2 or 0.8,
        [kMinimapBlipType.Observatory] =        numOthers >= 3 and 0.2 or 0.75,
        [kMinimapBlipType.Extractor] =          numOthers >= 3 and 0.2 or 0.7,
        [kMinimapBlipType.InfantryPortal] =     numOthers >= 3 and 0.2 or 0.6,
        [kMinimapBlipType.PrototypeLab] =       numOthers >= 3 and 0.2 or 0.55,
        [kMinimapBlipType.Armory] =             numOthers >= 3 and 0.2 or 0.5,
        [kMinimapBlipType.RoboticsFactory] =    numOthers >= 3 and 0.2 or 0.5,
        [kMinimapBlipType.ArmsLab] =            numOthers >= 3 and 0.2 or 0.5,
        [kMinimapBlipType.MAC] =                numOthers >= 2 and 0.2 or 0.4,
    }

    if urgencies[ mem.btype ] ~= nil then
        return urgencies[ mem.btype ]
    end

    return 0.0
    
end

local function PerformUmbraFriendlies( move, bot, brain, player, action )
    
    local target = action.target

    -- The bot action should have guaranteed proper distance etc by now
    local targetAimPoint = GetBestAimPoint(target)
    bot:GetMotion():SetDesiredViewTarget(targetAimPoint)

    if player:GetWeapon(LerkUmbra.kMapName) then
        player:SetActiveWeapon(LerkUmbra.kMapName)
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )

        brain.timeLastUmbra = Shared.GetTime()
    end

end

local function PerformSporeHostiles( move, bot, brain, player, action )

    local target = action.target

    -- The bot action should have guaranteed proper distance etc by now
    local targetAimPoint = GetBestAimPoint(target)
    bot:GetMotion():SetDesiredViewTarget(targetAimPoint)

    if player:GetWeapon(Spores.kMapName) then
        player:SetActiveWeapon(Spores.kMapName)

        local targetDir = (targetAimPoint - player:GetEyePos()):GetUnit()
        local lookConvergence = bot:GetMotion().currViewDir:DotProduct(targetDir)

        -- only trigger the spores when we're sure we're going to land them in the right spot
        if lookConvergence > 0.95 then
            move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
            brain.timeLastSpore = Shared.GetTime()
        end
    end

end

local function PerformAttackEntity( eyePos, bestTarget, lastSeenPos, bot, brain, move )

    assert( bestTarget )

    local sighted = not HasMixin(bestTarget, "LOS") or bestTarget:GetIsSighted()
    local aimPos = sighted and GetBestAimPoint( bestTarget ) or (lastSeenPos + Vector(0,0.5,0))
    local doFire = false

    local distance = GetDistanceToTouch(eyePos, bestTarget)
    if distance < 35 and bot:GetBotCanSeeTarget( bestTarget ) then
        doFire = true
    end

    local nearbyThreats = brain:GetSenses():Get("nearbyThreats")
    local anyShotguns = nearbyThreats.numShotguns >= 1
    local isAttackingMultiple = nearbyThreats.numEnemies > 2

    local lerk = bot:GetPlayer()

    local botAccGroup = kBotAccWeaponGroup.LerkBite
    local commandFlag = 0
    if doFire then

        if anyShotguns then
            local keepDistanceDirection = (eyePos - aimPos):GetUnit()
            if keepDistanceDirection.y > 0.1 then
                keepDistanceDirection.y = 0.1
            end

            local keepDistancePos = bestTarget:GetOrigin() + (keepDistanceDirection * 16)
            PerformMove(eyePos, keepDistancePos, bot, brain, move)
        else
            PerformMove(eyePos, aimPos, bot, brain, move)
        end

        lerk:SetActiveWeapon(LerkBite.kMapName)

        local isTargetPlayer = bestTarget:isa("Player")

        if distance < 1.5 then
            botAccGroup = kBotAccWeaponGroup.LerkBite
            commandFlag = Move.PrimaryAttack
        elseif isTargetPlayer then
            botAccGroup = kBotAccWeaponGroup.LerkSpikes
            commandFlag = Move.SecondaryAttack
        end

        doFire = bot.aim and bot.aim:UpdateAim(bestTarget, aimPos, botAccGroup)
        if doFire then

            -- Does nothing if commandflag is 0
            move.commands = AddMoveCommand( move.commands, commandFlag )

            -- Handle attacking structure
            if not isTargetPlayer and distance < 1.75 then
                bot:GetMotion():SetDesiredMoveTarget(nil)
            end
        end

    else -- Cannot see target yet, just keep traveling to it's position
        PerformMove(eyePos, bestTarget:GetOrigin(), bot, brain, move)
    end
    
end

local function PerformAttack( eyePos, mem, bot, brain, move )

    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then

        PerformAttackEntity( eyePos, target, mem.lastSeenPos, bot, brain, move )

    else
        assert(false)
    end
    
    brain.teamBrain:AssignBotToMemory(bot, mem)

end

------------------------------------------
-- Lerk Brain Objective Validators
------------------------------------------

local kValidateRetreat = function(bot, brain, lerk, action)
    if not IsValid(action.hive) or not action.hive:GetIsAlive() then
        return false
    end

    return true
end

------------------------------------------
-- Lerk Brain Objective Executors
------------------------------------------

local kExecRetreatObjective = function(move, bot, brain, lerk, action)

    local hive = action.hive
    local hiveDist = select(2, GetTunnelDistanceForAlien(lerk, hive))

    -- we are retreating, unassign ourselves from anything else, e.g. attack targets
    brain.teamBrain:UnassignBot(bot)

    if hiveDist >= Hive.kHealRadius * 0.5 then

        PerformMove(lerk:GetEyePos(), hive:GetEngagementPoint(), bot, brain, move)

    else

        if lerk:GetIsUnderFire() then
            -- If under attack, we want to move away to other side of Hive
            local damageOrigin = lerk:GetLastTakenDamageOrigin()
            local hiveOrigin = hive:GetEngagementPoint()
            local retreatDir = (hiveOrigin - damageOrigin):GetUnit()
            local _, max = hive:GetModelExtents()
            local retreatPos = hiveOrigin + (retreatDir * max.x)
            bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
            bot:GetMotion():SetDesiredMoveTarget( retreatPos )

        else
            -- We're safe, just sit still
            bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
            bot:GetMotion():SetDesiredMoveTarget( nil )
        end

    end

    local healthFraction = lerk:GetHealthScalar()
    local energyFraction = lerk:GetEnergy() / lerk:GetMaxEnergy()

    -- Finished when both our health and armor return to full
    if healthFraction > kLerkRetreatStopHealth and energyFraction > kLerkRetreatStopEnergy then
        return kPlayerObjectiveComplete
    end

end

------------------------------------------
-- Lerk Brain Objectives
------------------------------------------

local kLerkBrainObjectiveTypes = enum({
    "Retreat",
    "RespondToThreat",
    "Evolve",
    "Pheromone",
    "Explore"
})

LerkObjectiveWeights = MakeBotActionWeights(kLerkBrainObjectiveTypes, kLerkBrainObjectiveTypesOrderScale)

kLerkBrainObjectives =
{

    ------------------------------------------
    -- Retreat
    ------------------------------------------
    function(bot, brain, lerk)

        PROFILE("LerkBrain_Data:retreat")

        local name, weight = LerkObjectiveWeights:Get(kLerkBrainObjectiveTypes.Retreat)

        if lerk.isHallucination then
            return kNilAction
        end

        local sdb = brain:GetSenses()

        local hiveData = sdb:Get("nearestHive")
        local hive = hiveData.hive
        local hiveDist = hiveData.distance or 0
        local healthFraction = lerk:GetHealthScalar()
        local energyFraction = lerk:GetEnergy() / lerk:GetMaxEnergy()

        -- If we are pretty close to the hive, stay with it a bit longer to encourage full-healing, etc.
        -- so pretend our situation is more dire than it is
        if hiveDist < Hive.kHealRadius * 0.85 and healthFraction < 0.9 then
            healthFraction = healthFraction / 6.0
        end

        local shouldRetreat = hive and (healthFraction <= kLerkRetreatStartHealth or energyFraction <= kLerkRetreatStartEnergy)

        if not shouldRetreat then
            return kNilAction
        end

        return {
            name = name,
            weight = weight,
            fastUpdate = true,
            hive = hive,
            validate = kValidateRetreat,
            perform = kExecRetreatObjective
        }

    end,

    ------------------------------------------
    --  RespondToThreats
    ------------------------------------------
    CreateAlienRespondToThreatAction(LerkObjectiveWeights, kLerkBrainObjectiveTypes.RespondToThreat, PerformMove),

    ------------------------------------------
    -- Evolve
    ------------------------------------------
    CreateAlienEvolveAction(LerkObjectiveWeights, kLerkBrainObjectiveTypes.Evolve, kTechId.Lerk),

    ------------------------------------------
    -- Pheromone
    ------------------------------------------
    CreateAlienPheromoneAction(LerkObjectiveWeights, kLerkBrainObjectiveTypes.Pheromone, kLerkBrainPheromoneWeights, PerformMove),

    ------------------------------------------
    -- Explore
    ------------------------------------------
    CreateExploreAction( LerkObjectiveWeights:GetWeight(kLerkBrainObjectiveTypes.Explore), function(pos, targetPos, bot, brain, move)
        PerformMove(pos, targetPos, bot, brain, move)
    end ),

}

local kExecAttackAction = function(move, bot, brain, lerk, action)
    brain.teamBrain:UnassignBot(bot)
    PerformAttack( lerk:GetEyePos(), action.bestMem, bot, brain, move )
end

------------------------------------------
--  Each want function should return the fuzzy weight,
-- along with a closure to perform the action
-- The order they are listed matters - actions near the beginning of the list get priority.
------------------------------------------
kLerkBrainActions =
{
    
    ------------------------------------------
    -- Debug Idle
    ------------------------------------------
    --[[
    function(bot, brain)
        return { name = "debug idle", weight = 0.001,
                perform = function(move)
                    bot:GetMotion():SetDesiredMoveTarget(nil)
                    -- there is nothing obvious to do.. figure something out
                    -- like go to the marines, or defend
                end }
    end,
    --]]

    ------------------------------------------
    -- Umbra InCombat Allies
    ------------------------------------------
    function (bot, brain, lerk)
        PROFILE("LerkBrain_Data:umbra_in_combat")
        local name = kLerkBrainActionTypes[kLerkBrainActionTypes.UmbraInCombatAllies]

        local weight = 0
        local senses = brain:GetSenses()
        local nearestUmbraTarget

        if lerk:GetWeapon(LerkUmbra.kMapName) then

            local target = senses:Get("nearestUmbraTarget")

            local timeSinceLastUmbra = Shared.GetTime() - (brain.timeLastUmbra or Shared.GetTime())
            local timeSinceLastSpores = Shared.GetTime() - (brain.timeLastSpore or Shared.GetTime())
            local isSelf = target and target.entId == lerk:GetId()
            local umbraRate = isSelf and 8 or 4 -- don't waste a bunch of energy re-umbraing ourselves

            if lerk:GetEnergy() > kUmbraEnergyCost * 1.5 and target and timeSinceLastUmbra > umbraRate and timeSinceLastSpores > (kLerkBrainMinSporeRateTime * 0.5) then

                nearestUmbraTarget = Shared.GetEntity(target.entId)

                if GetBotCanSeeTarget(lerk, nearestUmbraTarget) or isSelf then -- don't try to umbra through walls
                    weight = GetLerkActionBaselineWeight(kLerkBrainActionTypes.UmbraInCombatAllies)
                end
            end

        end

        return
        {
            name = name,
            weight = weight,
            fastUpdate = true,
            target = nearestUmbraTarget,
            perform = PerformUmbraFriendlies
        }

    end,

    ------------------------------------------
    -- Spore hostiles
    ------------------------------------------
    function (bot, brain, lerk)
        PROFILE("LerkBrain_Data:SporeHostiles")
        local name = kLerkBrainActionTypes[kLerkBrainActionTypes.SporeHostiles]

        local weight = 0
        local senses = brain:GetSenses()
        local targetEntity
        local timeSinceLastSpores = Shared.GetTime() - (brain.timeLastSpore or Shared.GetTime())
        local timeSinceLastUmbra = Shared.GetTime() - (brain.timeLastUmbra or Shared.GetTime())

        -- leave a little bit of energy in the tank to retreat with
        if lerk:GetWeapon(Spores.kMapName) and lerk:GetEnergy() > kSporesDustEnergyCost * 1.5 and timeSinceLastSpores > kLerkBrainMinSporeRateTime and timeSinceLastUmbra > 2 then

            targetEntity = senses:Get("nearestSporesTarget")

            if targetEntity and GetBotCanSeeTarget(lerk, targetEntity) then

                local nearby = GetEntitiesWithinRange("SporeCloud", targetEntity:GetOrigin(), 11)

                if #nearby == 0 then
                    weight = GetLerkActionBaselineWeight(kLerkBrainActionTypes.SporeHostiles)
                end

            end

        end

        return
        {
            name = name,
            weight = weight,
            fastUpdate = true,
            target = targetEntity,
            perform = PerformSporeHostiles
        }

    end,


    ------------------------------------------
    -- Attack
    ------------------------------------------
    function(bot, brain, lerk)
        PROFILE("LerkBrain_Data:attack")
        local name = kLerkBrainActionTypes[kLerkBrainActionTypes.Attack]

        local memories = GetTeamMemories(lerk:GetTeamNumber())

        local bestMem = brain:GetSenses():Get("nearbyThreats").memory

        local weapon = lerk:GetActiveWeapon()
        local energy = lerk:GetEnergy() / lerk:GetMaxEnergy()
        local eHP = lerk:GetHealthScalar()
        local canAttack = weapon ~= nil
            and energy > kLerkRetreatStartEnergy
            and eHP > kLerkRetreatStartHealth

        local weight = 0.0

        if canAttack and bestMem ~= nil then

            local dist = select(2, GetTunnelDistanceForAlien(bot:GetPlayer(), Shared.GetEntity(bestMem.entId) or bestMem.lastSeenPos))
            if dist <= 50 then
                weight = GetLerkActionBaselineWeight(kLerkBrainActionTypes.Attack)
            end

        end

        return {
            name = name,
            weight = weight,
            fastUpdate = true,
            bestMem = bestMem,
            perform = kExecAttackAction
        }
    end,

    CreateAlienInterruptAction()

}

------------------------------------------
--
------------------------------------------
function CreateLerkBrainSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("nearbyThreats",
        function(db, lerk)
            local teamBrain = GetTeamBrain(lerk:GetTeamNumber())
            local enemyTeam = GetEnemyTeamNumber(lerk:GetTeamNumber())
            local lerkPos = lerk:GetOrigin()

            local numEnemies = 0
            local numShotguns = 0
            local bestUrgency = 0.0
            local bestMem = nil

            for _, mem in teamBrain:IterMemoriesNearLocation(lerk:GetLocationName(), enemyTeam) do

                local isActiveThreat = mem.btype == kMinimapBlipType.Marine
                    or mem.btype == kMinimapBlipType.JetpackMarine
                    or mem.btype == kMinimapBlipType.Exo
                    or mem.btype == kMinimapBlipType.Sentry

                if isActiveThreat then
                    local dist = lerkPos:GetDistance(mem.lastSeenPos)

                    if dist <= kLerkBrainNearbyEnemyThreshold then
                        numEnemies = numEnemies + 1

                        local ent = Shared.GetEntity(mem.entId)

                        if ent.GetWeapon and ent:GetWeapon(Shotgun.kMapName) ~= nil then
                            numShotguns = numShotguns + 1
                        end
                    end

                end

                local urgency = GetAttackUrgency(db.bot, mem)
                if urgency and urgency > bestUrgency then
                    bestUrgency = urgency
                    bestMem = mem
                end

            end

            return { memory = bestMem, numEnemies = numEnemies, numShotguns = numShotguns }
        end)

    s:Add("nearestUmbraTarget", function(db, lerk)

        local playerTeam = lerk:GetTeamNumber()
        local playerPos = lerk:GetOrigin()
        local memories = GetTeamMemories(playerTeam)
        local umbraTargets =
            FilterTableEntries( memories,
                function( mem )
                    local ent = Shared.GetEntity( mem.entId )

                    if ent:isa("Player") then
                        --local isOther = player:GetId() ~= ent:GetId()
                        local isAlive = HasMixin(ent, "Live") and ent:GetIsAlive()
                        local isUmbraReceiver = HasMixin(ent, "Umbra") and GetAreFriends(ent, lerk)
                        local isInUmbraRange = playerPos:GetDistance(ent:GetOrigin()) < kUmbraMaxRange
                        local isInCombat = HasMixin(ent, "Combat") and ent:GetIsInCombat()
                        return isAlive and isUmbraReceiver and not ent:GetHasUmbra() and isInUmbraRange and isInCombat
                    else
                        return false
                    end
                end)

        local distance, nearestFriendly = GetMinTableEntry( umbraTargets,
                function( mem )
                    -- prioritize non-self targets
                    if mem.entId == lerk:GetId() then
                        return 10.0
                    else
                        return playerPos:GetDistance(mem.lastSeenPos)
                    end
                end)

        return nearestFriendly

    end)

    s:Add("nearestSporesTarget",
        function(db, lerk)

            local enemyTeam = GetEnemyTeamNumber(lerk:GetTeamNumber())
            local teamBrain = GetTeamBrain(lerk:GetTeamNumber())
            local lerkPos = lerk:GetOrigin()

            local bestDist = 999.0
            local bestEnt = nil

            for _, mem in teamBrain:IterMemoriesNearLocation(lerk:GetLocationName(), enemyTeam) do
                local ent = Shared.GetEntity(mem.entId)

                if ent:isa("Player") and ent:GetIsAlive() then
                    local distance = lerkPos:GetDistance(ent:GetOrigin())

                    if distance < bestDist and distance < kLerkBrainMaxSporeDist then
                        bestDist = distance
                        bestEnt = ent
                    end
                end
            end

            return bestEnt

        end)

    CreateAlienThreatSense(s, EstimateLerkResponseUtility)

    s:Add("nearestHive", function(db, player)

        local hives = GetEntitiesForTeam("Hive", player:GetTeamNumber())

        local builtHives = {}

        -- retreat only to built hives
        for _, hive in ipairs(hives) do

            if hive:GetIsBuilt() and hive:GetIsAlive() then
                table.insert(builtHives, hive)
            end

        end

        local distance, nearestHive = GetMinTableEntry( builtHives,
                function( hive )
                    return select(2, GetTunnelDistanceForAlien(player, hive))
                end)

        return { hive = nearestHive, distance = distance }
    end)

    s:Add("nearestThreat", function(db, player)
        local playerPos = player:GetOrigin()

        local teamBrain = GetTeamBrain(player:GetTeamNumber())
        local enemyTeam = GetEnemyTeamNumber(player:GetTeamNumber())

        local bestDist = 999.0
        local bestMem = nil

        for _, mem in teamBrain:IterMemoriesNearLocation(player:GetLocationName(), enemyTeam) do

            local isThreat = mem.btype == kMinimapBlipType.Exo
                or mem.btype == kMinimapBlipType.Marine
                or mem.btype == kMinimapBlipType.JetpackMarine
                or mem.btype == kMinimapBlipType.ARC
                or mem.btype == kMinimapBlipType.Sentry

            local dist = playerPos:GetDistance(mem.lastSeenPos)
            if isThreat and dist < bestDist then
                bestDist = dist
                bestMem = mem
            end
        end

        return {distance = bestDist, memory = bestMem}
    end)

    CreateAlienCommPingSense(s)

    return s
end

local function GotRequirements(player, upgrade)
    if upgrade then
        local requirements = upgrade:GetRequirements()
        -- does this up needs other ups??
        if requirements then
            local requiredUpgrade = GetUpgradeFromId(requirements)
            return player:GetHasCombatUpgrade(requiredUpgrade:GetId())
        else
            return true
        end
    end
    return false
end

local function CreateBuyCombatUpgradeAction(techId, weightIfCanDo)

    return function(bot, brain)

        local name = "combat_" .. EnumToString( kTechId, techId )
        local weight = 0.0
        local upgrade = GetUpgradeFromTechId(techId)
        local player = bot:GetPlayer()

        -- limit how often we can try to buy things
        if not(bot.lastCombatBuyAction and bot.lastCombatBuyAction + 5 > Shared.GetTime()) then
            local resources = player:GetResources()
            local cost = upgrade:GetLevels()
            local hasUpgrade = player:GetHasCombatUpgrade(upgrade:GetId())
            local doable = GotRequirements(player, upgrade)
            local hardCapped = upgrade:GetIsHardCappedForBots(player)

            if not hardCapped and doable and not hasUpgrade and cost <= resources then
                weight = weightIfCanDo
            end

        end


        return {
            name = name, weight = weight,
            perform = function(move)
                bot.lastCombatBuyAction = Shared.GetTime()

                -- todo: support multiple upgrades at a time...?
                --Log("Trying to upgrade " .. upgrade:GetDescription())
                local upgradeTable = {}
                table.insert(upgradeTable, upgrade)
                player:CoEnableUpgrade(upgradeTable)


            end }
    end
end


-- todo: don't block movement!!
-- make the first upgrades kinda crappy so it's more fun for everyone
table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Carapace,     0.3 + math.random() ))
table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Regeneration,    3.0 + math.random() ))
table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Vampirism,     0.3 + math.random() ))
if not kCombatCompMode then
    table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Camouflage,          0.3 + math.random() ))
    --table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Aura,          0.3 + math.random() ))
    --table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.ShadeInk,          0.3 + math.random() ))
    table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Focus,          0.3 + math.random() ))
end
table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Celerity,      3.0 + math.random() ))
table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Adrenaline,      2.0 + math.random() ))
table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.Crush,          0.3 + math.random() ))

table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.BioMassTwo,     2.0 + math.random() * 2.0 ))
table.insert(kLerkBrainActions, CreateBuyCombatUpgradeAction(kTechId.BioMassThree,     2.3 + math.random() ))