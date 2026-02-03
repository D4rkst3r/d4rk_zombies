-- ====================================
-- IMPROVED ZOMBIE AI SYSTEM V2.1.1 (SPAWN FIX)
-- ====================================

ImprovedZombieAI = {}
ImprovedZombieAI.StuckZombies = {}
ImprovedZombieAI.ZombieGroups = {}
ImprovedZombieAI.SprintingZombies = {}

function ImprovedZombieAI:Init()
    self:StartStuckDetection()
    self:StartGroupBehavior()
    self:StartSprintSystem()
    self:OverrideZombieManager()

    if Config.Debug then
        print("^2[D4RK ZOMBIES]^0 Improved AI System V2.1.1 initialized")
    end
end

-- ====================================
-- ZOMBIE ACTIVATION (NEW - FIX SPAWN STANDING)
-- ====================================

function ImprovedZombieAI:ActivateZombie(zombieOrEntity)
    local entity

    -- ✅ Akzeptiere ENTWEDER Zombie-Objekt ODER direkt Entity
    if type(zombieOrEntity) == "table" then
        -- Es ist ein Zombie-Objekt
        if not zombieOrEntity or not zombieOrEntity.entity then
            if Config.Debug then
                print("^1[AI]^0 ActivateZombie: Invalid zombie object")
            end
            return
        end
        entity = zombieOrEntity.entity
    else
        -- Es ist direkt die Entity (NUMBER)
        entity = zombieOrEntity
    end

    -- ✅ ENTITY-CHECK
    if not entity or not DoesEntityExist(entity) then
        if Config.Debug then
            print("^1[AI]^0 ActivateZombie: Entity doesn't exist")
        end
        return
    end

    -- Force AI Activation
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetPedKeepTask(entity, true)

    -- Gib sofort eine Task
    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then return end

    local playerCoords = GetEntityCoords(playerPed)
    local zombieCoords = GetEntityCoords(entity)
    local distance = #(playerCoords - zombieCoords)

    -- Wenn Spieler in der Nähe → sofort Aggro
    if distance < 30.0 then
        TaskGoToEntity(entity, playerPed, -1, 1.5, 2.0, 1073741824, 0)

        if Config.Debug then
            print("^2[AI]^0 Zombie activated with immediate aggro (distance: " .. math.floor(distance) .. "m)")
        end
    else
        -- Sonst: Wander-Task
        local angle = math.random() * 2 * math.pi
        local dist = math.random(5, 15)

        local x = zombieCoords.x + (math.cos(angle) * dist)
        local y = zombieCoords.y + (math.sin(angle) * dist)

        local found, z = GetGroundZFor_3dCoord(x, y, zombieCoords.z + 10.0, false)

        if found then
            TaskGoToCoordAnyMeans(entity, x, y, z, 0.8, 0, false, 786603, 0.0)

            if Config.Debug then
                print("^2[AI]^0 Zombie activated with wander task")
            end
        end
    end

    -- Initialisiere Stuck-Data
    self.StuckZombies[entity] = {
        lastPos = zombieCoords,
        stuckTime = 0,
        lastCheck = GetGameTimer(),
        unstuckAttempts = 0
    }
end

-- ====================================
-- STUCK DETECTION & FIX (Verbessert)
-- ====================================

function ImprovedZombieAI:StartStuckDetection()
    CreateThread(function()
        while true do
            Wait(5000) -- Check alle 5 Sekunden

            for zoneName, zombies in pairs(ZombieManager.ActiveZombies) do
                for i, zombie in ipairs(zombies) do
                    if zombie and DoesEntityExist(zombie.entity) and not zombie.isDead then
                        self:CheckIfStuck(zombie, zoneName)
                    end
                end
            end
        end
    end)
end

