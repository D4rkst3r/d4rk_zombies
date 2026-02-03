-- ====================================
-- ZOMBIE SPAWNING & AI SYSTEM (OPTIMIZED & FIXED)
-- ====================================

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
-- HELPER FUNCTIONS
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

        if typeName == 'runner' then
            chance = chance * modifier.runnerChance
        elseif typeName == 'tank' then
            chance = chance * modifier.tankChance
        elseif typeName == 'exploder' then
            chance = chance * modifier.exploderChance
        end

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
        if rand <= cumulative then return wt.type end
    end
    return 'runner'
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
    end)
end

function ZombieManager:CreateZoneObject(name, data)
    if data.type == 'circle' then
        self.ZoneObjects[name] = CircleZone:Create(vector3(data.coords.x, data.coords.y, data.coords.z),
            data.radius or 50.0, { name = name, debugPoly = Config.ShowZoneDebug, useZ = true })
    elseif data.type == 'poly' or data.type == 'polygon' then
        self.ZoneObjects[name] = PolyZone:Create(data.points,
            {
                name = name,
                minZ = data.minZ or (data.coords and data.coords.z - 10) or 0,
                maxZ = data.maxZ or
                    (data.coords and data.coords.z + 20) or 100,
                debugPoly = Config.ShowZoneDebug
            })
    end

    if data.coords then
        local blip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, data.radius or 50.0)
        SetBlipColour(blip, 1)
        SetBlipAlpha(blip, 80)
    end
end

-- ====================================
-- SPAWN SYSTEM
-- ====================================

function ZombieManager:StartSpawnThread()
    CreateThread(function()
        while true do
            Wait(Config.DefaultZoneSettings.SpawnInterval)
            if self.TotalActiveZombies < Config.Optimization.MaxActiveZombies then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local spawnMultiplier = self:GetSpawnMultiplier()

                for zoneName, zoneData in pairs(self.ZoneCache) do
                    if zoneData.enabled then
                        local zoneCenter = self:GetZoneCenter(zoneData)
                        if #(playerCoords - zoneCenter) <= Config.MaxRenderDistance then
                            local maxZombies = math.floor((zoneData.maxZombies or Config.DefaultZoneSettings.MaxZombies) *
                                spawnMultiplier)
                            self:SpawnZombiesInZone(zoneName, zoneData, playerCoords, maxZombies)
                        end
                    end
                end
            end
        end
    end)
end

function ZombieManager:GetZoneCenter(zoneData)
    if zoneData.coords then return vector3(zoneData.coords.x, zoneData.coords.y, zoneData.coords.z) end
    if zoneData.points and #zoneData.points > 0 then
        local x, y = 0, 0
        for _, p in ipairs(zoneData.points) do x, y = x + p.x, y + p.y end
        return vector3(x / #zoneData.points, y / #zoneData.points, 0)
    end
    return vector3(0, 0, 0)
end

function ZombieManager:SpawnZombiesInZone(zoneName, zoneData, playerCoords, maxZombies)
    if not self.ActiveZombies[zoneName] then self.ActiveZombies[zoneName] = {} end
    if #self.ActiveZombies[zoneName] >= maxZombies then return end

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
                lastAttack = 0,
                isDead = false,
                hasAggro = false
            })
            self.TotalActiveZombies = self.TotalActiveZombies + 1
        end
    end
end

function ZombieManager:GetRandomSpawnPosition(zoneData, playerCoords)
    local center = self:GetZoneCenter(zoneData)
    local radius = zoneData.radius or 50.0
    for i = 1, 10 do
        local angle = math.random() * 2 * math.pi
        local r = radius * math.sqrt(math.random())
        local x, y = center.x + r * math.cos(angle), center.y + r * math.sin(angle)
        local found, z = GetGroundZFor_3dCoord(x, y, center.z + 50.0, false)
        if found and #(vector3(x, y, z) - playerCoords) >= Config.DefaultZoneSettings.MinDistanceFromPlayers then
            return vector3(x, y, z)
        end
    end
    return nil
end

-- ====================================
-- ZOMBIE CREATION
-- ====================================

