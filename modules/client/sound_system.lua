-- ====================================
-- XSOUND INTEGRATION
-- ====================================

SoundSystem = {}
SoundSystem.ActiveSounds = {}
SoundSystem.LastSoundTime = {}

function SoundSystem:Init()
    if not Config.SoundsEnabled or not Config.UseXSound then return end
    
    -- Prüfe ob xsound verfügbar ist
    if not exports.xsound then
        print('[D4RK ZOMBIES] XSound nicht gefunden - Sounds deaktiviert')
        Config.UseXSound = false
        return
    end
    
    if Config.Debug then
        print('[D4RK ZOMBIES] XSound-System initialisiert')
    end
end

function SoundSystem:PlayZombieSound(zombie, zombieType)
    if not Config.SoundsEnabled or not Config.UseXSound then return end
    
    local zombieId = NetworkGetNetworkIdFromEntity(zombie)
    if zombieId == 0 then
        zombieId = zombie
    end
    
    -- Cooldown-Check
    if self.LastSoundTime[zombieId] and (GetGameTimer() - self.LastSoundTime[zombieId]) < Config.SoundInterval.Min then
        return
    end
    
    local typeData = Config.ZombieTypes[zombieType]
    if not typeData or not typeData.Sound then return end
    
    -- Sound-Name generieren
    local soundName = ('zombie_%s_%s'):format(zombieId, GetGameTimer())
    local soundPath = ('nui://d4rk_zombies/sounds/%s'):format(typeData.Sound)
    local volume = typeData.SoundVolume or 0.2
    local coords = GetEntityCoords(zombie)
    
    -- XSound abspielen
    exports.xsound:PlayUrl(soundName, soundPath, volume, false)
    exports.xsound:Position(soundName, coords)
    exports.xsound:Distance(soundName, Config.SoundDistance)
    
    self.ActiveSounds[zombieId] = soundName
    self.LastSoundTime[zombieId] = GetGameTimer()
    
    -- Auto-Cleanup nach 5 Sekunden
    SetTimeout(5000, function()
        if exports.xsound then
            exports.xsound:Destroy(soundName)
        end
        self.ActiveSounds[zombieId] = nil
    end)
end

function SoundSystem:StopZombieSound(zombie)
    if not Config.UseXSound then return end
    
    local zombieId = NetworkGetNetworkIdFromEntity(zombie)
    if zombieId == 0 then
        zombieId = zombie
    end
    
    local soundName = self.ActiveSounds[zombieId]
    if soundName and exports.xsound then
        exports.xsound:Destroy(soundName)
        self.ActiveSounds[zombieId] = nil
    end
end

function SoundSystem:StartRandomSoundThread()
    if not Config.SoundsEnabled or not Config.UseXSound then return end
    
    CreateThread(function()
        while true do
            local interval = math.random(Config.SoundInterval.Min, Config.SoundInterval.Max)
            Wait(interval)
            
            -- Spiele Sounds für alle aktiven Zombies
            for zoneName, zombies in pairs(ZombieManager.ActiveZombies) do
                for _, zombie in ipairs(zombies) do
                    if DoesEntityExist(zombie.entity) and not zombie.isDead then
                        -- Zufällige Chance für Sound
                        if math.random() < 0.3 then -- 30% Chance
                            SoundSystem:PlayZombieSound(zombie.entity, zombie.type)
                        end
                    end
                end
            end
        end
    end)
end

-- Export
exports('PlayZombieSound', function(zombie, zombieType)
    SoundSystem:PlayZombieSound(zombie, zombieType)
end)
