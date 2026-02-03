-- ====================================
-- SERVER MAIN FILE
-- ====================================

QBCore = exports['qb-core']:GetCoreObject()

-- ====================================
-- INITIALIZATION
-- ====================================

CreateThread(function()
    print('^2━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━^0')
    print('^2[D4RK ZOMBIES]^0 Initialisiere System...')
    
    -- Initialize Modules
    ZoneManager:Init()
    KillTracker:Init()
    
    print('^2[D4RK ZOMBIES]^0 System erfolgreich gestartet!')
    print('^2━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━^0')
end)

-- ====================================
-- PERMISSION CHECKS
-- ====================================

lib.callback.register('d4rk_zombies:server:CheckPermission', function(source)
    return exports.d4rk_lib:CheckPermission(source, Config.AdminGroups)
end)

-- ====================================
-- AMBIENT INFECTION TOGGLE
-- ====================================

local InfectionEnabled = Config.AmbientInfection.Enabled

RegisterNetEvent('d4rk_zombies:server:ToggleInfection', function()
    local src = source
    
    if not exports.d4rk_lib:CheckPermission(src, Config.AdminGroups) then
        return
    end
    
    InfectionEnabled = not InfectionEnabled
    
    TriggerClientEvent('d4rk_zombies:client:ToggleInfection', -1, InfectionEnabled)
    TriggerClientEvent('d4rk_zombies:client:InfectionToggled', src, InfectionEnabled)
end)

-- ====================================
-- TELEPORT SYSTEM
-- ====================================

RegisterNetEvent('d4rk_zombies:server:TeleportToPlayer', function(targetId)
    local src = source
    
    if not exports.d4rk_lib:CheckPermission(src, Config.AdminGroups) then
        return
    end
    
    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
    
    if targetCoords then
        TriggerClientEvent('d4rk_zombies:client:Teleport', src, targetCoords)
    end
end)

RegisterNetEvent('d4rk_zombies:client:Teleport', function(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
end)

-- ====================================
-- VERSION CHECK
-- ====================================

CreateThread(function()
    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    
    PerformHttpRequest('https://api.github.com/repos/YOUR_REPO/d4rk_zombies/releases/latest', function(err, response, headers)
        if err == 200 then
            local data = json.decode(response)
            if data and data.tag_name then
                local latestVersion = data.tag_name:gsub('v', '')
                
                if latestVersion ~= currentVersion then
                    print('^3[D4RK ZOMBIES] Neue Version verfügbar: v' .. latestVersion .. '^0')
                    print('^3[D4RK ZOMBIES] Aktuelle Version: v' .. currentVersion .. '^0')
                end
            end
        end
    end, 'GET')
end)

-- ====================================
-- EXPORTS
-- ====================================

exports('GetZombieKills', function(source)
    return KillTracker:GetKills(source)
end)

exports('AddZombieKill', function(source)
    return KillTracker:AddKill(source)
end)

exports('GetLeaderboard', function(limit)
    return KillTracker:GetLeaderboard(limit)
end)

exports('CreateZone', function(name, data)
    return ZoneManager:CreateZone(name, data)
end)

exports('DeleteZone', function(name)
    return ZoneManager:DeleteZone(name)
end)

exports('GetAllZones', function()
    return ZoneManager:GetAllZones()
end)

-- ====================================
-- HORDE EVENT HANDLING
-- ====================================

local BloodMoonActive = false

RegisterNetEvent('d4rk_zombies:server:BloodMoonActive', function(active)
    local src = source
    
    if not exports.d4rk_lib:CheckPermission(src, Config.AdminGroups) then
        return
    end
    
    BloodMoonActive = active
    
    -- Notify all clients
    TriggerClientEvent('d4rk_zombies:client:BloodMoonStatus', -1, active)
end)

RegisterNetEvent('d4rk_zombies:server:LogCampingHorde', function(hordeSize)
    local src = source
    local Player = exports.d4rk_lib:GetPlayer(src)
    
    if Config.Discord.Enabled and Player then
        PerformHttpRequest(Config.Discord.Webhooks.AdminActions, function() end, 'POST', json.encode({
            username = Config.Discord.BotName,
            embeds = {{
                title = '🏕️ Camping Horde Spawned',
                description = ('**Spieler:** %s %s\n**Horde Größe:** %s Zombies'):format(
                    Player.PlayerData.charinfo.firstname,
                    Player.PlayerData.charinfo.lastname,
                    hordeSize
                ),
                color = 16744192,
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }}
        }), {['Content-Type'] = 'application/json'})
    end
end)

-- Export für Blood Moon Status
exports('IsBloodMoonActive', function()
    return BloodMoonActive
end)
