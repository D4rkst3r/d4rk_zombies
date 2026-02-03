-- ====================================
-- ZONE MANAGEMENT (SERVER)
-- ====================================

-- In einem Server-Script von d4rk_zombies
local d4rk = exports.d4rk_lib

-- Wir registrieren den Callback in deiner d4rk_lib
d4rk:RegisterCallback('d4rk_zombies:server:GetZones', function(source, cb)
    -- Hier musst du die Zonen-Tabelle zurückgeben, die dein Script nutzt
    -- Ich nenne sie hier mal 'Config.Zones' oder 'ZoneCache'
    -- Je nachdem wie sie bei dir heißt:
    local zones = ZoneCache or Config.Zones or {}

    cb(zones)
end)

ZoneManager = {}
ZoneManager.Zones = {}
ZoneManager.ZonesFile = 'zones.json'

function ZoneManager:Init()
    self:LoadZones()
end

function ZoneManager:LoadZones()
    local file = LoadResourceFile(GetCurrentResourceName(), self.ZonesFile)

    if file then
        local success, data = pcall(json.decode, file)
        if success and data then
            self.Zones = data
            print(('[D4RK ZOMBIES] %s Zonen geladen'):format(self:Count()))
        else
            print('[D4RK ZOMBIES] Fehler beim Laden der zones.json - Neue Datei wird erstellt')
            self:SaveZones()
        end
    else
        print('[D4RK ZOMBIES] zones.json nicht gefunden - Erstelle neue Datei')
        self:SaveZones()
    end
end

function ZoneManager:SaveZones()
    local encoded = json.encode(self.Zones, { indent = true })
    SaveResourceFile(GetCurrentResourceName(), self.ZonesFile, encoded, -1)
end

function ZoneManager:CreateZone(name, data)
    if self.Zones[name] then
        return false, 'Zone existiert bereits'
    end

    self.Zones[name] = data
    self:SaveZones()

    -- Notify all clients
    TriggerClientEvent('d4rk_zombies:client:ReloadZones', -1)

    return true
end

function ZoneManager:UpdateZone(name, updates)
    if not self.Zones[name] then
        return false, 'Zone nicht gefunden'
    end

    for key, value in pairs(updates) do
        self.Zones[name][key] = value
    end

    self:SaveZones()
    TriggerClientEvent('d4rk_zombies:client:ReloadZones', -1)

    return true
end

function ZoneManager:DeleteZone(name)
    if not self.Zones[name] then
        return false, 'Zone nicht gefunden'
    end

    self.Zones[name] = nil
    self:SaveZones()
    TriggerClientEvent('d4rk_zombies:client:ReloadZones', -1)

    return true
end

function ZoneManager:GetZone(name)
    return self.Zones[name]
end

function ZoneManager:GetAllZones()
    return self.Zones
end

function ZoneManager:Count()
    local count = 0
    for _ in pairs(self.Zones) do
        count = count + 1
    end
    return count
end

-- Events
RegisterNetEvent('d4rk_zombies:server:CreateZone', function(name, data)
    local src = source

    if not exports.d4rk_lib:CheckPermission(src, Config.AdminGroups) then
        return
    end

    local success, err = ZoneManager:CreateZone(name, data)

    if success then
        -- Discord Log
        if Config.Discord.Enabled then
            DiscordLogger:LogZoneCreated(src, name, data)
        end
    end
end)

RegisterNetEvent('d4rk_zombies:server:UpdateZone', function(name, updates)
    local src = source

    if not exports.d4rk_lib:CheckPermission(src, Config.AdminGroups) then
        return
    end

    ZoneManager:UpdateZone(name, updates)

    if Config.Discord.Enabled then
        DiscordLogger:LogZoneEdited(src, name, updates)
    end
end)

RegisterNetEvent('d4rk_zombies:server:DeleteZone', function(name)
    local src = source

    if not exports.d4rk_lib:CheckPermission(src, Config.AdminGroups) then
        return
    end

    ZoneManager:DeleteZone(name)

    if Config.Discord.Enabled then
        DiscordLogger:LogZoneDeleted(src, name)
    end
end)

-- Callback
lib.callback.register('d4rk_zombies:server:GetZones', function(source)
    return ZoneManager:GetAllZones()
end)
