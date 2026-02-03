# 🔊 Zombie Sounds Setup

## XSound Integration

Dieses Zombie-System nutzt **XSound** für hochwertige 3D-Positionierungs-Audio.

### Installation

1. **XSound Resource installieren:**
   ```bash
   cd resources
   git clone https://github.com/Xogy/xsound.git
   ```

2. **In server.cfg hinzufügen:**
   ```cfg
   ensure xsound
   ensure d4rk_zombies
   ```

3. **Sound-Dateien platzieren:**
   
   Erstelle einen `sounds/` Ordner in diesem Resource:
   ```
   d4rk_zombies/
   ├── sounds/
   │   ├── normal.ogg
   │   ├── fast.ogg
   │   ├── tank.ogg
   │   └── explosive.ogg
   ```

### Sound-Dateien

Du benötigst 4 Sound-Dateien (Format: `.ogg`, `.mp3` oder `.wav`):

- **normal.ogg** - Crawler Zombie-Geräusche
- **fast.ogg** - Runner Zombie-Geräusche
- **tank.ogg** - Tank Zombie-Geräusche
- **explosive.ogg** - Exploder Zombie-Geräusche

### Empfohlene Quellen für Zombie-Sounds

**Kostenlos:**
- [Freesound.org](https://freesound.org/) - Stichwort: "zombie groan"
- [Zapsplat.com](https://www.zapsplat.com/) - Zombie SFX
- [Pixabay Sounds](https://pixabay.com/sound-effects/) - Royalty Free

**Professionell:**
- [AudioJungle](https://audiojungle.net/) - Premium Zombie-Sounds
- [Sonniss](https://sonniss.com/) - Game Audio Bundles

### Sound-Eigenschaften anpassen

In `config/config.lua` kannst du für jeden Zombie-Typ anpassen:

```lua
Config.ZombieTypes = {
    ['crawler'] = {
        Sound = 'normal.ogg',
        SoundVolume = 0.2,  -- 0.0 - 1.0
        -- ...
    }
}

-- Globale Sound-Settings
Config.SoundDistance = 40.0  -- Maximale Hördistanz
Config.SoundInterval = {
    Min = 3000,  -- Mindestens alle 3 Sekunden
    Max = 8000   -- Maximal alle 8 Sekunden
}
```

### XSound deaktivieren

Falls du XSound nicht nutzen möchtest:

```lua
Config.SoundsEnabled = false
-- ODER
Config.UseXSound = false
```

### Troubleshooting

**Keine Sounds hörbar:**
1. Prüfe ob XSound gestartet ist: `ensure xsound`
2. Prüfe Sound-Pfade in F8 Console
3. Stelle sicher dass Sound-Dateien im `sounds/` Ordner liegen
4. Teste mit `Config.Debug = true`

**Sounds zu laut/leise:**
- Passe `SoundVolume` pro Zombie-Typ an (0.1 - 0.5)
- Passe `Config.SoundDistance` an

**Performance-Probleme:**
- Erhöhe `Config.SoundInterval.Min` auf 5000
- Reduziere `Config.SoundDistance` auf 30.0

---

## Alternative: Native GTA Sounds

Falls du XSound nicht nutzen möchtest, kann das System auf native GTA-Sounds umgestellt werden.

Setze in `config.lua`:
```lua
Config.UseXSound = false
```

Das System wird dann die eingebauten Ped-Sounds nutzen (weniger immersiv).

---

**Wichtig:** Sound-Dateien sind **NICHT** im Download enthalten und müssen separat beschafft werden!
