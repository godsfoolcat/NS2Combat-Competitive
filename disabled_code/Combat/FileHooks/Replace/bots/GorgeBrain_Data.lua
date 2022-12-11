
Script.Load("lua/bots/CommonActions.lua")
Script.Load("lua/bots/BrainSenses.lua")

------------------------------------------
--  More urgent == should really attack it ASAP
------------------------------------------
local function GetAttackUrgency(bot, mem)

    -- See if we know whether if it is alive or not
    local ent = Shared.GetEntity(mem.entId)
    if not HasMixin(ent, "Live") or not ent:GetIsAlive() or (ent.GetTeamNumber and ent:GetTeamNumber() == bot:GetTeamNumber()) then
        return 0.0
    end
    
    local botPos = bot:GetPlayer():GetOrigin()
    local targetPos = ent:GetOrigin()
    local distance = botPos:GetDistance(targetPos)

    if mem.btype == kMinimapBlipType.PowerPoint then
        local powerPoint = ent
        if powerPoint ~= nil and powerPoint:GetIsSocketed() then
            return 0.65
        else
            return 0
        end    
    end
        
    local immediateThreats = {
        [kMinimapBlipType.Marine] = true,
        [kMinimapBlipType.JetpackMarine] = true,
        [kMinimapBlipType.Exo] = true,    
        [kMinimapBlipType.Sentry] = true,
        [kMinimapBlipType.Embryo] = true,
        [kMinimapBlipType.Hydra]  = true,
        [kMinimapBlipType.Whip]   = true,
        [kMinimapBlipType.Skulk]  = true,
        [kMinimapBlipType.Gorge]  = true,
        [kMinimapBlipType.Lerk]   = true,
        [kMinimapBlipType.Fade]   = true,
        [kMinimapBlipType.Onos]   = true,
    }
    if table.contains(kMinimapBlipType, "Prowler") then
        immediateThreats[kMinimapBlipType.Prowler] = 1
    end
    
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
        [kMinimapBlipType.Marine] =             numOthers >= 4 and 0.6 or 1,
        [kMinimapBlipType.JetpackMarine] =      numOthers >= 4 and 0.7 or 1.1,
        [kMinimapBlipType.Exo] =                numOthers >= 6 and 0.8 or 1.2,
        [kMinimapBlipType.Sentry] =             numOthers >= 3 and 0.5 or 0.95,
        
        -- Structures
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
        
        -- from marine
        [kMinimapBlipType.Embryo] = numOthers >= 1 and 0.1 or 1.0,
        [kMinimapBlipType.Hydra] = numOthers >= 2  and 0.1 or 2.0,
        [kMinimapBlipType.Whip] = numOthers >= 2   and 0.1 or 3.0,
        [kMinimapBlipType.Skulk] = numOthers >= 2  and 0.1 or 4.0,
        [kMinimapBlipType.Gorge] =  numOthers >= 2  and 0.1 or 3.0,
        [kMinimapBlipType.Lerk] = numOthers >= 2   and 0.1 or 5.0,
        [kMinimapBlipType.Fade] = numOthers >= 3   and 0.1 or 6.0,
        [kMinimapBlipType.Onos] =  numOthers >= 4  and 0.1 or 7.0,
        
        [kMinimapBlipType.Crag] = numOthers >= 2           and 0.2 or 0.95, -- kind of a special case
        [kMinimapBlipType.Hive] = numOthers >= 6           and 0.5 or 0.9,
        [kMinimapBlipType.Harvester] = numOthers >= 2      and 0.4 or 0.8,
        [kMinimapBlipType.Egg] = numOthers >= 1            and 0.2 or 0.5,
        [kMinimapBlipType.Shade] = numOthers >= 2          and 0.2 or 0.5,
        [kMinimapBlipType.Shift] = numOthers >= 2          and 0.2 or 0.5,
        [kMinimapBlipType.Shell] = numOthers >= 2          and 0.2 or 0.5,
        [kMinimapBlipType.Veil] = numOthers >= 2           and 0.2 or 0.5,
        [kMinimapBlipType.Spur] = numOthers >= 2           and 0.2 or 0.5,
        [kMinimapBlipType.TunnelEntrance] = numOthers >= 1 and 0.2 or 0.5,
    }

    if urgencies[ mem.btype ] ~= nil then
        return urgencies[ mem.btype ]
    end

    return 0.0
    
end


