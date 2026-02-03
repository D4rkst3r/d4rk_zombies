# 🎨 Konfigurations-Template

Dieses Dokument zeigt gängige Konfigurationsszenarien und wie du sie einstellst.

## 📊 Performance-Profile

### High-End Server (64+ Spieler, starke Hardware)
```lua
Config.UpdateInterval = 500 -- Sehr reaktiv
Config.MaxRenderDistance = 200.0
Config.DespawnDistance = 250.0
Config.Optimization.MaxActiveZombies = 75
Config.DefaultZoneSettings.MaxZombies = 15
```

### Mid-Range Server (32-64 Spieler, mittlere Hardware)
```lua
Config.UpdateInterval = 750 -- Standard
Config.MaxRenderDistance = 150.0
Config.DespawnDistance = 200.0
Config.Optimization.MaxActiveZombies = 50
Config.DefaultZoneSettings.MaxZombies = 10
```

### Low-End Server (<32 Spieler, schwache Hardware)
```lua
Config.UpdateInterval = 1000 -- Reduziert
Config.MaxRenderDistance = 100.0
Config.DespawnDistance = 150.0
Config.Optimization.MaxActiveZombies = 30
Config.DefaultZoneSettings.MaxZombies = 5
Config.Optimization.DisableTraffic = true
```

## 🧟 Zombie-Schwierigkeit

### Easy Mode (Anfänger-Freundlich)
```lua
Config.ZombieTypes = {
    ['shambler'] = {
        Health = 100, -- Reduziert von 150
        Damage = 10,  -- Reduziert von 15
        Speed = 0.5,  -- Langsamer
        SpawnChance = 70,
    },
    ['runner'] = {
        Health = 75,
        Damage = 15,
        Speed = 1.2,
        SpawnChance = 25,
    },
    ['crawler'] = {
        Health = 50,
        Damage = 5,
        Speed = 0.3,
        SpawnChance = 5,
    }
}

Config.Combat.ZombieVisionRange = 10.0 -- Reduziert
```

### Hard Mode (Hardcore-Spieler)
```lua
Config.ZombieTypes = {
    ['shambler'] = {
        Health = 200,
        Damage = 25,
        Speed = 0.8,
        SpawnChance = 40,
    },
    ['runner'] = {
        Health = 150,
        Damage = 35,
        Speed = 2.0,
        SpawnChance = 40,
    },
    ['crawler'] = {
        Health = 100,
        Damage = 20,
        Speed = 0.6,
        SpawnChance = 20,
    }
}

Config.NoiseSystem.ZombieVisionRange = 20.0 -- Erhöht
Config.Combat.HeadshotMultiplier = 2.0 -- Reduziert
```

### Nightmare Mode (Extrem)
```lua
Config.ZombieTypes = {
    ['shambler'] = {
        Health = 300,
        Damage = 40,
        Speed = 1.0,
        SpawnChance = 30,
    },
    ['runner'] = {
        Health = 200,
        Damage = 50,
        Speed = 2.5,
        SpawnChance = 50,
    },
    ['crawler'] = {
        Health = 150,
        Damage = 30,
        Speed = 0.8,
        SpawnChance = 20,
    }
}

Config.DefaultZoneSettings.MaxZombies = 20
Config.NoiseSystem.ZombieVisionRange = 25.0
Config.AmbientInfection.Enabled = true
Config.AmbientInfection.ConversionChance = 0.30 -- 30%
```

## 💰 Loot-Profile

### Generous (Viel Loot)
```lua
Config.LootTables = {
    ['shambler_loot'] = {
        Items = {
            {item = 'bandage', min = 2, max = 4, chance = 60},
            {item = 'water_bottle', min = 1, max = 2, chance = 50},
            {item = 'lockpick', min = 1, max = 2, chance = 30},
            {item = 'metalscrap', min = 3, max = 6, chance = 45},
            {item = 'weapon_knife', min = 1, max = 1, chance = 15},
        }
    }
}
```

### Balanced (Standard)
```lua
-- Siehe Haupt-Config
```