function ImprovedZombieAI:CheckIfStuck(zombie, zoneName)
    local entity = zombie.entity
    local currentPos = GetEntityCoords(entity)

    -- Initialisiere Stuck-Data
    if not self.StuckZombies[entity] then
        self.StuckZombies[entity] = {
            lastPos = currentPos,
            stuckTime = 0,
            lastCheck = GetGameTimer(),
            unstuckAttempts = 0
        }
        return
    end

    local stuckData = self.StuckZombies[entity]
    local distance = #(currentPos - stuckData.lastPos)
    local timeSinceCheck = GetGameTimer() - stuckData.lastCheck

    -- Zombie hat sich weniger als 1m bewegt in 5 Sekunden?
    if distance < 1.0 and zombie.hasAggro then
        stuckData.stuckTime = stuckData.stuckTime + timeSinceCheck

        -- Nach 10 Sekunden = definitiv stuck
        if stuckData.stuckTime > 10000 then
            self:UnstuckZombie(zombie, zoneName)
            stuckData.stuckTime = 0
            stuckData.unstuckAttempts = stuckData.unstuckAttempts + 1

            -- Nach 3 Versuchen = Zombie löschen und neu spawnen
            if stuckData.unstuckAttempts >= 3 then
                if Config.Debug then
                    print("^1[AI]^0 Zombie permanently stuck - respawning")
                end
                DeleteEntity(entity)
                self.StuckZombies[entity] = nil
                return
            end
        end
    else
        -- Reset wenn Zombie sich bewegt hat
        stuckData.stuckTime = 0
        stuckData.unstuckAttempts = 0
    end

    stuckData.lastPos = currentPos
    stuckData.lastCheck = GetGameTimer()
end

function ImprovedZombieAI:UnstuckZombie(zombie, zoneName)
    local entity = zombie.entity

    if Config.Debug then
        print("^3[AI]^0 Zombie stuck detected - fixing...")
    end

    -- Methode 1: Task clearen und neu setzen
    ClearPedTasksImmediately(entity)

    -- Methode 2: Kurzer Teleport (2-3 Meter in Richtung Spieler)
    local coords = GetEntityCoords(entity)
    local playerCoords = GetEntityCoords(PlayerPedId())

    local dirX = playerCoords.x - coords.x
    local dirY = playerCoords.y - coords.y
    local length = math.sqrt(dirX * dirX + dirY * dirY)

    if length > 0 then
        dirX = dirX / length
        dirY = dirY / length

        local newX = coords.x + (dirX * 3.0)
        local newY = coords.y + (dirY * 3.0)
        local found, newZ = GetGroundZFor_3dCoord(newX, newY, coords.z + 5.0, false)

        if found then
            SetEntityCoords(entity, newX, newY, newZ, false, false, false, false)
        end
    end

    -- Methode 3: Force zum Spieler
    local playerPed = PlayerPedId()
    TaskGoToEntity(entity, playerPed, -1, 0.0, 2.5, 1073741824, 0)
end

-- ====================================
-- WANDER BEHAVIOR (NEW)
-- ====================================

function ImprovedZombieAI:MakeZombieWander(zombieOrEntity, currentPos)
    local entity

    -- ✅ Akzeptiere ENTWEDER Zombie-Objekt ODER direkt Entity
    if type(zombieOrEntity) == "table" then
        if not zombieOrEntity or not zombieOrEntity.entity then
            if Config.Debug then
                print("^1[AI]^0 MakeZombieWander: Invalid zombie object")
            end
            return
        end
        entity = zombieOrEntity.entity
    else
        entity = zombieOrEntity
    end

    if not DoesEntityExist(entity) then return end

    -- Falls keine Position übergeben wurde, hole aktuelle
    if not currentPos then
        currentPos = GetEntityCoords(entity)
    end

    local angle = math.random() * 2 * math.pi
    local distance = math.random(5, 15) -- 5-15 Meter

    local x = currentPos.x + (math.cos(angle) * distance)
    local y = currentPos.y + (math.sin(angle) * distance)

    local found, z = GetGroundZFor_3dCoord(x, y, currentPos.z + 10.0, false)

    if found then
        local targetPos = vector3(x, y, z)
        TaskGoToCoordAnyMeans(entity, targetPos.x, targetPos.y, targetPos.z, 0.8, 0, false, 786603, 0.0)

        if Config.Debug then
            print("^2[AI]^0 Zombie wandering to new position")
        end
    end
end

-- ====================================
-- GROUP BEHAVIOR (Zombies bleiben zusammen)
-- ====================================

function ImprovedZombieAI:StartGroupBehavior()
    CreateThread(function()
        while true do
            Wait(3000) -- Update alle 3 Sekunden

            for zoneName, zombies in pairs(ZombieManager.ActiveZombies) do
                if #zombies >= 3 then -- Mindestens 3 Zombies für Gruppe
                    self:FormGroup(zoneName, zombies)
                end
            end
        end
    end)
end

