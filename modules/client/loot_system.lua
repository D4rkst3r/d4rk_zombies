-- ====================================
-- LOOT SYSTEM
-- ====================================

RegisterNetEvent('d4rk_zombies:client:LootZombie', function(entity)
    if not DoesEntityExist(entity) then return end
    
    local state = Entity(entity).state
    if state.looted then
        exports.d4rk_lib:Notify(_('loot_already_searched'), 'error')
        return
    end
    
    local zombieType = state.zombieType
    local lootTable = Config.ZombieTypes[zombieType].LootTable
    local lootConfig = Config.LootTables[lootTable]
    
    if not lootConfig then
        print(('[D4RK ZOMBIES] Loot-Tabelle nicht gefunden: %s'):format(lootTable))
        return
    end
    
    -- Animation laden
    RequestAnimDict(lootConfig.SearchAnimation.dict)
    while not HasAnimDictLoaded(lootConfig.SearchAnimation.dict) do
        Wait(10)
    end
    
    local playerPed = PlayerPedId()
    TaskPlayAnim(
        playerPed,
        lootConfig.SearchAnimation.dict,
        lootConfig.SearchAnimation.anim,
        8.0, -8.0, -1,
        lootConfig.SearchAnimation.flags,
        0, false, false, false
    )
    
    -- Progress Bar
    if lib.progressBar({
        duration = lootConfig.SearchTime,
        label = _('searching'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
    }) then
        ClearPedTasks(playerPed)
        
        -- Markiere als gelootet
        Entity(entity).state:set('looted', true, true)
        
        -- Server-seitiges Loot-Rolling
        TriggerServerEvent('d4rk_zombies:server:RollLoot', lootTable)
    else
        ClearPedTasks(playerPed)
        exports.d4rk_lib:Notify('Durchsuchung abgebrochen', 'error')
    end
end)

-- Loot-Ergebnis vom Server
RegisterNetEvent('d4rk_zombies:client:ReceiveLoot', function(items)
    if not items or #items == 0 then
        exports.d4rk_lib:Notify('Nichts Brauchbares gefunden...', 'info')
        return
    end
    
    for _, item in ipairs(items) do
        local message = string.format('Gefunden: %sx %s', item.amount, item.label)
        exports.d4rk_lib:Notify(message, 'success')
    end
end)
