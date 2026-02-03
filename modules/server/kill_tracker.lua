-- ====================================
-- KILL TRACKING SYSTEM (SERVER)
-- ====================================

KillTracker = {}

function KillTracker:Init()
    if not Config.KillTracking.Enabled then return end

    -- Stelle sicher dass alle Spieler das metadata field haben
    CreateThread(function()
        Wait(5000) -- Warte auf QBCore Init

        local Players = QBCore.Functions.GetQBPlayers()
        for _, Player in pairs(Players) do
            self:InitializePlayer(Player.PlayerData.source)
        end
    end)
end

function KillTracker:InitializePlayer(source)
    local Player = exports.d4rk_lib:GetPlayer(source)
    if not Player then return end

    if not Player.PlayerData.metadata[Config.KillTracking.MetaDataKey] then
        Player.Functions.SetMetaData(Config.KillTracking.MetaDataKey, 0)
    end
end

function KillTracker:AddKill(source)
    local Player = exports.d4rk_lib:GetPlayer(source)
    if not Player then return end

    local currentKills = Player.PlayerData.metadata[Config.KillTracking.MetaDataKey] or 0
    local newKills = currentKills + 1
    Player.Functions.SetMetaData(Config.KillTracking.MetaDataKey, newKills)

    -- ============================================================
    -- XP SYSTEM INTEGRATION
    -- ============================================================
    local xpAmount = 5 -- Basis XP pro Zombie

    -- Wir nutzen den Export deines XP-Systems
    -- Da der Ordner ein "-" hat, nutzen wir die [] Schreibweise
    exports['qb-xpsystem']:GiveXP(source, xpAmount, "Zombie eliminiert")
    -- ============================================================

    -- Rewards (Geld)
    if Config.KillTracking.Rewards.Enabled then
        local amount = math.random(Config.KillTracking.Rewards.Money.min, Config.KillTracking.Rewards.Money.max)
        Player.Functions.AddMoney(Config.KillTracking.Rewards.MoneyAccount, amount, "zombie-kill")
    end

    -- Notification (Native vom Zombie Script)
    TriggerClientEvent('d4rk_zombies:client:KillNotification', source, newKills)

    return newKills
end

function KillTracker:GetKills(source)
    local Player = exports.d4rk_lib:GetPlayer(source)
    if not Player then return 0 end

    return Player.PlayerData.metadata[Config.KillTracking.MetaDataKey] or 0
end

function KillTracker:ResetKills(source)
    local Player = exports.d4rk_lib:GetPlayer(source)
    if not Player then return end

    Player.Functions.SetMetaData(Config.KillTracking.MetaDataKey, 0)
end

function KillTracker:ResetAllKills()
    local Players = QBCore.Functions.GetQBPlayers()

    for _, Player in pairs(Players) do
        Player.Functions.SetMetaData(Config.KillTracking.MetaDataKey, 0)
    end

    -- Update auch Offline-Spieler in DB
    MySQL.Async.execute('UPDATE players SET metadata = JSON_SET(metadata, "$.zombiekills", 0)', {})
end

function KillTracker:GetLeaderboard(limit)
    limit = limit or 10

    local Players = QBCore.Functions.GetQBPlayers()
    local leaderboard = {}

    -- Online Spieler
    for _, Player in pairs(Players) do
        local kills = Player.PlayerData.metadata[Config.KillTracking.MetaDataKey] or 0

        table.insert(leaderboard, {
            source = Player.PlayerData.source,
            citizenid = Player.PlayerData.citizenid,
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            kills = kills
        })
    end

    -- Sortiere nach Kills
    table.sort(leaderboard, function(a, b)
        return a.kills > b.kills
    end)

    -- Limitiere Ergebnisse
    local top = {}
    for i = 1, math.min(limit, #leaderboard) do
        table.insert(top, leaderboard[i])
    end

    return top
end

function KillTracker:GetPlayerRank(source)
    local leaderboard = self:GetLeaderboard(999)
    local citizenid = exports.d4rk_lib:GetIdentifier(source, 'citizenid')

    for rank, data in ipairs(leaderboard) do
        if data.citizenid == citizenid then
            return rank, data.kills
        end
    end

    return 0, 0
end

-- Events
RegisterNetEvent('d4rk_zombies:server:ZombieKilled', function(zombieType)
    local src = source
    KillTracker:AddKill(src)
end)

RegisterNetEvent('d4rk_zombies:server:ResetAllStats', function()
    local src = source

    if not exports.d4rk_lib:CheckPermission(src, Config.AdminGroups) then
        return
    end

    KillTracker:ResetAllKills()
end)

-- Callbacks
lib.callback.register('d4rk_zombies:server:GetLeaderboard', function(source)
    local leaderboard = KillTracker:GetLeaderboard(10)
    local rank, kills = KillTracker:GetPlayerRank(source)

    local myStats = {
        rank = rank,
        kills = kills
    }

    return leaderboard, myStats
end)

lib.callback.register('d4rk_zombies:server:GetOnlinePlayers', function(source)
    local Players = QBCore.Functions.GetQBPlayers()
    local players = {}

    for _, Player in pairs(Players) do
        table.insert(players, {
            source = Player.PlayerData.source,
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            kills = Player.PlayerData.metadata[Config.KillTracking.MetaDataKey] or 0
        })
    end

    return players
end)

-- Player Joined
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    KillTracker:InitializePlayer(Player.PlayerData.source)
end)