local function PerformAttackEntity( eyePos, bestTarget, bot, brain, move )

    assert( bestTarget )

    local marinePos = bestTarget:GetOrigin()

    local doFire = false
    bot:GetMotion():SetDesiredMoveTarget( marinePos )
    
    local distance = eyePos:GetDistance(marinePos)
    if distance < 25 and bot:GetBotCanSeeTarget( bestTarget ) then
        doFire = true
    end
    
    -- this needs to be done smarter, gorge should have a "retreat" during which it uses healspray
    if bot:GetPlayer():GetHealthFraction() < 0.8 then
        move.commands = AddMoveCommand( move.commands, Move.SecondaryAttack )
        
    elseif doFire then
        -- jitter view target a little bit
        -- local jitter = Vector( math.random(), math.random(), math.random() ) * 0.1
        bot:GetMotion():SetDesiredViewTarget( bestTarget:GetEngagementPoint() )
        move.commands = AddMoveCommand( move.commands, Move.PrimaryAttack )
 

        if GetDistanceToTouch(eyePos, bestTarget) < 10 then
            -- Stop running at the structure when close enough
            bot:GetMotion():SetDesiredMoveTarget(nil)
            
        end
 
    else
        bot:GetMotion():SetDesiredViewTarget( nil )

        -- Occasionally jump
        if math.random() < 0.01 and bot:GetPlayer():GetIsOnGround() then
            move.commands = AddMoveCommand( move.commands, Move.Jump )
            if distance < 15 then
                -- When approaching, try to jump sideways
                bot.timeOfJump = Shared.GetTime()
                bot.jumpOffset = nil
            end    
        end        
    end
    
    if bot.timeOfJump ~= nil and Shared.GetTime() - bot.timeOfJump < 0.5 then
        
        if bot.jumpOffset == nil then
            
            local botToTarget = GetNormalizedVectorXZ(marinePos - eyePos)
            local sideVector = botToTarget:CrossProduct(Vector(0, 1, 0))                
            if math.random() < 0.5 then
                bot.jumpOffset = botToTarget + sideVector
            else
                bot.jumpOffset = botToTarget - sideVector
            end            
            bot:GetMotion():SetDesiredViewTarget( bestTarget:GetEngagementPoint() )
            
        end
        
        bot:GetMotion():SetDesiredMoveDirection( bot.jumpOffset )
    end    
    
end

local function PerformAttack( eyePos, mem, bot, brain, move )

    assert( mem )

    local target = Shared.GetEntity(mem.entId)

    if target ~= nil then

        PerformAttackEntity( eyePos, target, bot, brain, move )

    else
    
        -- mem is too far to be relevant, so move towards it
        bot:GetMotion():SetDesiredViewTarget(nil)
        bot:GetMotion():SetDesiredMoveTarget(mem.lastSeenPos)

    end
    
    brain.teamBrain:AssignBotToMemory(bot, mem)

end