### Scarce (Wenig Loot, Survival-Fokus)
```lua
Config.LootTables = {
    ['shambler_loot'] = {
        Items = {
            {item = 'bandage', min = 1, max = 1, chance = 25},
            {item = 'water_bottle', min = 1, max = 1, chance = 15},
            {item = 'metalscrap', min = 1, max = 2, chance = 20},
            {item = 'plastic', min = 1, max = 2, chance = 25},
        }
    },
    ['runner_loot'] = {
        Items = {
            {item = 'bandage', min = 1, max = 2, chance = 30},
            {item = 'pistol_ammo', min = 2, max = 5, chance = 10},
        }
    }
}
```

## 🎯 Noise-System Profile

### Stealth-Focused (Vorsicht wird belohnt)
```lua
Config.NoiseSystem = {
    Enabled = true,
    ShowBlipOnMap = true,
    Crouching = 1.0,          -- Sehr leise
    Walking = 3.0,
    Running = 20.0,
    Shooting = 50.0,
    ShootingWithSuppressor = 10.0, -- Stark reduziert
    VehicleMultiplier = 0.6,
    ZombieVisionRange = 12.0,
}
```

### Action-Focused (Mehr Kämpfe)
```lua
Config.NoiseSystem = {
    Enabled = true,
    ShowBlipOnMap = false,    -- Keine visuelle Hilfe
    Crouching = 3.0,
    Walking = 8.0,
    Running = 30.0,
    Shooting = 70.0,
    ShootingWithSuppressor = 20.0,
    VehicleMultiplier = 1.0,
    ZombieVisionRange = 18.0,
}
```

### Noise Disabled (Klassisches Zombie-Verhalten)
```lua
Config.NoiseSystem = {
    Enabled = false, -- Zombies reagieren nur auf Sichtlinie
}
```

## 🏆 Reward-Systeme

### Money Rewards aktivieren
```lua
Config.KillTracking = {
    Enabled = true,
    Rewards = {
        Enabled = true,
        Money = {min = 10, max = 25}, -- Pro Kill
        MoneyAccount = 'cash',
    }
}
```

### Bonus für Top-Spieler
```lua
-- Erstelle ein Custom-Event in server/main.lua:
CreateThread(function()
    while true do
        Wait(3600000) -- Jede Stunde
        
        local leaderboard = KillTracker:GetLeaderboard(3)
        
        -- Top 3 belohnen
        for rank, data in ipairs(leaderboard) do
            local bonus = (4 - rank) * 1000 -- #1 = 3000, #2 = 2000, #3 = 1000
            exports.D4rk_lib:AddMoney(data.source, 'bank', bonus)
            
            TriggerClientEvent('QBCore:Notify', data.source, 
                ('Zombie Jäger Bonus: $%s (Rang #%s)'):format(bonus, rank), 
                'success', 5000
            )
        end
    end
end)
```

## 🦠 Ambient Infection Modi

### Zombie Apokalypse (Hardcore)
```lua
Config.AmbientInfection = {
    Enabled = true,
    ConversionRadius = 150.0,    -- Großer Bereich
    ConversionChance = 0.25,      -- 25% Chance
    CheckInterval = 5000,         -- Häufige Checks
    BlacklistedModels = {
        's_m_y_cop_01',           -- Nur Polizei ausschließen
    }
}
Config.Optimization.DisableAmbientPeds = false -- WICHTIG!
```

### Kontrollierte Infektion (Moderate)
```lua
Config.AmbientInfection = {
    Enabled = true,
    ConversionRadius = 75.0,
    ConversionChance = 0.10,
    CheckInterval = 15000,
    BlacklistedModels = {
        -- Alle wichtigen NPCs schützen
        's_m_y_cop_01', 's_f_y_cop_01',
        's_m_m_paramedic_01', 's_m_m_doctor_01',
        's_m_m_fiboffice_01', 's_m_m_ciasec_01',
    }
}
```

### Nur Zonen (Standard)
```lua
Config.AmbientInfection = {
    Enabled = false,
}
```

