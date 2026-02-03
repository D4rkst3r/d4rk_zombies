-- ====================================
-- HORDE EVENT SYSTEM
-- ====================================
local lib = exports.d4rk_lib
local d4rk = exports.d4rk_lib

HordeSystem = {}
HordeSystem.ActiveHordes = {}
HordeSystem.PlayerCampingData = {}
HordeSystem.EventActive = false
HordeSystem.NextEventTime = 0

function HordeSystem:Init()
    self:StartCampingDetection()
    self:StartRandomEvents()

    if Config.Debug then
        print("^2[D4RK ZOMBIES]^0 Horde System initialized")
    end
end

-- ====================================
-- CAMPING DETECTION (Zu lange an einem Ort)
-- ====================================

function HordeSystem:StartCampingDetection()
    CreateThread(function()
        while true do
            Wait(Config.HordeSystem.CampingCheckInterval)

            if not Config.HordeSystem.CampingPunishment.Enabled then
                goto continue
            end

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local playerId = PlayerId()

            -- Initialisiere Camping-Daten
            if not self.PlayerCampingData[playerId] then
                self.PlayerCampingData[playerId] = {
                    lastPos = playerCoords,
                    timeAtPosition = 0,
                    warningShown = false
                }
            end

            local campData = self.PlayerCampingData[playerId]
            local distance = #(playerCoords - campData.lastPos)

            -- Spieler hat sich bewegt?
            if distance > Config.HordeSystem.CampingPunishment.MovementThreshold then
                -- Reset
                campData.lastPos = playerCoords
                campData.timeAtPosition = 0
                campData.warningShown = false
            else
                -- Spieler campt
                campData.timeAtPosition = campData.timeAtPosition + (Config.HordeSystem.CampingCheckInterval / 1000)

                -- Warnung bei 75% der Zeit
                if not campData.warningShown and campData.timeAtPosition >= (Config.HordeSystem.CampingPunishment.TimeThreshold * 0.75) then
                    lib.notify({
                        title = '⚠️ Warnung',
                        description = 'Du bleibst zu lange an einem Ort! Zombies werden angelockt...',
                        type = 'warning',
                        duration = 5000
                    })
                    campData.warningShown = true
                end

                -- Horde spawnen
                if campData.timeAtPosition >= Config.HordeSystem.CampingPunishment.TimeThreshold then
                    self:SpawnCampingHorde(playerCoords, playerId)

                    -- Reset nach Spawn
                    campData.timeAtPosition = 0
                    campData.warningShown = false
                    campData.lastPos = playerCoords
                end
            end

            ::continue::
        end
    end)
end

function HordeSystem:SpawnCampingHorde(playerCoords, playerId)
    local hordeSize = math.random(
        Config.HordeSystem.CampingPunishment.HordeSize.min,
        Config.HordeSystem.CampingPunishment.HordeSize.max
    )

    lib.notify({
        title = '🧟 HORDE!',
        description = ('Eine Horde von %s Zombies wurde angelockt!'):format(hordeSize),
        type = 'error',
        duration = 5000
    })

    -- Spawn Horde
    self:SpawnHorde({
        center = playerCoords,
        size = hordeSize,
        radius = Config.HordeSystem.CampingPunishment.SpawnRadius,
        targetPlayer = playerId,
        type = 'camping',
        aggressive = true
    })

    -- Discord Log
    if Config.Discord.Enabled then
        TriggerServerEvent('d4rk_zombies:server:LogCampingHorde', hordeSize)
    end
end

-- ====================================
-- RANDOM HORDE EVENTS
-- ====================================

function HordeSystem:StartRandomEvents()
    CreateThread(function()
        -- Berechne erste Event-Zeit
        self.NextEventTime = GetGameTimer() + math.random(
            Config.HordeSystem.RandomEvents.IntervalMin,
            Config.HordeSystem.RandomEvents.IntervalMax
        )

        while true do
            Wait(30000) -- Check alle 30 Sekunden

            if not Config.HordeSystem.RandomEvents.Enabled then
                goto continue
            end

            if GetGameTimer() >= self.NextEventTime and not self.EventActive then
                self:TriggerRandomEvent()

                -- Nächstes Event planen
                self.NextEventTime = GetGameTimer() + math.random(
                    Config.HordeSystem.RandomEvents.IntervalMin,
                    Config.HordeSystem.RandomEvents.IntervalMax
                )
            end

            ::continue::
        end
    end)
end

function HordeSystem:TriggerRandomEvent()
    local eventType = self:SelectRandomEventType()

    if eventType == 'wandering_horde' then
        self:SpawnWanderingHorde()
    elseif eventType == 'blood_moon' then
        self:StartBloodMoon()
    elseif eventType == 'zone_siege' then
        self:StartZoneSiege()
    end