------------------------------------------
--  Each want function should return the fuzzy weight,
-- along with a closure to perform the action
-- The order they are listed matters - actions near the beginning of the list get priority.
------------------------------------------
kGorgeBrainActions =
{
    
    ------------------------------------------
    --
    ------------------------------------------
    function(bot, brain)
        return { name = "debug idle", weight = 0.001,
                perform = function(move)
                    bot:GetMotion():SetDesiredMoveTarget(nil)
                    -- there is nothing obvious to do.. figure something out
                    -- like go to the marines, or defend
                end }
    end,

    ------------------------------------------
    --
    ------------------------------------------
    CreateExploreAction( 0.01, function(pos, targetPos, bot, brain, move)
                bot:GetMotion():SetDesiredMoveTarget(targetPos)
                bot:GetMotion():SetDesiredViewTarget(nil)
                end ),
    
    ------------------------------------------
    --
    ------------------------------------------
    function(bot, brain)
        local name = "evolve"

        local weight = 0.0
        local player = bot:GetPlayer()

        -- Hallucinations don't evolve
        if player.isHallucination then
            return { name = name, weight = weight,
                perform = function() end }
        end

        local s = brain:GetSenses()
        local res = player:GetPersonalResources()

        local distanceToNearestThreat = s:Get("nearestThreat").distance
        local desiredUpgrades = {}

        if player:GetIsAllowedToBuy() and
                (distanceToNearestThreat == nil or distanceToNearestThreat > 15) and
                (player.GetIsInCombat == nil or not player:GetIsInCombat()) then

            -- Safe enough to try to evolve

            local existingUpgrades = player:GetUpgrades()

            local avaibleUpgrades = player.lifeformUpgrades

            if not avaibleUpgrades then
                avaibleUpgrades = {}

                local kUpgradeStructureTable = AlienTeam.GetUpgradeStructureTable()
                for i = 1, #kUpgradeStructureTable do
                    local upgrades = kUpgradeStructureTable[i].upgrades
                    table.insert(avaibleUpgrades, table.random(upgrades))
                end

                if player.lifeformEvolution then
                    table.insert(avaibleUpgrades, player.lifeformEvolution)
                end

                player.lifeformUpgrades = avaibleUpgrades
            end

            for i = 1, #avaibleUpgrades do
                local techId = avaibleUpgrades[i]
                local techNode = player:GetTechTree():GetTechNode(techId)

                local isAvailable = false
                local cost = 0
                if techNode ~= nil then
                    isAvailable = techNode:GetAvailable(player, techId, false)
                    cost = LookupTechData(techId, kTechDataGestateName) and GetCostForTech(techId) or LookupTechData(kTechId.Gorge, kTechDataUpgradeCost, 0)
                end

                if not player:GetHasUpgrade(techId) and isAvailable and res - cost > 0 and
                        GetIsUpgradeAllowed(player, techId, existingUpgrades) and
                        GetIsUpgradeAllowed(player, techId, desiredUpgrades) then
                    res = res - cost
                    table.insert(desiredUpgrades, techId)
                end
            end

            if  #desiredUpgrades > 0 then
                weight = 100.0
            end
        end

        return { name = name, weight = weight,
            perform = function(move)
                player:ProcessBuyAction( desiredUpgrades )
            end }

    end,

    ------------------------------------------
    --
    ------------------------------------------
    function(bot, brain)
        local name = "attack"
        local skulk = bot:GetPlayer()
        local eyePos = skulk:GetEyePos()
        
        local memories = GetTeamMemories(skulk:GetTeamNumber())
        local bestUrgency, bestMem = GetMaxTableEntry( memories, 
                function( mem )
                    return GetAttackUrgency( bot, mem )
                end)
        
        local weapon = skulk:GetActiveWeapon()
        local canAttack = weapon ~= nil and weapon:isa("SpitSpray")

        local weight = 0.0

        if canAttack and bestMem ~= nil then

            local dist = 0.0
            if Shared.GetEntity(bestMem.entId) ~= nil then
                dist = GetDistanceToTouch( eyePos, Shared.GetEntity(bestMem.entId) )
            else
                dist = eyePos:GetDistance( bestMem.lastSeenPos )
            end

            weight = EvalLPF( dist, {
                    { 0.0, EvalLPF( bestUrgency, {
                        { 0.0, 0.0 },
                        { 10.0, 25.0 }
                        })},
                    { 10.0, EvalLPF( bestUrgency, {
                            { 0.0, 0.0 },
                            { 10.0, 5.0 }
                            })},
                    { 50.0, 0.0 } })
        end

        return { name = name, weight = weight,
            perform = function(move)
                brain.teamBrain:UnassignBot(bot)
                PerformAttack( eyePos, bestMem, bot, brain, move )
            end }
    end,    

    ------------------------------------------
    --
    ------------------------------------------
    function(bot, brain)
        local name = "pheromone"
        
        local skulk = bot:GetPlayer()
        local eyePos = skulk:GetEyePos()

        local pheromones = EntityListToTable(Shared.GetEntitiesWithClassname("Pheromone"))            
        local bestPheromoneLocation = nil
        local bestValue = 0
        
        for p = 1, #pheromones do
        
            local currentPheromone = pheromones[p]
            if currentPheromone then
                local techId = currentPheromone:GetType()
                            
                if techId == kTechId.ExpandingMarker or techId == kTechId.ThreatMarker then
                
                    local location = currentPheromone:GetOrigin()
                    local locationOnMesh = Pathing.GetClosestPoint(location)
                    local distanceFromMesh = location:GetDistance(locationOnMesh)
                    
                    if distanceFromMesh > 0.001 and distanceFromMesh < 2 then
                    
                        local distance = eyePos:GetDistance(location)
                        
                        if currentPheromone.visitedBy == nil then
                            currentPheromone.visitedBy = {}
                        end
                                        
                        if not currentPheromone.visitedBy[bot] then
                        
                            if distance < 5 then 
                                currentPheromone.visitedBy[bot] = true
                            else   
            
                                -- Value goes from 5 to 10
                                local value = 5.0 + 5.0 / math.max(distance, 1.0) - #(currentPheromone.visitedBy)
                        
                                if value > bestValue then
                                    bestPheromoneLocation = locationOnMesh
                                    bestValue = value
                                end
                                
                            end    
                            
                        end    
                            
                    end
                    
                end
                        
            end
            
        end
        
        local weight = EvalLPF( bestValue, {
            { 0.0, 0.0 },
            { 10.0, 1.0 }
            })

        return { name = name, weight = weight,
            perform = function(move)
                bot:GetMotion():SetDesiredMoveTarget(bestPheromoneLocation)
                bot:GetMotion():SetDesiredViewTarget(nil)
            end }
    end,
    
    function(bot, brain)
    
        local name = "heal"
        local weight = 0.0
        local alien
        local hive
        if GetHasTimelimitPassed and GetHasTimelimitPassed() then
            weight = 0.0
        else
            local sdb = brain:GetSenses()
            alien = bot:GetPlayer()
            hive = sdb:Get("nearestHive")
            if hive then
                local health = hive:GetHealthScalar()
                weight = EvalLPF( health, {
                    { 0.0, 100.0 },
                    { 0.6, 20.0 },
                    { 0.8, 10.0 },
                    { 1.0, 0.0 }
                })
            end
        end
        return { name = name, weight = weight,
                 perform = function(move)
                     if hive then
            
                         brain.teamBrain:UnassignBot(bot)
    
                         local touchDist = GetDistanceToTouch( alien:GetEyePos(), hive )
                   
                         if touchDist > 2.5 then
        
                             --Print("Moving to hive")
                             bot:GetMotion():SetDesiredViewTarget(nil)
                             bot:GetMotion():SetDesiredMoveTarget(hive:GetEngagementPoint())
    
                         else
                             --Print("Healing hive")
                             
                             bot:GetMotion():SetDesiredViewTarget( hive:GetEngagementPoint() )
                             bot:GetMotion():SetDesiredMoveTarget( nil )
                             move.commands = AddMoveCommand( move.commands, Move.SecondaryAttack )
                         end
                     end
    
                 end }
    end,
    
    ------------------------------------------
    --
    ------------------------------------------
    function(bot, brain)
        local name = "order"

        local skulk = bot:GetPlayer()
        local order = bot:GetPlayerOrder()

        local weight = 0.0
        if order ~= nil then
            weight = 10.0
        end

        return { name = name, weight = weight,
            perform = function(move)
                if order then

                    local target = Shared.GetEntity(order:GetParam())

                    if target ~= nil and order:GetType() == kTechId.Attack then

                        PerformAttackEntity( skulk:GetEyePos(), target, bot, brain, move )
                        
                    else

                        if brain.debug then
                            DebugPrint("unknown order type: %s", ToString(order:GetType()) )
                        end

                        bot:GetMotion():SetDesiredMoveTarget( order:GetLocation() )
                        bot:GetMotion():SetDesiredViewTarget( nil )

                    end
                end
            end }
    end,    

}