## 📱 Discord Integration

### Minimal (Nur wichtige Events)
```lua
Config.Discord = {
    Enabled = true,
    Webhooks = {
        AdminActions = 'WEBHOOK',
        KillLeaderboard = 'WEBHOOK',
    },
    AutoLeaderboard = {
        Enabled = false, -- Manuell posten
    }
}
```

### Maximal (Alles loggen)
```lua
Config.Discord = {
    Enabled = true,
    Webhooks = {
        AdminActions = 'WEBHOOK',
        KillLeaderboard = 'WEBHOOK',
    },
    AutoLeaderboard = {
        Enabled = true,
        Interval = 43200000, -- Alle 12 Stunden
    }
}

-- Custom: Jeden Kill loggen (Performance-Impact!)
-- In server/main.lua hinzufügen:
RegisterNetEvent('d4rk_zombies:server:ZombieKilled', function(zombieType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Discord Webhook für jeden Kill
    PerformHttpRequest('DEIN_WEBHOOK', function() end, 'POST', json.encode({
        embeds = {{
            title = '🎯 Zombie Eliminiert',
            description = ('%s hat einen %s getötet'):format(
                Player.PlayerData.charinfo.firstname,
                zombieType
            ),
            color = 65280
        }}
    }), {['Content-Type'] = 'application/json'})
end)
```

## 🎮 Spezial-Events

### Halloween Event Config
```lua
-- Erhöhe Spawn-Raten
Config.DefaultZoneSettings = {
    MaxZombies = 20,
    SpawnInterval = 3000, -- Schnellerer Spawn
    RespawnTime = 15000,  -- Schnellerer Respawn
}

-- Besserer Loot
Config.LootTables['shambler_loot'].Items = {
    {item = 'halloween_candy', min = 5, max = 10, chance = 80},
    {item = 'pumpkin', min = 1, max = 3, chance = 50},
    -- ...
}

-- Ambient Infection aktivieren
Config.AmbientInfection.Enabled = true
Config.AmbientInfection.ConversionChance = 0.20
```

### Raid-Event (Temporär)
```lua
-- Erstelle temporäre Raid-Zone per Export
exports['d4rk_zombies']:CreateZone('raid_event', {
    type = 'circle',
    coords = {x = 123.45, y = -678.90, z = 50.0},
    radius = 100.0,
    maxZombies = 50, -- Massive Horde
    enabled = true
})

-- Nach 30 Minuten entfernen:
SetTimeout(1800000, function()
    exports['d4rk_zombies']:DeleteZone('raid_event')
end)
```

---

## 💡 Pro-Tipps

1. **Performance-Testing:** Teste neue Configs immer erst mit wenigen Spielern
2. **Backup:** Sichere `zones.json` vor größeren Änderungen
3. **Graduelle Anpassungen:** Ändere Werte schrittweise, nicht radikal
4. **Player-Feedback:** Frage deine Community nach bevorzugter Schwierigkeit
5. **Server-Monitoring:** Überwache RAM/CPU nach Config-Änderungen

## 🔧 Entwickler-Optionen

### Debug-Informationen aktivieren
```lua
Config.Debug = true

-- Füge in client/main.lua hinzu für erweiterte Debug-Info:
CreateThread(function()
    while Config.Debug do
        Wait(1000)
        
        local activeZombies = ZombieManager.TotalActiveZombies
        local noiseRadius = NoiseSystem:GetCurrentRadius()
        
        print(('Active Zombies: %s | Noise: %.1fm'):format(activeZombies, noiseRadius))
    end
end)
```

### Performance-Metriken
```lua
-- In server/main.lua:
CreateThread(function()
    while true do
        Wait(60000) -- Jede Minute
        
        local zones = ZoneManager:Count()
        local totalKills = 0
        
        for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
            totalKills = totalKills + (Player.PlayerData.metadata.zombiekills or 0)
        end
        
        print(('[STATS] Zones: %s | Total Kills: %s'):format(zones, totalKills))
    end
end)
```
