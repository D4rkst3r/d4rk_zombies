# ⚡ Quick Start Guide

Schnelleinstieg in 5 Minuten!

## 📦 Schnell-Installation

```bash
# 1. Resource herunterladen
cd resources
git clone https://github.com/YOUR_REPO/d4rk_zombies.git

# 2. Dependencies prüfen
# ✅ qb-core
# ✅ ox_lib
# ✅ ox_target
# ✅ PolyZone
# ✅ D4rk_lib

# 3. Server-Config
echo "ensure d4rk_zombies" >> server.cfg

# 4. Server starten
restart server
```

## 🎮 Erste Schritte

### 1. Discord Webhooks (Optional, 2 Min)

```lua
-- In config/config.lua:
Config.Discord = {
    Enabled = true,
    Webhooks = {
        AdminActions = 'DEIN_WEBHOOK',
        KillLeaderboard = 'DEIN_WEBHOOK',
    }
}
```

### 2. Erste Zone erstellen (2 Min)

1. Ingame als Admin einloggen
2. `/zombiezone` eingeben
3. "Zone erstellen" → "Kreis"
4. Radius: `50`, Max Zombies: `5`
5. Fertig! ✅

### 3. System testen (1 Min)

- Gehe in die Zone
- Warte 5-10 Sekunden
- Zombies spawnen automatisch
- Töte einen → Drücke E zum Looten

## 🛠️ Basic Commands

```bash
/zombiezone     # Zone-Editor
/zombieadmin    # Admin-Panel
```

## ⚙️ Schnell-Config

### Performance anpassen

**Für starke Server:**
```lua
Config.Optimization.MaxActiveZombies = 75
Config.UpdateInterval = 500
```

**Für schwache Server:**
```lua
Config.Optimization.MaxActiveZombies = 30
Config.UpdateInterval = 1000
```

### Schwierigkeit anpassen

**Easy Mode:**
```lua
Config.ZombieTypes['shambler'].Health = 100
Config.ZombieTypes['shambler'].Damage = 10
```

**Hard Mode:**
```lua
Config.ZombieTypes['shambler'].Health = 250
Config.ZombieTypes['shambler'].Damage = 30
Config.AmbientInfection.Enabled = true
```

## 🎯 Häufigste Probleme

### ❌ Keine Zombies spawnen
```lua
-- Debug aktivieren:
Config.Debug = true

-- Check in F8:
-- "Zone enabled: true"?
-- "Player distance: <150m"?
```

### ❌ ox_target funktioniert nicht
```bash
# Neustart:
restart ox_target
restart d4rk_zombies
```

### ❌ Loot-Items nicht vorhanden
```lua
-- Passe Loot-Table an vorhandene Items an:
Config.LootTables['shambler_loot'].Items = {
    {item = 'bandage', min = 1, max = 2, chance = 50},
    -- Nur Items die in deiner items.lua existieren!
}
```

## 📊 Empfohlene Einstellungen

### Für Roleplay-Server
```lua
Config.AmbientInfection.Enabled = false
Config.KillTracking.Rewards.Enabled = true
Config.Discord.AutoLeaderboard.Enabled = true
Config.NoiseSystem.ShowBlipOnMap = true
```

### Für PvE-Action-Server
```lua
Config.AmbientInfection.Enabled = true
Config.Optimization.MaxActiveZombies = 75
Config.DefaultZoneSettings.MaxZombies = 15
Config.Combat.HeadshotMultiplier = 3.0
```

### Für Survival-Server
```lua
Config.KillTracking.Rewards.Enabled = false
Config.LootTables -- Reduziere alle Chances auf 10-30%
Config.NoiseSystem.ShowBlipOnMap = false
Config.ZombieTypes -- Erhöhe Health & Damage
```

## 🔗 Wichtige Links

- 📖 [Vollständige Dokumentation](README.md)
- 🔧 [Installations-Guide](INSTALLATION.md)
- 🎨 [Config-Templates](CONFIG_TEMPLATE.md)
- 🐛 [Troubleshooting](INSTALLATION.md#häufige-probleme--lösungen)
- 💬 [Discord Support](https://discord.gg/YOUR_INVITE)

## ✅ Checkliste

Nach Installation sollten funktionieren:

- [ ] `/zombiezone` öffnet Menü
- [ ] `/zombieadmin` öffnet Admin-Panel
- [ ] Zonen werden auf Minimap angezeigt
- [ ] Zombies spawnen in Zonen
- [ ] E zum Looten funktioniert
- [ ] Kill-Tracking aktualisiert sich
- [ ] Leaderboard zeigt Statistiken

## 💡 Pro-Tipps

1. **Teste erst mit 1 Zone** (Radius 50, Max 5 Zombies)
2. **Debug-Mode aktivieren** für erste Tests
3. **Backup** vor großen Config-Änderungen
4. **Discord-Webhooks** für besseres Monitoring
5. **Spieler-Feedback** einholen nach 24h

---

## 🆘 Schnelle Hilfe

**Problem?** → Siehe [INSTALLATION.md](INSTALLATION.md)  
**Bug gefunden?** → [GitHub Issues](https://github.com/YOUR_REPO/issues)  
**Frage?** → [Discord](https://discord.gg/YOUR_INVITE)

**Support-Zeiten:**  
Mo-Fr: 10:00 - 20:00 CET  
Sa-So: 12:00 - 18:00 CET

---

**Viel Erfolg beim Zombie-Jagen! 🧟‍♂️🔫**
