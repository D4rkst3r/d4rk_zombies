-- ====================================
-- ZOMBIE SPAWNING & AI SYSTEM (IMPROVED)
-- ====================================

local lib = exports.d4rk_lib

ZombieManager = {}
ZombieManager.ActiveZombies = {}
ZombieManager.ZoneCache = {}
ZombieManager.ZoneObjects = {} -- PolyZone objects
ZombieManager.LastUpdate = 0
ZombieManager.TotalActiveZombies = 0

function ZombieManager:Init()
    -- Setup Relationships
    AddRelationshipGroup("ZOMBIE")
    SetRelationshipBetweenGroups(5, `ZOMBIE`, `PLAYER`)
    SetRelationshipBetweenGroups(5, `PLAYER`, `ZOMBIE`)

    self:LoadZones()
    self:StartSpawnThread()
    self:StartAIThread()
    self:StartCleanupThread()

    if Config.Debug then
        print("^2[D4RK ZOMBIES]^0 Zombie Manager initialized")
    end
end

-- ====================================
-- HELPER FUNCTIONS (From old script)
-- ====================================

function ZombieManager:IsNightTime()
    local hour = GetClockHours()
    return hour >= Config.NightStartHour or hour < Config.NightEndHour
end

function ZombieManager:GetSpawnMultiplier()
    return self:IsNightTime() and Config.NightSpawnMultiplier or 1.0
end

function ZombieManager:SelectZombieType(dangerLevel)
    local modifier = Config.DangerLevelModifiers[dangerLevel] or Config.DangerLevelModifiers.medium
    local isNight = self:IsNightTime()
    local weightedTypes = {}
    local totalWeight = 0

    for typeName, zType in pairs(Config.ZombieTypes) do
        local chance = zType.SpawnChance

        -- Apply danger level modifiers
        if typeName == 'runner' then
            chance = chance * modifier.runnerChance
        elseif typeName == 'tank' then
            chance = chance * modifier.tankChance
        elseif typeName == 'exploder' then
            chance = chance * modifier.exploderChance
        end

        -- Apply night modifiers
        if isNight and Config.NightZombieModifier then
            if typeName == 'runner' then
                chance = chance * Config.NightZombieModifier.runnerChance
            elseif typeName == 'tank' then
                chance = chance * Config.NightZombieModifier.tankChance
            elseif typeName == 'exploder' then
                chance = chance * Config.NightZombieModifier.exploderChance
            end
        end

        totalWeight = totalWeight + chance
        table.insert(weightedTypes, { type = typeName, weight = chance })
    end

    local rand = math.random() * totalWeight
    local cumulative = 0

    for _, wt in ipairs(weightedTypes) do
        cumulative = cumulative + wt.weight
        if rand <= cumulative then
            return wt.type
        end
    end

    return 'crawler' -- Fallback
end

-- ====================================
-- ZONE MANAGEMENT
-- ====================================

function ZombieManager:LoadZones()
    lib.callback('d4rk_zombies:server:GetZones', false, function(zones)
        self.ZoneCache = zones or {}

        for zoneName, zoneData in pairs(self.ZoneCache) do
            self:CreateZoneObject(zoneName, zoneData)
        end

        if Config.Debug then
            print(('[D4RK ZOMBIES] %s Zonen geladen'):format(self:CountZones()))
        end
    end)
end

function ZombieManager:CreateZoneObject(name, data)
    if data.type == 'circle' then
        self.ZoneObjects[name] = CircleZone:Create(
            vector3(data.coords.x, data.coords.y, data.coords.z),
            data.radius or 50.0,
            {
                name = name,
                debugPoly = Config.ShowZoneDebug,
                useZ = true
            }
        )
    elseif data.type == 'poly' or data.type == 'polygon' then
        self.ZoneObjects[name] = PolyZone:Create(
            data.points,
            {
                name = name,
                minZ = data.minZ or (data.coords and data.coords.z - 10) or 0,
                maxZ = data.maxZ or (data.coords and data.coords.z + 20) or 100,
                debugPoly = Config.ShowZoneDebug
            }
        )
    end

    -- Create blip for zone
    if data.coords then
        local blip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, data.radius or 50.0)
        SetBlipColour(blip, 1)
        SetBlipAlpha(blip, 80)

        local centerBlip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(centerBlip, 303)
        SetBlipScale(centerBlip, 0.8)
        SetBlipColour(centerBlip, 1)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(('🧟 %s'):format(name))
        EndTextCommandSetBlipName(centerBlip)
    end
