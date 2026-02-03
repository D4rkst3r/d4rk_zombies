# 🧟 D4RK Zombies - Ultimate Modular Zombie Survival System

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/YOUR_REPO)
[![Framework](https://img.shields.io/badge/framework-QBCore-green.svg)](https://github.com/qbcore-framework)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

Ein hochmodernes, vollständig modulares Zombie-Survival-System für FiveM mit QBCore Framework. Entwickelt mit Fokus auf Performance, Spieler-Immersion und administrative Flexibilität.

## 🎯 Hauptfeatures

### 🎮 Stealth & Aggro System
- **Dynamisches Noise System**: Lärmpegel basiert auf Bewegung, Waffen und Fahrzeugen
- **Visuelles Feedback**: Roter Radius-Blip zeigt aktuellen Lärmpegel auf der Minimap
- **Intelligente KI**: Zombies reagieren auf Lärm UND Sichtlinie
- **Schalldämpfer-Erkennung**: Automatische Reduzierung des Waffenlärms

### 🧟 Zombie-Varianten
- **Shambler**: Langsam, robust, klassisches Zombie-Verhalten
- **Runner**: Schnell, aggressiv, gefährlich im Nahkampf
- **Crawler**: Niedrig, schwer zu treffen, überraschende Angriffe

### 🎁 Loot-System
- **ox_target Integration**: Leichen durchsuchen per Interaktion
- **Progressbars**: Realistische Such-Animationen (3-5 Sekunden)
- **Konfigurierbare Loot-Tables**: Wahrscheinlichkeiten, Items, Mengen pro Zombie-Typ
- **State Bags**: Jede Leiche kann nur einmal geplündert werden

### 🗺️ Zonen-Management
- **Ingame-Editor**: Erstelle Zonen direkt im Spiel
- **Kreis & Polygon**: Zwei Zonen-Typen für maximale Flexibilität
- **Live-Verwaltung**: Bearbeite, aktiviere/deaktiviere, lösche Zonen ohne Restart
- **Persistente Speicherung**: Alle Zonen werden in `zones.json` gespeichert

### 📊 Kill-Tracking & Leaderboard
- **Automatisches Tracking**: Jeder Kill wird in Spieler-Metadata gespeichert
- **Top 10 Leaderboard**: Ingame-Anzeige der besten Zombie-Jäger
- **Discord-Integration**: Automatisches Posten der Leaderboards
- **Rewards**: Optional Geld pro Kill (konfigurierbar)

### 🦠 Ambient Infection
- **NPC-Konvertierung**: Verwandelt normale Peds in Zombies
- **Zuschaltbar**: Kann ingame ein/ausgeschaltet werden
- **Blacklist**: Schütze wichtige NPCs (Polizei, Medics, etc.)

### ⚡ Performance-Optimierung
- **Intelligentes Spawning**: Nur in aktiven Zonen und Spielernähe
- **Distanz-Checks**: Reduzierte Update-Frequenz (500-1000ms)
- **Despawn-System**: Automatisches Entfernen von zu weit entfernten Zombies
- **Traffic-Deaktivierung**: Optional komplett fahrzeugfreie Welt

## 📋 Voraussetzungen

### Dependencies (erforderlich)
- [QBCore Framework](https://github.com/qbcore-framework)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [PolyZone](https://github.com/mkafrin/PolyZone)
- [oxmysql](https://github.com/overextended/oxmysql)
- **D4rk_lib** (Deine eigene Library)

## 📦 Installation

### 1. Download & Platzierung
```bash
cd resources
git clone https://github.com/YOUR_REPO/d4rk_zombies.git
```

### 2. server.cfg Eintrag
```cfg
ensure qb-core
ensure ox_lib
ensure ox_target
ensure PolyZone
ensure D4rk_lib
ensure d4rk_zombies
```

### 3. Discord Webhooks (Optional)
Öffne `config/config.lua` und füge deine Webhooks ein:
```lua
Config.Discord = {
    Enabled = true,
    Webhooks = {
        AdminActions = 'DEIN_WEBHOOK_HIER',
        KillLeaderboard = 'DEIN_WEBHOOK_HIER',
    }
}
```

### 4. Items zur QBCore Items.lua hinzufügen (Falls nicht vorhanden)
```lua
-- Beispiel Items für Loot
['bandage'] = {
    name = 'bandage',
    label = 'Bandage',
    weight = 100,
    type = 'item',
    image = 'bandage.png',
    unique = false,
    useable = true,
    shouldClose = true,
    description = 'Verbindet Wunden'
},
```

## 🎮 Verwendung

### Admin-Commands
```
/zombiezone     - Öffnet den Zone-Editor
/zombieadmin    - Öffnet das Admin-Panel
```

### Zonen erstellen
1. `/zombiezone` ausführen
2. "Zone erstellen" auswählen
3. Zonen-Typ wählen (Kreis oder Polygon)
4. Für **Kreis**: Radius und Max-Zombies eingeben
5. Für **Polygon**: Mit E Punkte setzen, mit ENTER abschließen

### Leaderboard anzeigen
1. `/zombieadmin` ausführen
2. "Leaderboard" auswählen
3. Top 10 werden angezeigt inklusive deiner Position

### Zombie looten
1. Töte einen Zombie
2. Gehe zur Leiche
3. Drücke E (ox_target)
4. Warte auf Progressbar (3-5 Sekunden)
5. Erhalte Items

## ⚙️ Konfiguration

### Zombie-Typen anpassen
```lua
Config.ZombieTypes = {
    ['custom_zombie'] = {
        Name = 'Dein Custom Zombie',
        Model = 'dein_model',
        Health = 200,
        Speed = 1.0,
        Damage = 25,
        SpawnChance = 15,
        LootTable = 'custom_loot',
        -- ...
    }
}
```

### Loot-Tables anpassen
```lua
Config.LootTables = {
    ['custom_loot'] = {
        SearchTime = 5000,
        Items = {
            {item = 'dein_item', min = 1, max = 5, chance = 50},
            -- ...
        }
    }
}
```

### Noise-System tweaken
```lua
Config.NoiseSystem = {
    Crouching = 2.0,      -- Schleichen
    Walking = 5.0,         -- Gehen
    Running = 25.0,        -- Rennen
    Shooting = 60.0,       -- Schießen
    -- ...
}
```

## 📡 Exports

### Client-Side
```lua
-- Zombie-Kills eines Spielers abrufen
local kills = exports['d4rk_zombies']:GetZombieKills()

-- Infection-Status prüfen
local enabled = exports['d4rk_zombies']:IsInfectionEnabled()

-- Aktive Zombie-Anzahl
local count = exports['d4rk_zombies']:GetActiveZombieCount()

-- Aktuellen Noise-Radius
local radius = exports['d4rk_zombies']:GetCurrentNoiseRadius()
```

### Server-Side
```lua
-- Kills eines Spielers abrufen
local kills = exports['d4rk_zombies']:GetZombieKills(source)

-- Kill hinzufügen
local newKills = exports['d4rk_zombies']:AddZombieKill(source)

-- Leaderboard abrufen
local top10 = exports['d4rk_zombies']:GetLeaderboard(10)

-- Zone erstellen
local success = exports['d4rk_zombies']:CreateZone('zone_name', {
    type = 'circle',
    coords = {x = 0, y = 0, z = 0},
    radius = 50,
    maxZombies = 10,
    enabled = true
})

-- Alle Zonen abrufen
local zones = exports['d4rk_zombies']:GetAllZones()
```

## 🐛 Troubleshooting

### Zombies spawnen nicht
- Prüfe ob Zonen in `zones.json` vorhanden und `enabled = true`
- Stelle sicher dass du in der Nähe einer Zone bist (<150m)
- Check Server-Console auf Fehler
- Debug-Mode aktivieren: `Config.Debug = true`

### Loot funktioniert nicht
- Prüfe ob alle Items in deiner `qb-core/shared/items.lua` existieren
- Stelle sicher dass ox_target korrekt installiert ist
- Check ob Entity State Bags funktionieren

### Performance-Probleme
- Reduziere `Config.Optimization.MaxActiveZombies`
- Erhöhe `Config.UpdateInterval` (z.B. auf 1000ms)
- Reduziere `Config.MaxRenderDistance`
- Aktiviere `Config.Optimization.DisableTraffic`

## 📝 Changelog

### Version 2.0.0 (Aktuell)
- ✨ Komplettes Noise & Stealth System
- ✨ Drei Zombie-Varianten mit einzigartigen Eigenschaften
- ✨ Ingame Zone-Editor mit Polygon-Support
- ✨ Discord-Integration mit Auto-Leaderboards
- ✨ Ambient Infection System
- ✨ Vollständige ox_lib Integration
- ⚡ Massive Performance-Optimierungen
- 🐛 Diverse Bugfixes

## 🤝 Support & Community

- **Discord**: [Dein Discord Server](https://discord.gg/YOUR_INVITE)
- **Issues**: [GitHub Issues](https://github.com/YOUR_REPO/issues)
- **Dokumentation**: [Wiki](https://github.com/YOUR_REPO/wiki)

## 📜 License

Dieses Projekt ist unter der MIT-Lizenz lizenziert. Siehe [LICENSE](LICENSE) für Details.

## 💎 Credits

Entwickelt mit ❤️ von **D4rk Development**

**Special Thanks:**
- QBCore Framework Team
- Overextended (ox_lib, ox_target)
- PolyZone (mkafrin)
- FiveM Community

---

> **Note**: Dieses Script erfordert grundlegendes Verständnis von FiveM, Lua und QBCore. Bei Fragen wende dich an unser Support-Team.
