# 📦 D4RK Zombies - Installationsanleitung

## Schritt-für-Schritt Installation

### Voraussetzungen prüfen

Stelle sicher, dass folgende Resources installiert und funktionsfähig sind:

1. ✅ QBCore Framework (neueste Version)
2. ✅ ox_lib (neueste Version)
3. ✅ ox_target (neueste Version)
4. ✅ PolyZone
5. ✅ oxmysql
6. ✅ D4rk_lib (deine eigene Library)

### Installation

#### 1. Resource herunterladen
```bash
cd resources
# Entweder via Git:
git clone https://github.com/YOUR_REPO/d4rk_zombies.git

# Oder ZIP herunterladen und entpacken
```

#### 2. server.cfg anpassen
Füge am Ende deiner `server.cfg` hinzu (wichtig: NACH den Dependencies!):

```cfg
# Dependencies
ensure qb-core
ensure ox_lib
ensure ox_target
ensure PolyZone
ensure oxmysql
ensure D4rk_lib

# D4RK Zombies (am Ende!)
ensure d4rk_zombies
```

#### 3. Config anpassen

Öffne `d4rk_zombies/config/config.lua` und passe folgendes an:

**Discord Webhooks (Optional aber empfohlen):**
```lua
Config.Discord = {
    Enabled = true, -- auf false wenn du keine Webhooks willst
    Webhooks = {
        AdminActions = 'DEIN_ADMIN_WEBHOOK',
        KillLeaderboard = 'DEIN_LEADERBOARD_WEBHOOK',
    }
}
```

**Admin-Gruppen:**
```lua
Config.AdminGroups = {
    'god',
    'admin',
    'moderator'
    -- Füge deine Admin-Gruppen hinzu
}
```

**Performance-Einstellungen (falls Server schwach):**
```lua
Config.Optimization = {
    DisableTraffic = true,
    DisableAmbientPeds = false, -- NICHT true wenn AmbientInfection = true!
    MaxActiveZombies = 30, -- Reduzieren auf 30 statt 50
}

Config.UpdateInterval = 1000 -- Erhöhen auf 1000ms statt 750ms
```

#### 4. Items zur qb-core/shared/items.lua hinzufügen

Falls folgende Items noch nicht existieren, füge sie hinzu:

```lua
-- Medizinische Items
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

['painkillers'] = {
    name = 'painkillers',
    label = 'Schmerzmittel',
    weight = 50,
    type = 'item',
    image = 'painkillers.png',
    unique = false,
    useable = true,
    shouldClose = true,
    description = 'Lindert Schmerzen'
},

-- Handwerks-Items
['metalscrap'] = {
    name = 'metalscrap',
    label = 'Metallschrott',
    weight = 200,
    type = 'item',
    image = 'metalscrap.png',
    unique = false,
    useable = false,
    shouldClose = false,
    description = 'Brauchbarer Metallschrott'
},

['plastic'] = {
    name = 'plastic',
    label = 'Plastik',
    weight = 100,
    type = 'item',
    image = 'plastic.png',
    unique = false,
    useable = false,
    shouldClose = false,
    description = 'Recyceltes Plastik'
},

['copper'] = {
    name = 'copper',
    label = 'Kupfer',
    weight = 300,
    type = 'item',
    image = 'copper.png',
    unique = false,
    useable = false,
    shouldClose = false,
    description = 'Kupferdraht und Schrott'
},

-- Waffen & Ammo
['pistol_ammo'] = {
    name = 'pistol_ammo',
    label = 'Pistolen-Munition',
    weight = 150,
    type = 'item',
    image = 'pistol_ammo.png',
    unique = false,
    useable = false,
    shouldClose = false,
    description = '9mm Patronen'
},
```

> **Tipp:** Du kannst die Items-Liste in der Config an deine Server-Items anpassen!

#### 5. Server starten

```bash
# Server komplett neustarten (nicht nur refresh!)
restart server

# Oder in der Server-Console:
refresh
ensure d4rk_zombies
```

### Erste Schritte nach Installation

#### 1. Erste Zone erstellen

1. Ingame als Admin einloggen
2. `/zombiezone` eingeben
3. "Zone erstellen" wählen
4. Zonen-Typ auswählen (Kreis empfohlen für Test)
5. **Kreis**: Radius 50, Max Zombies 5
6. Zone wird sofort aktiv