end

function ZombieManager:CountZones()
    local count = 0
    for _ in pairs(self.ZoneCache) do
        count = count + 1
    end
    return count
end

-- ====================================
-- SPAWN SYSTEM
-- ====================================

function ZombieManager:StartSpawnThread()
    CreateThread(function()
        while true do
            Wait(Config.DefaultZoneSettings.SpawnInterval)

            if self.TotalActiveZombies >= Config.Optimization.MaxActiveZombies then
                goto continue
            end

            local playerCoords = GetEntityCoords(PlayerPedId())
            local spawnMultiplier = self:GetSpawnMultiplier()

            for zoneName, zoneData in pairs(self.ZoneCache) do
                if not zoneData.enabled then goto skip end

                local zoneCoords = self:GetZoneCenter(zoneData)
                local distance = #(playerCoords - zoneCoords)

                if distance <= Config.MaxRenderDistance then
                    local maxZombies = math.floor((zoneData.maxZombies or Config.DefaultZoneSettings.MaxZombies) *
                        spawnMultiplier)
                    self:SpawnZombiesInZone(zoneName, zoneData, playerCoords, maxZombies)
                end

                ::skip::
            end

            ::continue::
        end
    end)
end

function ZombieManager:GetZoneCenter(zoneData)
    if zoneData.coords then
        return vector3(zoneData.coords.x, zoneData.coords.y, zoneData.coords.z)
    elseif zoneData.points and #zoneData.points > 0 then
        local sumX, sumY = 0, 0
        for _, point in ipairs(zoneData.points) do
            sumX = sumX + point.x
            sumY = sumY + point.y
        end
        return vector3(sumX / #zoneData.points, sumY / #zoneData.points, 0)
    end
    return vector3(0, 0, 0)
end

function ZombieManager:SpawnZombiesInZone(zoneName, zoneData, playerCoords, maxZombies)
    if not self.ActiveZombies[zoneName] then
        self.ActiveZombies[zoneName] = {}
    end

    local currentCount = #self.ActiveZombies[zoneName]

    if currentCount >= maxZombies then return end

    local spawnAmount = math.min(2, maxZombies - currentCount)

    for i = 1, spawnAmount do
        if self.TotalActiveZombies >= Config.Optimization.MaxActiveZombies then
            break
        end

        local spawnPos = self:GetRandomSpawnPosition(zoneData, playerCoords)
        if spawnPos then
            local zombieType = self:SelectZombieType(zoneData.dangerLevel or 'medium')
            local zombieEntity = self:CreateZombie(spawnPos, zombieType)

            if zombieEntity then
                table.insert(self.ActiveZombies[zoneName], {
                    entity = zombieEntity,
                    type = zombieType,
                    zone = zoneName,
                    spawned = GetGameTimer(),
                    target = nil,
                    lastAttack = 0,
                    isDead = false,
                    hasAggro = false
                })

                self.TotalActiveZombies = self.TotalActiveZombies + 1

                Wait(Config.DefaultZoneSettings.SpawnInterval / 5) -- Stagger spawns
            end
        end
    end
end

function ZombieManager:GetRandomSpawnPosition(zoneData, playerCoords)
    local maxAttempts = 10
    local center = self:GetZoneCenter(zoneData)
    local radius = zoneData.radius or Config.DefaultZoneSettings.SpawnRadius

    for i = 1, maxAttempts do
        local angle = math.random() * 2 * math.pi
        local r = radius * math.sqrt(math.random())

        local x = center.x + r * math.cos(angle)
        local y = center.y + r * math.sin(angle)

        local found, z = GetGroundZFor_3dCoord(x, y, center.z + 50.0, false)

        if found then
            local spawnPos = vector3(x, y, z)
            local distanceToPlayer = #(spawnPos - playerCoords)

            if distanceToPlayer >= Config.DefaultZoneSettings.MinDistanceFromPlayers then
                return spawnPos
            end
        end
    end

    return nil
end

-- ====================================
-- ZOMBIE CREATION (Improved from old script)
-- ====================================

function ZombieManager:CreateZombie(coords, zombieType)
    local typeData = Config.ZombieTypes[zombieType]
    if not typeData then return nil end

    -- Select random model from type
    local randomModel = typeData.Models[math.random(#typeData.Models)]
    local modelHash = GetHashKey(randomModel)

    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end

    if not HasModelLoaded(modelHash) then
        if Config.Debug then
            print(('[D4RK ZOMBIES] Model %s failed to load'):format(randomModel))
        end
        return nil
    end

    local zombie = CreatePed(4, modelHash, coords.x, coords.y, coords.z, math.random(0, 360), false, false)

    if not DoesEntityExist(zombie) then
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end

    -- Zombie Setup (From your old script)
    SetPedAsEnemy(zombie, true)
    SetCanAttackFriendly(zombie, false, true)
    SetPedRelationshipGroupHash(zombie, `ZOMBIE`)

    -- Prevent fleeing
    SetPedFleeAttributes(zombie, 0, false)
    SetBlockingOfNonTemporaryEvents(zombie, true)

    -- Combat attributes
    SetPedCombatAttributes(zombie, 46, true)
    SetPedCombatAttributes(zombie, 5, true)
    SetPedCombatAttributes(zombie, 0, true)
    SetPedCombatAttributes(zombie, 1, true)
    SetPedCombatAttributes(zombie, 3, true)

    SetPedCombatMovement(zombie, 2)
    SetPedCombatRange(zombie, 0)
    SetPedCombatAbility(zombie, 100)

    -- Ragdoll
    SetPedCanRagdoll(zombie, true)
    SetPedCanRagdollFromPlayerImpact(zombie, true)

    -- Entity flags
    SetEntityAsMissionEntity(zombie, true, true)
    SetEntityInvincible(zombie, false)

    -- Health
    SetEntityHealth(zombie, typeData.Health)
    SetPedArmour(zombie, 0)
    SetEntityMaxHealth(zombie, typeData.Health)

    -- Vision & Hearing
    local visualRange = self:IsNightTime() and Config.ZombieAggroSettings.visualRangeNight or
        Config.ZombieAggroSettings.visualRange
    SetPedSeeingRange(zombie, visualRange)
    SetPedHearingRange(zombie, Config.ZombieAggroSettings.shootNoiseRange)
    SetPedVisualFieldMinAngle(zombie, -90.0)
    SetPedVisualFieldMaxAngle(zombie, 90.0)
    SetPedVisualFieldMinElevationAngle(zombie, -45.0)
    SetPedVisualFieldMaxElevationAngle(zombie, 45.0)
    SetPedVisualFieldPeripheralRange(zombie, 180.0)

    -- Speed
    if typeData.Speed then
        SetPedMoveRateOverride(zombie, typeData.Speed)
    end

    -- Movement Animation
    if typeData.MovementClipSet then
        local clipset

        -- Support für mehrere Clipsets (zufällige Auswahl)
        if type(typeData.MovementClipSet) == 'table' then
            clipset = typeData.MovementClipSet[math.random(#typeData.MovementClipSet)]
        else
            clipset = typeData.MovementClipSet
        end

        RequestAnimSet(clipset)
        local timeout = 0
        while not HasAnimSetLoaded(clipset) and timeout < 3000 do
            Wait(100)
            timeout = timeout + 100
        end

        if HasAnimSetLoaded(clipset) then
            SetPedMovementClipset(zombie, clipset, 1.0)
        end
    end

    SetPedKeepTask(zombie, true)
    SetModelAsNoLongerNeeded(modelHash)

    if Config.Debug then
        print(typeData.Color .. "✅ Zombie: " .. typeData.Name .. " | HP: " .. typeData.Health .. "^7")
    end

    return zombie
end

-- Continue in next file...

-- ====================================
-- AI THREAD WITH AGGRO SYSTEM
-- ====================================

function ZombieManager:StartAIThread()
    CreateThread(function()
        while true do
            Wait(Config.UpdateInterval)

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local currentTime = GetGameTimer()

            for zoneName, zombies in pairs(self.ActiveZombies) do
                for i = #zombies, 1, -1 do
                    local zombie = zombies[i]

                    if not zombie or not DoesEntityExist(zombie.entity) or IsEntityDead(zombie.entity) then
                        self:HandleZombieDeath(zoneName, i, zombie)
                    else
                        self:UpdateZombieAI(zombie, playerPed, playerCoords, currentTime)
                    end
                end
            end
        end
    end)
end

function ZombieManager:UpdateZombieAI(zombie, playerPed, playerCoords, currentTime)
    local zombieCoords = GetEntityCoords(zombie.entity)
    local distance = #(playerCoords - zombieCoords)

    -- Despawn if too far
    if distance > Config.DespawnDistance then
        DeleteEntity(zombie.entity)
        self.TotalActiveZombies = math.max(0, self.TotalActiveZombies - 1)
        return
    end

    -- Aggro logic (From your old script)
    local isAggro = false

    -- Close range = always aggro
    if distance <= Config.ZombieAggroSettings.closeRange then
        isAggro = true
    end

    -- Vision check
    if Config.ZombieAggroSettings.requireLineOfSight then
        if HasEntityClearLosToEntity(zombie.entity, playerPed, 17) then
            local visualRange = self:IsNightTime() and Config.ZombieAggroSettings.visualRangeNight or
                Config.ZombieAggroSettings.visualRange
            if distance <= visualRange then
                isAggro = true
            end
        end
    end

    -- Shooting noise check
    if IsPedShooting(playerPed) and distance <= Config.ZombieAggroSettings.shootNoiseRange then
        if math.random(100) <= Config.ZombieAggroSettings.shootNoiseChance then
            isAggro = true
        end
    end

    -- Noise system check
    if NoiseSystem and NoiseSystem:IsPlayerMakingNoise(playerCoords, zombieCoords) then
        isAggro = true
    end

    -- Lose aggro if too far
    if zombie.hasAggro and distance > Config.ZombieAggroSettings.loseAggroDistance then
        if math.random(100) <= Config.ZombieAggroSettings.loseAggroChance then
            zombie.hasAggro = false
            ClearPedTasks(zombie.entity)
        end
    end

    if isAggro then
        zombie.hasAggro = true
        self:AttackPlayer(zombie, playerPed, playerCoords, currentTime)
    else
        -- Idle behavior - Wander around
        if not IsPedInCombat(zombie.entity, playerPed) then
            -- Random sound
            if math.random() < 0.02 then
                self:PlayIdleSound(zombie)
            end

            -- Wander behavior (if enabled)
            if Config.ZombieBehavior.WanderEnabled then
                local wanderInterval = math.random(Config.ZombieBehavior.WanderInterval.min,
                    Config.ZombieBehavior.WanderInterval.max)
                if not zombie.lastWander or (currentTime - zombie.lastWander) > wanderInterval then
                    self:MakeZombieWander(zombie, zombieCoords)
                    zombie.lastWander = currentTime
                end
            end
        end
    end
end

function ZombieManager:AttackPlayer(zombie, playerPed, playerCoords, currentTime)
    local typeData = Config.ZombieTypes[zombie.type]

    TaskGoToEntity(zombie.entity, playerPed, -1, typeData.AttackRange, typeData.Speed, 1073741824, 0)

    local zombieCoords = GetEntityCoords(zombie.entity)
    local distance = #(playerCoords - zombieCoords)

    if distance <= typeData.AttackRange then
        if currentTime - zombie.lastAttack >= typeData.AttackCooldown then
            TaskCombatPed(zombie.entity, playerPed, 0, 16)
            self:PlayAttackSound(zombie)

            if Config.Combat.ZombieMeleeDamage then
                ApplyDamageToPed(playerPed, typeData.Damage, false)
            end

            zombie.lastAttack = currentTime
        end
    end
end

function ZombieManager:PlayIdleSound(zombie)
    local typeData = Config.ZombieTypes[zombie.type]
    if typeData and typeData.Sounds and typeData.Sounds.Idle then
        PlayPain(zombie.entity, typeData.Sounds.Idle[1], 1.0, 0)
    end
end

function ZombieManager:PlayAttackSound(zombie)
    local typeData = Config.ZombieTypes[zombie.type]
    if typeData and typeData.Sounds and typeData.Sounds.Attack then
        PlayPain(zombie.entity, typeData.Sounds.Attack[1], 1.0, 0)
    end
end

-- ====================================
-- DEATH & CLEANUP
-- ====================================

function ZombieManager:HandleZombieDeath(zoneName, index, zombie)
    if not zombie then return end

    if not zombie.isDead then
        zombie.isDead = true

        local typeData = Config.ZombieTypes[zombie.type]

        -- Exploder death explosion
        if typeData and typeData.ExplodeOnDeath then
            local coords = GetEntityCoords(zombie.entity)
            AddExplosion(
                coords.x, coords.y, coords.z,
                1, -- Explosion type
                typeData.ExplosionDamage or 50,
                true, false, true
            )
        end

        self:SetupLootable(zombie)
        TriggerServerEvent('d4rk_zombies:server:ZombieKilled', zombie.type)
    end

    SetTimeout(Config.DefaultZoneSettings.RespawnTime, function()
        if zombie.entity and DoesEntityExist(zombie.entity) then
            DeleteEntity(zombie.entity)
        end

        if self.ActiveZombies[zoneName] and self.ActiveZombies[zoneName][index] then
            table.remove(self.ActiveZombies[zoneName], index)
            self.TotalActiveZombies = math.max(0, self.TotalActiveZombies - 1)
        end
    end)
end

function ZombieManager:SetupLootable(zombie)
    if not zombie or not zombie.entity then return end

    local entity = zombie.entity
    local typeData = Config.ZombieTypes[zombie.type]

    Entity(entity).state.looted = false
    Entity(entity).state.zombieType = zombie.type

    exports.ox_target:addLocalEntity(entity, {
        {
            name = 'zombie_loot',
            icon = Config.Interaction.LootIcon,
            label = Config.Interaction.LootLabel,
            distance = Config.Interaction.LootDistance,
            canInteract = function(entity)
                return not Entity(entity).state.looted
            end,
            onSelect = function(data)
                TriggerEvent('d4rk_zombies:client:LootZombie', data.entity)
            end
        }
    })
end

function ZombieManager:StartCleanupThread()
    CreateThread(function()
        while true do
            Wait(30000)

            for zoneName, zombies in pairs(self.ActiveZombies) do
                for i = #zombies, 1, -1 do
                    local zombie = zombies[i]

                    if zombie and zombie.isDead and (GetGameTimer() - zombie.spawned) > 120000 then
                        if DoesEntityExist(zombie.entity) then
                            DeleteEntity(zombie.entity)
                        end
                        table.remove(zombies, i)
                        self.TotalActiveZombies = math.max(0, self.TotalActiveZombies - 1)
                    end
                end
            end
        end
    end)
end

-- ====================================
-- EVENTS
-- ====================================

RegisterNetEvent('d4rk_zombies:client:ReloadZones', function()
    ZombieManager:LoadZones()
end)

RegisterNetEvent('zombie:client:zonesUpdated', function(zones)
    ZombieManager.ZoneCache = zones

    -- Recreate zone objects
    for zoneName, zoneData in pairs(zones) do
        ZombieManager:CreateZoneObject(zoneName, zoneData)
    end

    if Config.Debug then
        print('^2[D4RK ZOMBIES]^0 Zonen aktualisiert: ' .. ZombieManager:CountZones())
    end
end)

-- ====================================
-- WANDER BEHAVIOR
-- ====================================

function ZombieManager:MakeZombieWander(zombie, currentPos)
    if not DoesEntityExist(zombie.entity) then return end

    -- Generate random wander point within configured radius
    local angle = math.random() * 2 * math.pi
    local distance = math.random(Config.ZombieBehavior.WanderRadius.min, Config.ZombieBehavior.WanderRadius.max)

    local x = currentPos.x + (math.cos(angle) * distance)
    local y = currentPos.y + (math.sin(angle) * distance)

    local found, z = GetGroundZFor_3dCoord(x, y, currentPos.z + 10.0, false)

    if found then
        local targetPos = vector3(x, y, z)

        -- Make zombie walk to random point
        TaskGoToCoordAnyMeans(zombie.entity, targetPos.x, targetPos.y, targetPos.z, Config.ZombieBehavior.WanderSpeed, 0,
            false, 786603, 0.0)

        if Config.Debug then
            -- Draw debug line to show wander target
            CreateThread(function()
                local endTime = GetGameTimer() + 3000
                while GetGameTimer() < endTime do
                    DrawLine(currentPos.x, currentPos.y, currentPos.z + 1.0, targetPos.x, targetPos.y, targetPos.z + 1.0,
                        0, 255, 0, 100)
                    Wait(0)
                end
            end)
        end
    end
end
