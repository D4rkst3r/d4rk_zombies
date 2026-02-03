-- ====================================
-- CLIENT MAIN FILE (UPDATED)
-- ====================================

QBCore = exports['qb-core']:GetCoreObject()
PlayerData = {}

-- ====================================
-- INITIALIZATION
-- ====================================

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end

    PlayerData = QBCore.Functions.GetPlayerData()

    -- Zombie Relationship Group erstellen
    AddRelationshipGroup('ZOMBIE')
    SetRelationshipBetweenGroups(5, GetHashKey('ZOMBIE'), GetHashKey('PLAYER'))
    SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GetHashKey('ZOMBIE'))

    -- Initialize All Systems
    NoiseSystem:Init()
    ZombieManager:Init()
    AmbientInfection:Init()
    SoundSystem:Init()
    SoundSystem:StartRandomSoundThread()
    HordeSystem:Init()

    -- ✅ NEUE AI STARTEN
    ImprovedZombieAI:Init()

    if Config.Debug then
        print('[D4RK ZOMBIES] Client erfolgreich gestartet')
    end
end)

-- ====================================
-- PERFORMANCE OPTIMIZATION
-- ====================================

if Config.Optimization.DisableTraffic then
    CreateThread(function()
        while true do
            Wait(0)

            -- Deaktiviere Fahrzeug-Verkehr
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetPedDensityMultiplierThisFrame(Config.Optimization.DisableAmbientPeds and 0.0 or 1.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetParkedVehicleDensityMultiplierThisFrame(0.0)

            -- Deaktiviere Scenario Peds
            if Config.Optimization.DisableScenarioPeds then
                SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
            end

            -- Dispatch Services deaktivieren
            for i = 1, 15 do
                EnableDispatchService(i, false)
            end

            -- Polizei-Spawns verhindern
            SetMaxWantedLevel(0)
            SetPlayerWantedLevel(PlayerId(), 0, false)
            SetPlayerWantedLevelNow(PlayerId(), false)
        end
    end)
end

-- ====================================
-- PLAYER DATA UPDATES
-- ====================================

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

-- ====================================
-- KILL NOTIFICATIONS
-- ====================================

RegisterNetEvent('d4rk_zombies:client:KillNotification', function(totalKills)
    if Config.KillTracking.ShowKillNotification then
        exports.d4rk_lib:Notify(_('zombie_killed', totalKills), 'success')
    end
end)

-- ====================================
-- UTILITY FUNCTIONS
-- ====================================

function GetPlayerZombieKills()
    if not PlayerData.metadata then return 0 end
    return PlayerData.metadata[Config.KillTracking.MetaDataKey] or 0
end

-- ====================================
-- EXPORTS
-- ====================================

exports('GetZombieKills', GetPlayerZombieKills)
exports('IsInfectionEnabled', function() return AmbientInfection.Enabled end)
exports('GetActiveZombieCount', function() return ZombieManager.TotalActiveZombies end)
exports('GetImprovedAI', function() return ImprovedZombieAI end)
-- ====================================