end

function HordeSystem:SelectRandomEventType()
    local types = Config.HordeSystem.RandomEvents.Types
    local total = 0

    for _, event in ipairs(types) do
        total = total + event.chance
    end

    local roll = math.random() * total
    local current = 0

    for _, event in ipairs(types) do
        current = current + event.chance
        if roll <= current then
            return event.type
        end
    end

    return 'wandering_horde'
end

-- ====================================
-- WANDERING HORDE (Horde läuft durch Map)
-- ====================================

function HordeSystem:SpawnWanderingHorde()
    -- Zufällige Position auf der Map
    local randomPos = self:GetRandomMapPosition()
    local hordeSize = math.random(15, 30)

    -- Globale Benachrichtigung
    TriggerEvent('chat:addMessage', {
        color = { 255, 0, 0 },
        multiline = true,
        args = { "[ZOMBIE ALERT]", ("Eine wandernde Horde (%s Zombies) wurde gesichtet!"):format(hordeSize) }
    })

    lib.notify({
        title = '🌊 Wandernde Horde',
        description = 'Eine Zombie-Horde wandert durch die Gegend!',
        type = 'error',
        duration = 10000
    })

    self.EventActive = true

    -- Spawn Horde
    local horde = self:SpawnHorde({
        center = randomPos,
        size = hordeSize,
        radius = 50.0,
        type = 'wandering',
        aggressive = false
    })

    -- Horde wandert für 5 Minuten
    self:MakeHordeWander(horde, 300000)

    SetTimeout(300000, function()
        self.EventActive = false
    end)
end

-- ====================================
-- BLOOD MOON (Nacht mit extra vielen Zombies)
-- ====================================

function HordeSystem:StartBloodMoon()
    if not self:IsNightTime() then
        return -- Nur nachts möglich
    end

    self.EventActive = true

    -- Benachrichtigung
    TriggerEvent('chat:addMessage', {
        color = { 139, 0, 0 },
        multiline = true,
        args = { "[BLOOD MOON]", "Der Blutmond erhebt sich... Die Toten erwachen!" }
    })

    lib.notify({
        title = '🌙 BLUTMOND',
        description = 'Zombie-Spawns sind verdoppelt!\nDauer: 10 Minuten',
        type = 'error',
        duration = 10000
    })

    -- Screen-Effect (Optional)
    SetTimecycleModifier('BikerFilter')

    -- Event an Server senden für globalen Spawn-Boost
    TriggerServerEvent('d4rk_zombies:server:BloodMoonActive', true)

    -- 10 Minuten Dauer
    SetTimeout(600000, function()
        lib.notify({
            title = '🌙 Blutmond vorbei',
            description = 'Die Nacht wird wieder ruhiger...',
            type = 'success'
        })

        ClearTimecycleModifier()
        TriggerServerEvent('d4rk_zombies:server:BloodMoonActive', false)
        self.EventActive = false
    end)
end

-- ====================================
-- ZONE SIEGE (Eine Zone wird überflutet)
-- ====================================