function ZombieManager:CreateZombie(coords, zombieType)
    local typeData = Config.ZombieTypes[zombieType]
    if not typeData then return nil end

    local model = GetHashKey(typeData.Models[math.random(#typeData.Models)])
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local zombie = CreatePed(4, model, coords.x, coords.y, coords.z, math.random(360), false, false)
    SetEntityAsMissionEntity(zombie, true, true)

    -- AI Wakeup Fix
    SetPedRelationshipGroupHash(zombie, `ZOMBIE`)
    SetPedFleeAttributes(zombie, 0, false)
    SetBlockingOfNonTemporaryEvents(zombie, true)
    SetPedCombatAttributes(zombie, 46, true)
    SetPedCombatAbility(zombie, 100)
    SetPedCombatMovement(zombie, 2)

    SetEntityHealth(zombie, typeData.Health)
    SetEntityMaxHealth(zombie, typeData.Health)
    if typeData.Speed then SetPedMoveRateOverride(zombie, typeData.Speed) end

    -- State Bags for better Sync
    Entity(zombie).state:set('isZombie', true, true)
    Entity(zombie).state:set('zombieType', zombieType, true)

    -- Clipset
    if typeData.MovementClipSet then
        local cs = type(typeData.MovementClipSet) == 'table' and
            typeData.MovementClipSet[math.random(#typeData.MovementClipSet)] or typeData.MovementClipSet
        RequestAnimSet(cs)
        while not HasAnimSetLoaded(cs) do Wait(10) end
        SetPedMovementClipset(zombie, cs, 1.0)
    end

    SetTimeout(200, function()
        if DoesEntityExist(zombie) then TaskWanderStandard(zombie, 10.0, 10) end
    end)

    SetModelAsNoLongerNeeded(model)
    return zombie
end

-- ====================================
-- AI CORE & UPDATE
-- ====================================

function ZombieManager:StartAIThread()
    CreateThread(function()
        while true do
            Wait(Config.UpdateInterval or 500)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local currentTime = GetGameTimer()

            for zoneName, zombies in pairs(self.ActiveZombies) do
                for i = #zombies, 1, -1 do
                    local z = zombies[i]
                    if not z or not DoesEntityExist(z.entity) or IsEntityDead(z.entity) then
                        self:HandleZombieDeath(zoneName, i, z)
                    else
                        -- Performance Throttle
                        local dist = #(playerCoords - GetEntityCoords(z.entity))
                        local skip = (dist > 50.0 and currentTime % 1000 < 500)
                        if not skip then self:UpdateZombieAI(z, playerPed, playerCoords, currentTime) end
                    end
                end
            end
        end
    end)
end

function ZombieManager:UpdateZombieAI(zombie, playerPed, playerCoords, currentTime)
    local zCoords = GetEntityCoords(zombie.entity)
    local dist = #(playerCoords - zCoords)

    if dist > Config.DespawnDistance then
        DeleteEntity(zombie.entity)
        self.TotalActiveZombies = math.max(0, self.TotalActiveZombies - 1)
        return
    end

    local isAggro = (dist <= Config.ZombieAggroSettings.closeRange) or
        (IsPedShooting(playerPed) and dist <= Config.ZombieAggroSettings.shootNoiseRange)

    if isAggro then
        zombie.hasAggro = true
        -- Stuck Fix: Force Combat if Idle
        if GetScriptTaskStatus(zombie.entity, 0x2e85a751) == 7 then
            ClearPedTasks(zombie.entity)
            TaskCombatPed(zombie.entity, playerPed, 0, 16)
        end
        self:AttackPlayer(zombie, playerPed, playerCoords, currentTime)
    else
        if zombie.hasAggro and dist > Config.ZombieAggroSettings.loseAggroDistance then
            zombie.hasAggro = false
            TaskWanderStandard(zombie.entity, 10.0, 10)
        end
    end
end

function ZombieManager:AttackPlayer(zombie, playerPed, playerCoords, currentTime)
    local typeData = Config.ZombieTypes[zombie.type]
    local dist = #(playerCoords - GetEntityCoords(zombie.entity))

    if dist <= typeData.AttackRange then
        if currentTime - zombie.lastAttack >= typeData.AttackCooldown then
            ClearPedTasksImmediately(zombie.entity)
            TaskCombatPed(zombie.entity, playerPed, 0, 16)

            if Config.Combat.ZombieMeleeDamage then
                ApplyDamageToPed(playerPed, typeData.Damage, false)
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
            end
            zombie.lastAttack = currentTime
        end
    else
        TaskGoToEntity(zombie.entity, playerPed, -1, 0.0, typeData.Speed or 1.0, 1073741824, 0)
    end
end

-- ====================================
-- DEATH & CLEANUP
-- ====================================

function ZombieManager:HandleZombieDeath(zoneName, index, zombie)
    if not zombie or zombie.isDead then return end
    zombie.isDead = true

    local typeData = Config.ZombieTypes[zombie.type]
    if typeData.ExplodeOnDeath then
        local c = GetEntityCoords(zombie.entity)
        AddExplosion(c.x, c.y, c.z, 1, 50, true, false, true)
    end

    TriggerServerEvent('d4rk_zombies:server:ZombieKilled', zombie.type)

    SetTimeout(Config.DefaultZoneSettings.RespawnTime or 5000, function()
        if DoesEntityExist(zombie.entity) then DeleteEntity(zombie.entity) end
        if self.ActiveZombies[zoneName] then table.remove(self.ActiveZombies[zoneName], index) end
        self.TotalActiveZombies = math.max(0, self.TotalActiveZombies - 1)
    end)
end

function ZombieManager:StartCleanupThread()
    CreateThread(function()
        while true do
            Wait(60000)
            -- Hier könnte man noch Peds löschen, die zu weit weg sind
        end
    end)
end

return ZombieManager
