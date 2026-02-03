-- ====================================
-- DISCORD LOGGING SYSTEM
-- ====================================

DiscordLogger = {}

function DiscordLogger:SendEmbed(webhook, embed)
    if not Config.Discord.Enabled then return end
    
    PerformHttpRequest(webhook, function(err, text, headers)
        if err ~= 200 and Config.Debug then
            print(('[D4RK ZOMBIES] Discord Webhook Error: %s'):format(err))
        end
    end, 'POST', json.encode({
        username = Config.Discord.BotName,
        avatar_url = Config.Discord.BotAvatar,
        embeds = {embed}
    }), {['Content-Type'] = 'application/json'})
end

function DiscordLogger:LogZoneCreated(source, zoneName, zoneData)
    local Player = exports.d4rk_lib:GetPlayer(source)
    if not Player then return end
    
    local embed = {
        title = _('discord_zone_created'),
        color = 65280, -- Grün
        fields = {
            {
                name = _('discord_admin'),
                value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                inline = true
            },
            {
                name = _('discord_zone_name'),
                value = zoneName,
                inline = true
            },
            {
                name = _('discord_zone_type'),
                value = zoneData.type,
                inline = true
            },
            {
                name = _('discord_max_zombies'),
                value = tostring(zoneData.maxZombies),
                inline = true
            }
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }
    
    self:SendEmbed(Config.Discord.Webhooks.AdminActions, embed)
end

function DiscordLogger:LogZoneEdited(source, zoneName, updates)
    local Player = exports.d4rk_lib:GetPlayer(source)
    if not Player then return end
    
    local changesText = ''
    for key, value in pairs(updates) do
        changesText = changesText .. ('**%s**: %s\n'):format(key, tostring(value))
    end
    
    local embed = {
        title = _('discord_zone_edited'),
        color = 16776960, -- Gelb
        fields = {
            {
                name = _('discord_admin'),
                value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                inline = true
            },
            {
                name = _('discord_zone_name'),
                value = zoneName,
                inline = true
            },
            {
                name = 'Änderungen',
                value = changesText,
                inline = false
            }
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }
    
    self:SendEmbed(Config.Discord.Webhooks.AdminActions, embed)
end

function DiscordLogger:LogZoneDeleted(source, zoneName)
    local Player = exports.d4rk_lib:GetPlayer(source)
    if not Player then return end
    
    local embed = {
        title = _('discord_zone_deleted'),
        color = Config.Discord.EmbedColor,
        fields = {
            {
                name = _('discord_admin'),
                value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                inline = true
            },
            {
                name = _('discord_zone_name'),
                value = zoneName,
                inline = true
            }
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }
    
    self:SendEmbed(Config.Discord.Webhooks.AdminActions, embed)
end

function DiscordLogger:PostLeaderboard()
    local leaderboard = KillTracker:GetLeaderboard(10)
    
    local description = '**Top 10 Zombie Jäger**\n\n'
    
    for rank, data in ipairs(leaderboard) do
        local medal = rank == 1 and '🥇' or rank == 2 and '🥈' or rank == 3 and '🥉' or '▫️'
        description = description .. ('%s **#%s** - %s: **%s Kills**\n'):format(medal, rank, data.name, data.kills)
    end
    
    local embed = {
        title = '🏆 Zombie Survival Leaderboard',
        description = description,
        color = 15844367, -- Gold
        thumbnail = {
            url = 'https://i.imgur.com/YOUR_ZOMBIE_IMAGE.png'
        },
        footer = {
            text = 'D4rk Zombies | Letzte Aktualisierung'
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }
    
    self:SendEmbed(Config.Discord.Webhooks.KillLeaderboard, embed)
end

-- Auto Leaderboard Posting
if Config.Discord.AutoLeaderboard.Enabled then
    CreateThread(function()
        while true do
            Wait(Config.Discord.AutoLeaderboard.Interval)
            DiscordLogger:PostLeaderboard()
        end
    end)
end

-- Event
RegisterNetEvent('d4rk_zombies:server:PostLeaderboard', function()
    local src = source
    
    if not exports.d4rk_lib:CheckPermission(src, Config.AdminGroups) then
        return
    end
    
    DiscordLogger:PostLeaderboard()
end)