function HordeSystem:StartZoneSiege()
    -- Wähle zufällige Zone
    local zones = ZombieManager.ZoneCache
    local zoneList = {}

    for name, data in pairs(zones) do
        if data.enabled then
            table.insert(zoneList, { name = name, data = data })
        end
    end

    if #zoneList == 0 then return end

    local selectedZone = zoneList[math.random(#zoneList)]

    lib.notify({
        title = '🏚️ Zone Belagerung',
        description = ('Zone "%s" wird von Zombies überrannt!'):format(selectedZone.name),
        type = 'error',
        duration = 10000
    })

    self.EventActive = true

    -- Spawn massive Horde in Zone
    local center = ZombieManager:GetZoneCenter(selectedZone.data)
    self:SpawnHorde({
        center = center,
        size = 40,
        radius = selectedZone.data.radius or 50,
        type = 'siege',
        aggressive = true
    })

    SetTimeout(180000, function() -- 3 Minuten
        self.EventActive = false
    end)
end

-- ====================================
-- HORDE SPAWNING (Universal)
-- ====================================

function HordeSystem:SpawnHorde(config)
    local horde = {
        id = #self.ActiveHordes + 1,
        zombies = {},
        center = config.center,
        type = config.type,
        spawned = GetGameTimer()
    }

    for i = 1, config.size do
        Wait(100) -- Stagger spawns

        local spawnPos = self:GetHordeSpawnPosition(config.center, config.radius)

        if spawnPos then
            -- Wähle Zombie-Typ (mehr Runner/Exploder bei Horden)
            local zombieType = self:SelectHordeZombieType()
            local zombie = ZombieManager:CreateZombie(spawnPos, zombieType)

            if zombie then
                table.insert(horde.zombies, {
                    entity = zombie,
                    type = zombieType
                })

                -- Wenn Horde aggressiv ist, sofort Spieler angreifen
                if config.aggressive and config.targetPlayer then
                    local targetPed = GetPlayerPed(config.targetPlayer)
                    TaskCombatPed(zombie, targetPed, 0, 16)
                end
            end
        end
    end

    table.insert(self.ActiveHordes, horde)

    if Config.Debug then
        print(('^2[HORDE]^0 %s Horde spawned: %s Zombies'):format(config.type, config.size))
    end

    return horde
end

function HordeSystem:GetHordeSpawnPosition(center, radius)
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius

    local x = center.x + (math.cos(angle) * distance)
    local y = center.y + (math.sin(angle) * distance)

    local found, z = GetGroundZFor_3dCoord(x, y, center.z + 20.0, false)

    if found then
        return vector3(x, y, z)
    end

    return nil
end

function HordeSystem:SelectHordeZombieType()
    -- Horden haben mehr Runner und Exploder
    local roll = math.random(100)

    if roll <= 40 then
        return 'runner'
    elseif roll <= 60 then
        return 'crawler'
    elseif roll <= 80 then
        return 'exploder'
    else
        return 'tank'
    end
end

-- ====================================
-- HORDE WANDER BEHAVIOR
-- ====================================

function HordeSystem:MakeHordeWander(horde, duration)
    local endTime = GetGameTimer() + duration

    CreateThread(function()
        while GetGameTimer() < endTime do
            Wait(10000) -- Neues Ziel alle 10 Sekunden

            -- Neues Wander-Ziel
            local newCenter = self:GetRandomNearbyPosition(horde.center, 100)
            horde.center = newCenter

            -- Alle Zombies zum neuen Ziel schicken
            for _, zombie in ipairs(horde.zombies) do
                if DoesEntityExist(zombie.entity) and not IsEntityDead(zombie.entity) then
                    TaskGoToCoordAnyMeans(zombie.entity, newCenter.x, newCenter.y, newCenter.z, 1.0, 0, false, 786603,
                        0.0)
                end
            end
        end

        -- Cleanup
        for i, activeHorde in ipairs(self.ActiveHordes) do
            if activeHorde.id == horde.id then
                table.remove(self.ActiveHordes, i)
                break
            end
        end
    end)
end

-- ====================================
-- HELPER FUNCTIONS
-- ====================================

function HordeSystem:IsNightTime()
    local hour = GetClockHours()
    return hour >= Config.NightStartHour or hour < Config.NightEndHour
end

function HordeSystem:GetRandomMapPosition()
    -- San Andreas Koordinaten-Bereiche
    local x = math.random(-3000, 4000)
    local y = math.random(-3000, 8000)
    local found, z = GetGroundZFor_3dCoord(x, y, 1000.0, false)

    return vector3(x, y, z or 0)
end

function HordeSystem:GetRandomNearbyPosition(center, radius)
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius

    local x = center.x + (math.cos(angle) * distance)
    local y = center.y + (math.sin(angle) * distance)
    local found, z = GetGroundZFor_3dCoord(x, y, center.z + 20.0, false)

    return vector3(x, y, z or center.z)
end

-- ====================================
-- ADMIN COMMANDS
-- ====================================

RegisterCommand('spawnhorde', function(source, args)
    -- Wir fragen den Server, ob wir Admin sind (via Callback)
    -- Ich nehme an, 'd4rk_zombies:server:CheckPermission' ist ein registrierter Callback
    lib.callback('d4rk_zombies:server:CheckPermission', false, function(hasPermission)
        if not hasPermission then
            d4rk:Notify('Keine Berechtigung!', 'error')
            return
        end

        local size = tonumber(args[1]) or 20
        local playerCoords = GetEntityCoords(PlayerPedId())

        -- Horde spawnen
        HordeSystem:SpawnHorde({
            center = playerCoords,
            size = size,
            radius = 30.0,
            type = 'admin',
            aggressive = true,
            targetPlayer = PlayerId()
        })

        d4rk:Notify('Horde gespawnt: ' .. size .. ' Zombies', 'success')
    end)
end)

RegisterCommand('bloodmoon', function()
    lib.callback('d4rk_zombies:server:CheckPermission', false, function(hasPermission)
        if hasPermission then
            HordeSystem:StartBloodMoon()
            d4rk:Notify('Blutmond gestartet!', 'error') -- 'error' ist oft rot, passt zu Blutmond
        else
            d4rk:Notify('Keine Berechtigung!', 'error')
        end
    end)
end)