function ImprovedZombieAI:FormGroup(zoneName, zombies)
    -- Finde Gruppen-Center (durchschnittliche Position)
    local centerX, centerY, centerZ = 0, 0, 0
    local validCount = 0

    for _, zombie in ipairs(zombies) do
        if zombie and DoesEntityExist(zombie.entity) and not zombie.isDead then
            local coords = GetEntityCoords(zombie.entity)
            centerX = centerX + coords.x
            centerY = centerY + coords.y
            centerZ = centerZ + coords.z
            validCount = validCount + 1
        end
    end

    if validCount == 0 then return end

    local groupCenter = vector3(
        centerX / validCount,
        centerY / validCount,
        centerZ / validCount
    )

    -- Zombies die zu weit von Gruppe sind → zurück zur Gruppe
    for _, zombie in ipairs(zombies) do
        if zombie and DoesEntityExist(zombie.entity) and not zombie.isDead and not zombie.hasAggro then
            local coords = GetEntityCoords(zombie.entity)
            local distanceFromGroup = #(coords - groupCenter)

            -- Über 20m von Gruppe entfernt?
            if distanceFromGroup > 20.0 then
                -- Langsam zurück zur Gruppe
                TaskGoToCoordAnyMeans(zombie.entity, groupCenter.x, groupCenter.y, groupCenter.z, 0.8, 0, false, 786603,
                    0.0)

                if Config.Debug then
                    DrawLine(coords.x, coords.y, coords.z, groupCenter.x, groupCenter.y, groupCenter.z, 255, 165, 0, 150)
                end
            end
        end
    end
end

-- ====================================
-- SPRINT SYSTEM (Nur für Runner)
-- ====================================

function ImprovedZombieAI:StartSprintSystem()
    CreateThread(function()
        while true do
            Wait(1000)

            for zoneName, zombies in pairs(ZombieManager.ActiveZombies) do
                for _, zombie in ipairs(zombies) do
                    if zombie and DoesEntityExist(zombie.entity) and not zombie.isDead then
                        self:UpdateSprintStatus(zombie)
                    end
                end
            end
        end
    end)
end

function ImprovedZombieAI:UpdateSprintStatus(zombie)
    local typeData = Config.ZombieTypes[zombie.type]

    -- Nur Runner & Exploder können sprinten
    if zombie.type ~= 'runner' and zombie.type ~= 'exploder' then
        return
    end

    local entity = zombie.entity
    local playerPed = PlayerPedId()
    local zombieCoords = GetEntityCoords(entity)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(zombieCoords - playerCoords)

    -- Sprint nur wenn Spieler in Sichtweite (10-30m)
    if zombie.hasAggro and distance >= 10.0 and distance <= 30.0 then
        if not self.SprintingZombies[entity] then
            -- Sprint aktivieren
            SetPedMoveRateOverride(entity, 2.0) -- Doppelte Speed
            self.SprintingZombies[entity] = true

            if Config.Debug then
                print("^2[AI]^0 " .. zombie.type .. " is sprinting!")
            end
        end
    else
        if self.SprintingZombies[entity] then
            -- Sprint deaktivieren
            SetPedMoveRateOverride(entity, typeData.Speed)
            self.SprintingZombies[entity] = nil
        end
    end
end

-- ====================================
-- HEALTH-BASED BEHAVIOR
-- ====================================

function ImprovedZombieAI:GetHealthPercentage(entity)
    local health = GetEntityHealth(entity)
    local maxHealth = GetEntityMaxHealth(entity)
    return (health / maxHealth) * 100
end

function ImprovedZombieAI:ApplyHealthBehavior(zombie)
    local entity = zombie.entity
    local healthPercent = self:GetHealthPercentage(entity)
    local typeData = Config.ZombieTypes[zombie.type]

    -- Unter 30% HP = langsamer + aggressiver
    if healthPercent < 30 then
        SetPedMoveRateOverride(entity, typeData.Speed * 0.7) -- 30% langsamer
        SetPedCombatRange(entity, 0)                         -- Sehr aggressiv

        -- Blutet stärker
        if math.random() < 0.3 then
            local boneIndex = GetPedBoneIndex(entity, 31086)
            UseParticleFxAsset("core")
            StartParticleFxNonLoopedOnPedBone(
                "scr_bike_adversary",
                "scr_adversary_ped_glow",
                entity,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                boneIndex,
                0.5,
                false, false, false
            )
        end
    end

    -- Unter 10% HP = "Berserk" Mode (nur Tank)
    if healthPercent < 10 and zombie.type == 'tank' then
        SetPedCombatMovement(entity, 3)                      -- Offensive
        SetPedMoveRateOverride(entity, typeData.Speed * 1.5) -- Schneller
    end
end

-- ====================================
-- IMPROVED PATHFINDING
-- ====================================

