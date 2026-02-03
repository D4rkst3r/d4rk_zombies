-- ====================================
-- LOOT SYSTEM (SERVER)
-- ====================================

LootSystem = {}

function LootSystem:RollLoot(lootTableName)
    local lootTable = Config.LootTables[lootTableName]
    if not lootTable then return {} end
    
    local rewards = {}
    
    for _, item in ipairs(lootTable.Items) do
        local roll = math.random(1, 100)
        
        if roll <= item.chance then
            local amount = math.random(item.min, item.max)
            
            table.insert(rewards, {
                name = item.item,
                amount = amount
            })
        end
    end
    
    return rewards
end

function LootSystem:GiveItems(source, items)
    if #items == 0 then
        TriggerClientEvent('d4rk_zombies:client:ReceiveLoot', source, {})
        return
    end
    
    local Player = exports.d4rk_lib:GetPlayer(source)
    if not Player then return end
    
    local itemsWithLabels = {}
    
    for _, item in ipairs(items) do
        local success = Player.Functions.AddItem(item.name, item.amount)
        
        if success then
            local itemData = QBCore.Shared.Items[item.name]
            table.insert(itemsWithLabels, {
                name = item.name,
                amount = item.amount,
                label = itemData and itemData.label or item.name
            })
            
            TriggerClientEvent('inventory:client:ItemBox', source, itemData, 'add', item.amount)
        end
    end
    
    TriggerClientEvent('d4rk_zombies:client:ReceiveLoot', source, itemsWithLabels)
end

-- Event Handler
RegisterNetEvent('d4rk_zombies:server:RollLoot', function(lootTableName)
    local src = source
    
    local rewards = LootSystem:RollLoot(lootTableName)
    LootSystem:GiveItems(src, rewards)
end)