------------------------------------------
--
------------------------------------------
function CreateGorgeBrainSenses()

    local s = BrainSenses()
    s:Initialize()

    s:Add("allThreats", function(db)
            local player = db.bot:GetPlayer()
            local team = player:GetTeamNumber()
            local memories = GetTeamMemories( team )
            return FilterTableEntries( memories,
                function( mem )                    
                    local ent = Shared.GetEntity( mem.entId )
                    
                    if ent:isa("Player") or ent:isa("Sentry") then
                        local isAlive = HasMixin(ent, "Live") and ent:GetIsAlive()
                        local isEnemy = HasMixin(ent, "Team") and ent:GetTeamNumber() ~= team                    
                        return isAlive and isEnemy
                    else
                        return false
                    end
                end)                
        end)

    s:Add("nearestThreat", function(db)
            local allThreats = db:Get("allThreats")
            local player = db.bot:GetPlayer()
            local playerPos = player:GetOrigin()
            
            local distance, nearestThreat = GetMinTableEntry( allThreats,
                function( mem )
                    local origin = mem.origin
                    if origin == nil then
                        origin = Shared.GetEntity(mem.entId):GetOrigin()
                    end
                    return playerPos:GetDistance(origin)
                end)

            return {distance = distance, memory = nearestThreat}
        end)
    
    s:Add("nearestHive", function(db)
        local player = db.bot:GetPlayer()
        local playerPos = player:GetOrigin()
        
        local hives = GetEntitiesForTeam("Hive", player:GetTeamNumber())
        
        local builtHives = {}
        
        -- retreat only to built hives
        for _, hive in ipairs(hives) do
            
            if hive:GetIsBuilt() and hive:GetIsAlive() and hive:GetHealthScalar() < 1.00  then
                table.insert(builtHives, hive)
            end
        
        end
        
        Shared.SortEntitiesByDistance(playerPos, builtHives)
        
        return builtHives[1]
    end)
    
    return s
end

-- are we running combat?
if kCombatVersion then
    
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
    table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.Carapace,     0.3 + math.random() ))
    table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.Regeneration,    3.0 + math.random() ))
    table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.Vampirism,     0.3 + math.random() ))
    if not kCombatCompMode then
        table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.Camouflage,          0.3 + math.random() ))
        --table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.Aura,          0.3 + math.random() ))
        --table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.ShadeInk,          0.3 + math.random() ))
        table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.Focus,          0.3 + math.random() ))
    end
    table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.Celerity,      3.0 + math.random() ))
    table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.Adrenaline,      2.0 + math.random() ))
    table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.Crush,          0.3 + math.random() ))
    
    table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.BioMassTwo,     2.0 + math.random() * 2.0 ))
    table.insert(kGorgeBrainActions, CreateBuyCombatUpgradeAction(kTechId.BioMassThree,     2.3 + math.random() ))

end