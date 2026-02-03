-- ====================================
-- AMBIENT INFECTION SYSTEM
-- ====================================

AmbientInfection = {}
AmbientInfection.InfectedPeds = {}
AmbientInfection.Enabled = Config.AmbientInfection.Enabled

function AmbientInfection:Init()
    if not self.Enabled then return end
    
    CreateThread(function()
        while true do
            Wait(Config.AmbientInfection.CheckInterval)
            
            if self.Enabled then
                self:ScanAndInfect()
            end
        end
    end)
end

function AmbientInfection:ScanAndInfect()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    local nearbyPeds = GetNearbyPeds(playerCoords, Config.AmbientInfection.ConversionRadius)
    
    for _, ped in ipairs(nearbyPeds) do
        if self:CanInfect(ped) then
            if math.random() <= Config.AmbientInfection.ConversionChance then
                self:InfectPed(ped)
            end
        end
    end
end

function AmbientInfection:CanInfect(ped)
    -- Bereits infiziert?
    if self.InfectedPeds[ped] then return false end
    
    -- Ist ein Spieler?
    if IsPedAPlayer(ped) then return false end
    
    -- Ist tot?
    if IsEntityDead(ped) then return false end
    
    -- Ist in einem Fahrzeug?
    if IsPedInAnyVehicle(ped, false) then return false end
    
    -- Blacklisted Model?
    local model = GetEntityModel(ped)
    for _, blacklisted in ipairs(Config.AmbientInfection.BlacklistedModels) do
        if model == GetHashKey(blacklisted) then
            return false
        end
    end
    
    return true
end

function AmbientInfection:InfectPed(ped)
    self.InfectedPeds[ped] = true
    
    -- Zombie-Eigenschaften
    SetEntityHealth(ped, 150)
    SetPedMaxHealth(ped, 150)
    SetPedCombatAbility(ped, 100)
    SetPedCombatMovement(ped, 2)
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- Zombie-Animation
    local zombieType = math.random() > 0.5 and 'shambler' or 'runner'
    local clipset = Config.ZombieTypes[zombieType].MovementClipSet
    
    RequestAnimSet(clipset)
    while not HasAnimSetLoaded(clipset) do
        Wait(10)
    end
    SetPedMovementClipset(ped, clipset, 1.0)
    
    -- Ziel: Spieler
    TaskGoToEntity(ped, PlayerPedId(), -1, 2.0, 1.5, 1073741824, 0)
    
    -- Setup Loot wenn getötet
    CreateThread(function()
        while DoesEntityExist(ped) and not IsEntityDead(ped) do
            Wait(1000)
        end
        
        if DoesEntityExist(ped) then
            -- Lootbar machen
            local fakeZombie = {
                entity = ped,
                type = zombieType,
                zone = 'ambient',
                isDead = true
            }
            ZombieManager:SetupLootable(fakeZombie)
        end
    end)
end

function AmbientInfection:Toggle()
    self.Enabled = not self.Enabled
    return self.Enabled
end

-- Helper Function
function GetNearbyPeds(coords, radius)
    local peds = {}
    local handle, ped = FindFirstPed()
    local success
    
    repeat
        local pos = GetEntityCoords(ped)
        local distance = #(coords - pos)
        
        if distance <= radius and ped ~= PlayerPedId() then
            table.insert(peds, ped)
        end
        
        success, ped = FindNextPed(handle)
    until not success
    
    EndFindPed(handle)
    return peds
end

-- Event Handler
RegisterNetEvent('d4rk_zombies:client:ToggleInfection', function(enabled)
    AmbientInfection.Enabled = enabled
end)