#### 2. System testen

1. Gehe in die erstellte Zone (Radius ist auf Minimap sichtbar)
2. Warte 5-10 Sekunden
3. Zombies sollten spawnen
4. Töte einen Zombie
5. Drücke E auf der Leiche zum Looten

#### 3. Admin-Panel erkunden

```
/zombieadmin
```

Hier kannst du:
- Leaderboard anschauen
- Ambient Infection togglen
- Stats verwalten
- Zu Spielern teleportieren

### Häufige Probleme & Lösungen

#### ❌ Zombies spawnen nicht

**Problem:** Keine Zombies in der Zone

**Lösung:**
1. Prüfe `zones.json` - ist die Zone `enabled: true`?
2. Stehe innerhalb der Zone (< 150m vom Center)
3. Warte mindestens 5 Sekunden
4. Check Server-Console auf Fehler
5. Aktiviere Debug: `Config.Debug = true`

#### ❌ ox_target funktioniert nicht

**Problem:** Keine E-Interaction bei Leichen

**Lösung:**
1. Ist ox_target installiert? `ensure ox_target`
2. Neuester ox_target Update? `cd resources/ox_target && git pull`
3. Restart: `restart ox_target`

#### ❌ Items werden nicht gegeben

**Problem:** Loot funktioniert nicht

**Lösung:**
1. Prüfe ob alle Items in `qb-core/shared/items.lua` existieren
2. Check Server-Console auf Item-Fehler
3. Passe Loot-Tables an vorhandene Items an

#### ❌ Performance-Probleme / FPS-Drops

**Problem:** Spiel laggt stark

**Lösung:**
```lua
-- In config.lua:
Config.UpdateInterval = 1000 -- Auf 1000ms erhöhen
Config.Optimization.MaxActiveZombies = 25 -- Reduzieren
Config.MaxRenderDistance = 100.0 -- Reduzieren
Config.DespawnDistance = 150.0 -- Reduzieren
```

#### ❌ Keine Admin-Rechte

**Problem:** "Keine Berechtigung" Fehler

**Lösung:**
```lua
-- In config.lua:
Config.AdminGroups = {
    'god',
    'admin',
    'DEINE_ADMIN_GRUPPE' -- Hier deine Gruppe eintragen
}
```

### Discord Webhooks einrichten

#### 1. Webhook erstellen

1. Gehe zu deinem Discord-Server
2. Server-Einstellungen → Integrationen → Webhooks
3. "Neuer Webhook" → Kanal auswählen
4. Webhook-URL kopieren

#### 2. In Config eintragen

```lua
Config.Discord = {
    Enabled = true,
    Webhooks = {
        AdminActions = 'https://discord.com/api/webhooks/DEINE_WEBHOOK_ID',
        KillLeaderboard = 'https://discord.com/api/webhooks/DEINE_WEBHOOK_ID',
    },
    AutoLeaderboard = {
        Enabled = true,
        Interval = 86400000, -- 24 Stunden
    }
}
```

#### 3. Testen

```
/zombieadmin → "Leaderboard zu Discord posten"
```

### Backup & Updates

#### Vor jedem Update:

```bash
# Backup der aktuellen Config
cp d4rk_zombies/config/config.lua d4rk_zombies/config/config.lua.backup

# Backup der Zonen
cp d4rk_zombies/zones.json d4rk_zombies/zones.json.backup
```

#### Update durchführen:

```bash
cd resources/d4rk_zombies
git pull

# Config & Zonen wiederherstellen
cp config/config.lua.backup config/config.lua
cp zones.json.backup zones.json

# Server neustarten
restart d4rk_zombies
```

### Support

Bei Problemen:

1. **Debug-Mode aktivieren:**
   ```lua
   Config.Debug = true
   ```

2. **Console-Logs prüfen:**
   - F8 (Client)
   - Server-Console

3. **GitHub Issues:**
   https://github.com/YOUR_REPO/d4rk_zombies/issues

4. **Discord Support:**
   https://discord.gg/YOUR_INVITE

---

## ✅ Installation abgeschlossen!

Wenn alles funktioniert, solltest du jetzt:
- ✅ Zombies in Zonen sehen
- ✅ Leichen looten können
- ✅ Kill-Tracking haben
- ✅ Admin-Menüs nutzen können

Viel Spaß beim Zombie-Jagen! 🧟‍♂️🔫