function ImprovedZombieAI:SmartPathfinding(zombie, targetPos)
    local entity = zombie.entity
    local zombiePos = GetEntityCoords(entity)
    local distance = #(zombiePos - targetPos)

    -- Kurze Distanz = direkt
    if distance < 10.0 then
        TaskGoStraightToCoord(entity, targetPos.x, targetPos.y, targetPos.z, 2.5, -1, 0.0, 0.0)
        return
    end

    -- Mittlere Distanz = TaskGoToCoordAnyMeans (nutzt Wege)
    if distance < 50.0 then
        TaskGoToCoordAnyMeans(entity, targetPos.x, targetPos.y, targetPos.z, 2.0, 0, false, 786603, 0.0)
        return
    end

    -- Lange Distanz = TaskGoToEntity (besseres Pathfinding)
    local playerPed = PlayerPedId()
    TaskGoToEntity(entity, playerPed, -1, 0.0, 2.5, 1073741824, 0)
end

-- ====================================
-- IMPROVED ATTACK SYSTEM
-- ====================================

function ImprovedZombieAI:ImprovedAttack(zombie, playerPed, playerCoords)
    local entity = zombie.entity
    local zombieCoords = GetEntityCoords(entity)
    local typeData = Config.ZombieTypes[zombie.type]
    local distance = #(playerCoords - zombieCoords)

    -- Health-basiertes Verhalten anwenden
    self:ApplyHealthBehavior(zombie)

    -- In Angriffs-Reichweite?
    if distance <= typeData.AttackRange then
        local currentTime = GetGameTimer()

        if currentTime - (zombie.lastAttack or 0) >= typeData.AttackCooldown then
            -- Clear alte Tasks
            ClearPedTasks(entity)

            -- Verschiedene Angriffs-Animationen je nach Typ
            local attackAnims = self:GetAttackAnimations(zombie.type)
            local randomAnim = attackAnims[math.random(#attackAnims)]

            self:PlayAttackAnimation(entity, randomAnim.dict, randomAnim.anim)

            -- Damage nach kurzer Verzögerung
            SetTimeout(300, function()
                if DoesEntityExist(entity) and DoesEntityExist(playerPed) then
                    local finalDistance = #(GetEntityCoords(entity) - GetEntityCoords(playerPed))

                    if finalDistance <= typeData.AttackRange + 1.0 then
                        -- Damage
                        if Config.Combat.ZombieMeleeDamage then
                            local damage = typeData.Damage

                            -- Bonus-Damage bei wenig HP (Berserk)
                            local healthPercent = self:GetHealthPercentage(entity)
                            if healthPercent < 30 then
                                damage = damage * 1.5
                            end

                            ApplyDamageToPed(playerPed, damage, false)

                            -- Screen Shake
                            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)

                            -- Blood Effect
                            if Config.Combat.BloodEffect then
                                local boneIndex = GetPedBoneIndex(playerPed, 31086)
                                UseParticleFxAsset("core")
                                StartParticleFxNonLoopedOnPedBone(
                                    "scr_bike_adversary",
                                    "scr_adversary_weap_glow",
                                    playerPed,
                                    0.0, 0.0, 0.0,
                                    0.0, 0.0, 0.0,
                                    boneIndex,
                                    0.3,
                                    false, false, false
                                )
                            end
                        end
                    end
                end
            end)

            zombie.lastAttack = currentTime
        end
    else
        -- Laufe zum Spieler mit Smart Pathfinding
        self:SmartPathfinding(zombie, playerCoords)
    end
end

-- ====================================
-- ATTACK ANIMATIONS
-- ====================================

function ImprovedZombieAI:GetAttackAnimations(zombieType)
    local animations = {
        tank = {
            { dict = "melee@large_wpn@streamed_core",       anim = "ground_attack_on_spot" },
            { dict = "melee@large_wpn@streamed_core",       anim = "heavy_attack_l" },
            { dict = "melee@large_wpn@streamed_variations", anim = "plyr_takedown_front_headlock" }
        },
        runner = {
            { dict = "melee@unarmed@streamed_variations", anim = "plyr_takedown_front_elbow" },
            { dict = "melee@unarmed@streamed_variations", anim = "plyr_takedown_front_slap" },
            { dict = "melee@unarmed@streamed_core",       anim = "plyr_takedown_front_headbutt" }
        },
        crawler = {
            { dict = "melee@unarmed@streamed_core", anim = "plyr_takedown_front_headbutt" },
            { dict = "melee@unarmed@streamed_core", anim = "plyr_grapple_punches" }
        },
        exploder = {
            { dict = "melee@unarmed@streamed_variations", anim = "plyr_takedown_front_elbow" },
            { dict = "melee@unarmed@streamed_core",       anim = "plyr_takedown_front_headbutt" }
        }
    }

    return animations[zombieType] or animations.crawler
end

function ImprovedZombieAI:PlayAttackAnimation(entity, dict, anim)
    RequestAnimDict(dict)

    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 2000 do
        Wait(10)
        timeout = timeout + 10
    end

    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(entity, dict, anim, 8.0, -8.0, -1, 48, 0, false, false, false)
    end
end

-- ====================================
-- OBSTACLE DETECTION (Fenster/Türen)
-- ====================================

function ImprovedZombieAI:CheckObstacles(zombie, targetPos)
    local entity = zombie.entity
    local zombiePos = GetEntityCoords(entity)

    -- Raycast zum Spieler
    local rayHandle = StartShapeTestRay(
        zombiePos.x, zombiePos.y, zombiePos.z + 1.0,
        targetPos.x, targetPos.y, targetPos.z + 1.0,
        1, -- Hit world
        entity,
        7
    )

    local _, hit, hitCoords, _, materialHash = GetShapeTestResult(rayHandle)

    if hit then
        -- Hindernis gefunden
        if Config.ZombieAI and Config.ZombieAI.BreakThroughObjects then
            -- Versuche durchzubrechen
            self:BreakThroughObstacle(zombie, hitCoords)
        else
            -- Umweg suchen
            self:FindAlternatePath(zombie, targetPos)
        end
        return true
    end

    return false
end

function ImprovedZombieAI:BreakThroughObstacle(zombie, obstaclePos)
    local entity = zombie.entity

    -- Animation: Schlagen
    self:PlayAttackAnimation(entity, "melee@unarmed@streamed_core", "plyr_takedown_front_slap")

    -- Sound Effect
    PlaySoundFromCoord(-1, "CHECKPOINT_UNDER_THE_BRIDGE", obstaclePos.x, obstaclePos.y, obstaclePos.z,
        "HEIST_MINIGAME_SOUNDSET", false, 10.0, false)

    -- Particle Effect
    UseParticleFxAsset("core")
    StartParticleFxNonLoopedAtCoord(
        "ent_dst_wood",
        obstaclePos.x, obstaclePos.y, obstaclePos.z,
        0.0, 0.0, 0.0,
        0.5,
        false, false, false
    )
end

function ImprovedZombieAI:FindAlternatePath(zombie, targetPos)
    -- Versuche links/rechts um Hindernis herum
    local entity = zombie.entity
    local zombiePos = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)

    -- 45° links oder rechts
    local newHeading = math.random() > 0.5 and (heading + 45) or (heading - 45)
    local rad = math.rad(newHeading)

    local offsetX = math.cos(rad) * 5.0
    local offsetY = math.sin(rad) * 5.0

    local newPos = vector3(
        zombiePos.x + offsetX,
        zombiePos.y + offsetY,
        zombiePos.z
    )

    TaskGoToCoordAnyMeans(entity, newPos.x, newPos.y, newPos.z, 1.8, 0, false, 786603, 0.0)
