Locale = {}

Locale.de = {
    -- Notifications
    ['zombie_killed'] = 'Zombie getötet! Total: %s',
    ['loot_found'] = 'Gefunden: %sx %s',
    ['loot_nothing'] = 'Nichts Brauchbares gefunden...',
    ['loot_already_searched'] = 'Diese Leiche wurde bereits durchsucht',
    ['zone_created'] = 'Zone "%s" wurde erstellt',
    ['zone_deleted'] = 'Zone "%s" wurde gelöscht',
    ['zone_updated'] = 'Zone "%s" wurde aktualisiert',
    ['no_permission'] = 'Keine Berechtigung!',
    ['stats_reset'] = 'Zombie-Statistiken wurden zurückgesetzt',
    
    -- Zone Editor
    ['zone_menu_title'] = '🧟 Zombie Zone Editor',
    ['zone_create'] = 'Zone erstellen',
    ['zone_manage'] = 'Zonen verwalten',
    ['zone_list'] = 'Alle Zonen anzeigen',
    ['zone_name'] = 'Zonen-Name',
    ['zone_type'] = 'Zonen-Typ',
    ['zone_type_circle'] = 'Kreis',
    ['zone_type_poly'] = 'Polygon',
    ['zone_radius'] = 'Radius (Meter)',
    ['zone_max_zombies'] = 'Max. Zombies',
    ['zone_point_added'] = 'Punkt hinzugefügt (%s/%s)',
    ['zone_point_finish'] = 'Drücke ENTER um Zone zu erstellen',
    ['zone_tp'] = 'Teleportieren',
    ['zone_edit'] = 'Bearbeiten',
    ['zone_delete'] = 'Löschen',
    ['zone_delete_confirm'] = 'Zone wirklich löschen?',
    
    -- Admin Menu
    ['admin_menu_title'] = '🛡️ Zombie Admin Panel',
    ['admin_leaderboard'] = 'Leaderboard',
    ['admin_stats'] = 'Statistiken',
    ['admin_toggle_infection'] = 'Ambient Infection umschalten',
    ['admin_post_leaderboard'] = 'Leaderboard zu Discord posten',
    ['admin_reset_all'] = 'Alle Stats zurücksetzen',
    ['admin_teleport'] = 'Zu Spieler teleportieren',
    ['infection_enabled'] = 'Ambient Infection aktiviert',
    ['infection_disabled'] = 'Ambient Infection deaktiviert',
    
    -- Leaderboard
    ['leaderboard_title'] = '🏆 Top 10 Zombie Jäger',
    ['leaderboard_rank'] = '#%s - %s: %s Kills',
    ['leaderboard_you'] = 'Deine Position: #%s mit %s Kills',
    
    -- Interaction
    ['press_to_loot'] = 'Drücke ~INPUT_CONTEXT~ zum Durchsuchen',
    ['searching'] = 'Durchsuche Leiche...',
    
    -- Discord
    ['discord_zone_created'] = '🟢 Zone erstellt',
    ['discord_zone_deleted'] = '🔴 Zone gelöscht',
    ['discord_zone_edited'] = '🟡 Zone bearbeitet',
    ['discord_admin'] = 'Administrator',
    ['discord_zone_name'] = 'Zonen-Name',
    ['discord_zone_type'] = 'Typ',
    ['discord_max_zombies'] = 'Max Zombies',
    ['discord_timestamp'] = 'Zeitstempel',
}

function _(key, ...)
    local translation = Locale[Config.Language][key]
    if not translation then return key end
    return string.format(translation, ...)
end
