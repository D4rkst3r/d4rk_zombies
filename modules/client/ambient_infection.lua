-- ====================================
-- AMBIENT INFECTION SYSTEM (FIXED)
-- ====================================

AmbientInfection = {}
AmbientInfection.InfectedPeds = {}
AmbientInfection.Enabled = Config.AmbientInfection.Enabled

function AmbientInfection:Init()
    if not self.Enabled then return end

    CreateThread(function()
        while true do
            Wait(Config.AmbientInfection.CheckInterval or 5000)

            if self.Enabled then
                self:ScanAndInfect()
            end
        end
    end)
end

function AmbientInfection:ScanAndInfect()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local nearbyPeds = GetNearbyPeds(playerCoords, Config.AmbientInfection.ConversionRadius or 50.0)

    for _, ped in ipairs(nearbyPeds) do
        if self:CanInfect(ped) then
            if math.random() <= (Config.AmbientInfection.ConversionChance or 0.1) then
                self:InfectPed(ped)
            end
        end
    end
end

function AmbientInfection:CanInfect(ped)
    if not DoesEntityExist(ped) or self.InfectedPeds[ped] then return false end
    if IsPedAPlayer(ped) or IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then return false end

    -- Blacklisted Model Check
    local model = GetEntityModel(ped)
    if Config.AmbientInfection.BlacklistedModels then
        for _, blacklisted in ipairs(Config.AmbientInfection.BlacklistedModels) do
            if model == GetHashKey(blacklisted) then return false end
        end
    end

    return true
end

function AmbientInfection:InfectPed(ped)
    -- 1. Sicherstellen, dass wir einen existierenden Typ aus der Config nehmen!
    -- Wir holen uns alle Keys aus deiner Config.ZombieTypes (z.B. "runner", "crawler", etc.)
    local availableTypes = {}
    for typeName, _ in pairs(Config.ZombieTypes) do
        table.insert(availableTypes, typeName)
    end

    -- Falls deine Config leer sein sollte (Sicherheitshaken)
    if #availableTypes == 0 then return end

    local zombieType = availableTypes[math.random(#availableTypes)]
    local typeData = Config.ZombieTypes[zombieType]

    self.InfectedPeds[ped] = true

    -- 2. Zombie-Eigenschaften setzen
    SetEntityHealth(ped, typeData.Health or 150)
    SetPedMaxHealth(ped, typeData.Health or 150)
    SetPedCombatAbility(ped, 100)
    SetPedCombatMovement(ped, 2)
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- Beziehung zu Zombies setzen, damit sie sich nicht gegenseitig fressen
    SetPedRelationshipGroupHash(ped, `ZOMBIE`)

    -- 3. Zombie-Animation (Clipset Support für Strings und Tabellen)
    local clipset = typeData.MovementClipSet
    if type(clipset) == 'table' then
        clipset = clipset[math.random(#clipset)]
    end

    if type(clipset) == 'string' then
        RequestAnimSet(clipset)
        local timeout = 0
        while not HasAnimSetLoaded(clipset) and timeout < 2000 do
            Wait(10)
            timeout = timeout + 10
        end
        if HasAnimSetLoaded(clipset) then
            SetPedMovementClipset(ped, clipset, 1.0)
        end
    end

    -- 4. Ziel: Den Spieler jagen
    TaskCombatPed(ped, PlayerPedId(), 0, 16)

    -- 5. Loot-Logik nach dem Tod
    CreateThread(function()
        while DoesEntityExist(ped) and not IsEntityDead(ped) do
            Wait(2000)
        end

        if DoesEntityExist(ped) then
            -- Fake-Objekt für den ZombieManager erstellen
            local fakeZombie = {
                entity = ped,
                type = zombieType,
                zone = 'ambient',
                isDead = true
            }
            if ZombieManager and ZombieManager.SetupLootable then
                ZombieManager:SetupLootable(fakeZombie)
            end
        end
    end)
end

function AmbientInfection:Toggle()
    self.Enabled = not self.Enabled
    return self.Enabled
end

-- Helper Function (KORRIGIERT)
function GetNearbyPeds(coords, radius)
    local peds = {}
    local handle, ped = FindFirstPed()
    local success

    if handle == -1 then return peds end -- Sicherheitshalber abbrechen, wenn kein Ped gefunden wird

    repeat
        if DoesEntityExist(ped) and ped ~= PlayerPedId() then
            local pos = GetEntityCoords(ped)
            if #(coords - pos) <= radius then
                table.insert(peds, ped)
            end
        end
        success, ped = FindNextPed(handle)
    until not success -- Das 'repeat' oben war zu viel, hier gehört nur 'until' hin

    EndFindPed(handle)
    return peds
end

-- Event Handler
RegisterNetEvent('d4rk_zombies:client:ToggleInfection', function(enabled)
    AmbientInfection.Enabled = enabled
end)