end

-- ====================================
-- INTEGRATION INTO ZOMBIE MANAGER
-- ====================================

function ImprovedZombieAI:OverrideZombieManager()
    -- Ersetze die Standard-Angriffsfunktion
    local originalAttack = ZombieManager.AttackPlayer

    ZombieManager.AttackPlayer = function(self, zombie, playerPed, playerCoords, currentTime)
        -- Nutze verbesserte AI
        ImprovedZombieAI:ImprovedAttack(zombie, playerPed, playerCoords)
    end

    if Config.Debug then
        print("^2[D4RK ZOMBIES]^0 AI Overrides applied")
    end
end

-- ====================================
-- CLEANUP
-- ====================================

function ImprovedZombieAI:Cleanup()
    -- Entferne Stuck-Data für gelöschte Entities
    for entity, _ in pairs(self.StuckZombies) do
        if not DoesEntityExist(entity) then
            self.StuckZombies[entity] = nil
        end
    end

    -- Entferne Sprint-Status für gelöschte Entities
    for entity, _ in pairs(self.SprintingZombies) do
        if not DoesEntityExist(entity) then
            self.SprintingZombies[entity] = nil
        end
    end
end

CreateThread(function()
    while true do
        Wait(60000) -- Cleanup alle 60 Sekunden
        ImprovedZombieAI:Cleanup()
    end
end)
