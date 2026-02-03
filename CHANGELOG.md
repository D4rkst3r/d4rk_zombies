# 📋 Changelog

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-02-03

### 🎉 Initial Release - Complete Rewrite

Dies ist die erste vollständige Version des modularen Zombie-Systems.

### ✨ Features

#### Core Systems
- **Noise & Stealth System**: Dynamisches Lärm-System mit visueller Feedback
  - Berechnung basiert auf Bewegung, Waffen und Fahrzeugen
  - Roter Radius-Blip zeigt aktuellen Lärmpegel
  - Schalldämpfer-Erkennung für Waffen
  - Sichtlinien-Checks für Zombie-KI

#### Zombie-Varianten
- **Shambler**: Klassischer langsamer Zombie mit Drunk-Walk Animation
- **Runner**: Schneller, aggressiver Zombie mit erhöhtem Schaden
- **Crawler**: Kriechender Zombie, schwer zu treffen

#### Loot-System
- Integration mit ox_target für intuitive Interaktion
- Progressbars mit Animationen (3-5 Sekunden)
- Konfigurierbare Loot-Tables mit Wahrscheinlichkeiten
- State Bags verhindern mehrfaches Looten
- Automatische Item-Distribution über QBCore

#### Zone-Management
- Ingame Zone-Editor mit ox_lib Menüs
- Zwei Zonen-Typen: Kreis und Polygon
- Live-Erstellung und -Bearbeitung
- Persistente Speicherung in zones.json
- Teleport-Funktion zu Zonen
- Aktivieren/Deaktivieren von Zonen ohne Neustart

#### Kill-Tracking
- Automatische Speicherung in Spieler-Metadata
- Top 10 Leaderboard-System
- Ingame-Anzeige mit Rangposition
- Optional: Geld-Rewards pro Kill
- Discord-Integration für Auto-Leaderboards

#### Ambient Infection
- Konvertierung von NPCs zu Zombies
- Konfigurierbarer Radius und Konversionsrate
- Blacklist für wichtige NPCs (Polizei, Medics)
- Zuschaltbar über Admin-Panel
- Automatisches Loot-Setup für infizierte NPCs

#### Admin-Tools
- Umfassendes Admin-Panel (ox_lib)
- Zone-Editor mit Polygon-Support
- Leaderboard-Verwaltung
- Stats-Reset (einzeln oder alle)
- Spieler-Teleport-System
- Infection-Toggle

#### Discord-Integration
- Webhook-Logging für Admin-Aktionen
- Automatisches Leaderboard-Posting (konfigurierbar)
- Rich Embeds mit detaillierten Informationen
- Separate Webhooks für verschiedene Event-Typen

### ⚡ Performance-Optimierungen
- Intelligentes Spawning nur in aktiven Zonen
- Distanz-basierte Update-Intervalle (750ms Standard)
- Automatisches Despawning bei großer Entfernung
- Globales Zombie-Limit (konfiguriebar)
- Ground-Check vor Spawn verhindert Glitches
- Entity-Existence-Checks vor allen Operationen
- Optimierte Thread-Nutzung
- Optionale Verkehrs-Deaktivierung

### 🎨 UI/UX
- Vollständige ox_lib Integration
- Moderne, responsive Menüs
- Intuitive Icons und Beschreibungen
- Progressbars mit Animationen
- Mehrsprachigkeit (Deutsch als Standard)
- Visuelle Feedback-Systeme

### 🔧 Technische Details
- QBCore Framework Integration
- ox_lib für Menüs und UI
- ox_target für Interaktionen
- PolyZone für Gebietsverwaltung
- oxmysql für Datenbank-Operationen
- Lua 5.4 Unterstützung
- Modularer Code-Aufbau
- Umfassende Config-Datei
- Export-System für andere Resources

### 📝 Dokumentation
- Ausführliche README mit Features
- Schritt-für-Schritt Installationsanleitung
- Konfigurations-Templates für verschiedene Szenarien
- Troubleshooting-Guide
- Code-Kommentare in allen Dateien

### 🐛 Bekannte Limitierungen
- Zombie-Animationen sind auf GTA V Animationen beschränkt
- PolyZone-Performance kann bei sehr komplexen Polygonen leiden
- Discord-Webhooks haben Rate-Limits (berücksichtigt)

---

## [Unreleased]

### 🚀 Geplant für v2.1.0
- [ ] Zombie-Horden-Events
- [ ] Boss-Zombies mit Special-Abilities
- [ ] Barrikaden-System
- [ ] Safe-Zones
- [ ] Crafting-System für Zombie-Abwehr
- [ ] Achievements-System
- [ ] Ranglisten-Saisons
- [ ] Mobile-App Integration
- [ ] Custom Zombie-Models Support
- [ ] Voice-Lines für Zombies

### 🔮 Zukünftige Features
- Zombie-Mutationen
- Wetter-abhängiges Verhalten
- Tag/Nacht-Zyklen
- Survival-Mechanics (Hunger, Durst)
- Spieler-Gruppen-System
- PvP Safe-Zones
- Trading-System
- Vehicle-Upgrades gegen Zombies

---

## Version-Schema

Versions-Nummerierung: `MAJOR.MINOR.PATCH`

- **MAJOR**: Inkompatible API-Änderungen
- **MINOR**: Neue Features, abwärtskompatibel
- **PATCH**: Bugfixes, abwärtskompatibel

## Support & Feedback

- **Issues**: [GitHub Issues](https://github.com/YOUR_REPO/d4rk_zombies/issues)
- **Discord**: [Dein Discord Server](https://discord.gg/YOUR_INVITE)
- **Dokumentation**: [Wiki](https://github.com/YOUR_REPO/d4rk_zombies/wiki)

---

**Legende:**
- ✨ Neue Features
- 🐛 Bugfixes
- ⚡ Performance-Verbesserungen
- 🔒 Sicherheit
- 🎨 UI/UX
- 📝 Dokumentation
- ♻️ Refactoring
- 🗑️ Entfernt
