-- ====================================
-- ADMIN PANEL
-- ====================================

local d4rk = exports.d4rk_lib
local lib = {
    callback = function(name, ...)
        -- Client-Callbacks in ox_lib werden meistens so aufgerufen:
        return d4rk:callback(name, ...)
    end
}

AdminPanel = {}

function AdminPanel:OpenMainMenu()
    lib.registerContext({
        id = 'zombie_admin_main',
        title = _('admin_menu_title'),
        options = {
            {
                title = _('admin_leaderboard'),
                description = 'Top 10 Zombie Jäger anzeigen',
                icon = 'trophy',
                onSelect = function()
                    self:ShowLeaderboard()
                end
            },
            {
                title = _('admin_toggle_infection'),
                description = 'Ambient Infection ein/ausschalten',
                icon = 'disease',
                onSelect = function()
                    TriggerServerEvent('d4rk_zombies:server:ToggleInfection')
                end
            },
            {
                title = _('admin_post_leaderboard'),
                description = 'Leaderboard zu Discord posten',
                icon = 'share',
                iconColor = 'blue',
                onSelect = function()
                    TriggerServerEvent('d4rk_zombies:server:PostLeaderboard')
                    exports.d4rk_lib:Notify('Leaderboard wurde gepostet', 'success')
                end
            },
            {
                title = _('admin_reset_all'),
                description = 'ALLE Spieler-Stats zurücksetzen',
                icon = 'redo',
                iconColor = 'red',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Alle Stats zurücksetzen?',
                        content = 'Dies kann nicht rückgängig gemacht werden!',
                        centered = true,
                        cancel = true
                    })

                    if confirm == 'confirm' then
                        TriggerServerEvent('d4rk_zombies:server:ResetAllStats')
                        exports.d4rk_lib:Notify('Alle Stats wurden zurückgesetzt', 'success')
                    end
                end
            },
            {
                title = 'Teleport-Menü',
                description = 'Zu Spielern teleportieren',
                icon = 'users',
                onSelect = function()
                    self:OpenTeleportMenu()
                end
            }
        }
    })

    lib.showContext('zombie_admin_main')
end

function AdminPanel:ShowLeaderboard()
    lib.callback('d4rk_zombies:server:GetLeaderboard', false, function(leaderboard, myStats)
        local options = {}

        for rank, data in ipairs(leaderboard) do
            local medal = rank == 1 and '🥇' or rank == 2 and '🥈' or rank == 3 and '🥉' or ''

            table.insert(options, {
                title = ('%s #%s - %s'):format(medal, rank, data.name),
                description = ('%s Zombie Kills'):format(data.kills),
                icon = 'skull',
                iconColor = rank <= 3 and 'yellow' or 'white'
            })
        end

        -- Eigene Stats unten anzeigen
        if myStats then
            table.insert(options, {
                title = '━━━━━━━━━━━━━━━━━',
                description = 'Deine Statistiken',
                icon = 'chart-line',
                disabled = true
            })
            table.insert(options, {
                title = ('Deine Position: #%s'):format(myStats.rank),
                description = ('%s Zombie Kills'):format(myStats.kills),
                icon = 'user',
                iconColor = 'green'
            })
        end

        lib.registerContext({
            id = 'zombie_leaderboard',
            title = _('leaderboard_title'),
            menu = 'zombie_admin_main',
            options = options
        })

        lib.showContext('zombie_leaderboard')
    end)
end

function AdminPanel:OpenTeleportMenu()
    lib.callback('d4rk_zombies:server:GetOnlinePlayers', false, function(players)
        local options = {}

        for _, player in ipairs(players) do
            table.insert(options, {
                title = player.name,
                description = ('ID: %s | Kills: %s'):format(player.source, player.kills),
                icon = 'user',
                onSelect = function()
                    TriggerServerEvent('d4rk_zombies:server:TeleportToPlayer', player.source)
                end
            })
        end

        if #options == 0 then
            options = { {
                title = 'Keine Spieler online',
                icon = 'info-circle'
            } }
        end

        lib.registerContext({
            id = 'zombie_teleport',
            title = 'Spieler Teleport',
            menu = 'zombie_admin_main',
            options = options
        })

        lib.showContext('zombie_teleport')
    end)
end

-- Events
RegisterNetEvent('d4rk_zombies:client:InfectionToggled', function(enabled)
    local msg = enabled and _('infection_enabled') or _('infection_disabled')
    exports.d4rk_lib:Notify(msg, 'info')
end)

-- Command Registration
RegisterCommand(Config.Commands.AdminMenu, function()
    lib.callback('d4rk_zombies:server:CheckPermission', false, function(hasPermission)
        if hasPermission then
            AdminPanel:OpenMainMenu()
        else
            exports.d4rk_lib:Notify(_('no_permission'), 'error')
        end
    end)
end)
