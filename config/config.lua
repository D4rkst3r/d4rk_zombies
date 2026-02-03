Config = {}

-- ====================================
-- CORE SYSTEM SETTINGS
-- ====================================
Config.Framework = 'qb-core'
Config.Debug = true
Config.Language = 'de'

-- Performance Settings
Config.UpdateInterval = 750
Config.MaxRenderDistance = 150.0
Config.DespawnDistance = 200.0

-- ====================================
-- ZOMBIE MODELS & TYPES
-- ====================================
Config.ZombieModels = {
    'u_m_y_zombie_01',
    'g_m_m_zombie_01',
    'g_m_m_zombie_02',
    'IG_Zombie_DJ_01',
    'G_M_M_Zombie_03',
    'G_M_M_Zombie_05',
    'G_M_M_Zombie_04'
}

Config.ZombieTypes = {
    ['crawler'] = {
        Name = 'Crawler',
        Models = { 'u_m_y_zombie_01', 'g_m_m_zombie_01', 'g_m_m_zombie_02' },
        Health = 200,
        Speed = 1.0,
        Damage = 10,
        AttackRange = 1.5,
        AttackCooldown = 3000,
        MovementClipSet = { 'move_m@drunk@verydrunk', 'move_m@injured' }, -- Mehrere möglich!
        SpawnChance = 50,
        LootTable = 'crawler_loot',
        HeadshotMultiplier = 2.0,
        Color = "^2",
        Sounds = {
            Idle = { 'GENERIC_INSULT_HIGH', 'SPEECH_PARAMS_FORCE' },
            Attack = { 'GENERIC_WAR_CRY', 'SPEECH_PARAMS_FORCE_SHOUTED' }
        }
    },
    ['runner'] = {
        Name = 'Runner',
        Models = { 'IG_Zombie_DJ_01', 'G_M_M_Zombie_03' },
        Health = 150,
        Speed = 1.8,
        Damage = 8,
        AttackRange = 2.0,
        AttackCooldown = 2000,
        MovementClipSet = 'move_m@hurry@a',
        SpawnChance = 25,
        LootTable = 'runner_loot',
        HeadshotMultiplier = 2.5,
        Color = "^3",
        Sounds = {
            Idle = { 'GENERIC_FRIGHTENED_HIGH', 'SPEECH_PARAMS_FORCE' },
            Attack = { 'GENERIC_INSULT_HIGH', 'SPEECH_PARAMS_FORCE_SHOUTED' }
        }
    },
    ['tank'] = {
        Name = 'Tank',
        Models = { 'G_M_M_Zombie_05' },
        Health = 500,
        Speed = 0.7,
        Damage = 20,
        AttackRange = 2.0,
        AttackCooldown = 3500,
        MovementClipSet = { 'move_m@intimidation@1h', 'move_m@tough_guy@' }, -- Mehrere möglich!
        SpawnChance = 15,
        LootTable = 'tank_loot',
        HeadshotMultiplier = 1.5,
        Color = "^1",
        Sounds = {
            Idle = { 'GENERIC_WAR_CRY', 'SPEECH_PARAMS_FORCE' },
            Attack = { 'GENERIC_INSULT_HIGH', 'SPEECH_PARAMS_FORCE_SHOUTED_CLEAR' }
        }
    },
    ['exploder'] = {
        Name = 'Exploder',
        Models = { 'G_M_M_Zombie_04' },
        Health = 100,
        Speed = 1.2,
        Damage = 15,
        AttackRange = 1.8,
        AttackCooldown = 2500,
        MovementClipSet = 'move_m@hurry@a',
        SpawnChance = 10,
        LootTable = 'exploder_loot',
        HeadshotMultiplier = 3.0,
        ExplodeOnDeath = true,
        ExplosionDamage = 50,
        ExplosionRadius = 5.0,
        Color = "^8",
        Sounds = {
            Idle = { 'GENERIC_HOWS_IT_GOING', 'SPEECH_PARAMS_FORCE' },
            Attack = { 'GENERIC_INSULT_MED', 'SPEECH_PARAMS_FORCE_SHOUTED' }
        }
    }
}

-- ====================================
-- AGGRO SYSTEM (From your old script)
-- ====================================
Config.ZombieAggroSettings = {
    -- Schuss-Erkennung
    shootNoiseRange = 150.0,
    shootNoiseChance = 70,

    -- Sicht-Erkennung
    visualRange = 8.0,
    visualRangeNight = 5.0,
    requireLineOfSight = true,

    -- Nähe-Erkennung
    closeRange = 3.0,

    -- Aggro-Verlust
    loseAggroDistance = 40.0,
    loseAggroChance = 80
}

-- ====================================
-- STEALTH & NOISE SYSTEM
-- ====================================
Config.NoiseSystem = {
    Enabled = true,
    ShowBlipOnMap = Config.Debug, -- Nur im Debug-Mode
    BlipColor = 1,
    BlipAlpha = 100,

    Crouching = 2.0,
    Walking = 5.0,
    Running = 25.0,
    Shooting = 60.0,
    ShootingWithSuppressor = 15.0,
    VehicleMultiplier = 0.8,

    ZombieVisionRange = 15.0,
    VisionAngle = 120,
}

-- ====================================
-- ZONE MANAGEMENT
-- ====================================
Config.DefaultZoneSettings = {
    MaxZombies = 10,
    SpawnRadius = 50.0,
    RespawnTime = 30000,
    SpawnInterval = 8000, -- From your config
    MinDistanceFromPlayers = 20.0,
}

-- Danger Level Modifiers (From your old script)
Config.DangerLevelModifiers = {
    low = {
        runnerChance = 0.5,
        tankChance = 0.3,
        exploderChance = 0.2,
        maxZombies = 8
    },
    medium = {
        runnerChance = 1.0,
        tankChance = 1.0,
        exploderChance = 1.0,
        maxZombies = 15
    },
    high = {
        runnerChance = 1.5,
        tankChance = 2.0,
        exploderChance = 1.5,
        maxZombies = 25
    }
}

-- ====================================
-- DAY/NIGHT SYSTEM (From your old script)
-- ====================================
Config.NightSpawnMultiplier = 2.5
Config.NightStartHour = 22
Config.NightEndHour = 6

Config.NightZombieModifier = {
    runnerChance = 1.5,
    tankChance = 1.3,
    exploderChance = 1.2
}

-- ====================================
-- LOOT SYSTEM (NO PROPS!)
-- ====================================
Config.LootTables = {
    ['crawler_loot'] = {
        SearchTime = 4000,
        SearchAnimation = {
            dict = 'amb@medic@standing@kneel@base',
            anim = 'base',
            flags = 1
        },
        Items = {
            { item = 'water_bottle', min = 1, max = 2, chance = 40 },
            { item = 'sandwich',     min = 1, max = 1, chance = 35 },
            { item = 'bandage',      min = 1, max = 2, chance = 30 },
            { item = 'pistol_ammo',  min = 3, max = 8, chance = 15 }
        }
    },
    ['runner_loot'] = {
        SearchTime = 3500,
        SearchAnimation = {
            dict = 'amb@medic@standing@kneel@base',
            anim = 'base',
            flags = 1
        },
        Items = {
            { item = 'water_bottle', min = 1, max = 3,  chance = 50 },
            { item = 'painkillers',  min = 1, max = 2,  chance = 25 },
            { item = 'pistol_ammo',  min = 5, max = 12, chance = 30 },
            { item = 'weapon_knife', min = 1, max = 1,  chance = 10 }
        }
    },
    ['tank_loot'] = {
        SearchTime = 5000,
        SearchAnimation = {
            dict = 'amb@medic@standing@kneel@base',
            anim = 'base',
            flags = 1
        },
        Items = {
            { item = 'bandage',     min = 2,  max = 4,  chance = 60 },
            { item = 'painkillers', min = 1,  max = 2,  chance = 40 },
            { item = 'rifle_ammo',  min = 10, max = 20, chance = 35 },
            { item = 'weapon_bat',  min = 1,  max = 1,  chance = 20 },
            { item = 'armor',       min = 1,  max = 1,  chance = 5 }
        }
    },
    ['exploder_loot'] = {
        SearchTime = 3000,
        SearchAnimation = {
            dict = 'amb@medic@standing@kneel@base',
            anim = 'base',
            flags = 1
        },
        Items = {
            { item = 'pistol_ammo',    min = 10, max = 25, chance = 50 },
            { item = 'rifle_ammo',     min = 8,  max = 15, chance = 40 },
            { item = 'weapon_molotov', min = 1,  max = 2,  chance = 15 },
            { item = 'lockpick',       min = 1,  max = 1,  chance = 10 }
        }
    }
}

-- NO LOOT PROPS!
Config.UseLootProps = false

-- ====================================
-- AMBIENT INFECTION
-- ====================================
Config.AmbientInfection = {
    Enabled = false,
    ConversionRadius = 100.0,
    ConversionChance = 0.15,
    CheckInterval = 10000,
    BlacklistedModels = {
        's_m_y_cop_01',
        's_f_y_cop_01',
        's_m_m_paramedic_01',
        's_m_m_doctor_01',
        'mp_m_freemode_01',
        'mp_f_freemode_01'
    }
}

-- ====================================
-- COMBAT SYSTEM
-- ====================================
Config.Combat = {
    ZombieMeleeDamage = true,
    DamageInterval = 1000,
    HeadshotMultiplier = 2.5,
    KnockbackChance = 25,
    BloodEffect = true,
}

-- ====================================
-- ZOMBIE BEHAVIOR
-- ====================================
Config.ZombieBehavior = {
    WanderEnabled = true,                       -- Zombies laufen rum wenn idle
    WanderInterval = { min = 5000, max = 10000 }, -- ms zwischen Wander
    WanderRadius = { min = 5, max = 20 },       -- Meter Radius
    WanderSpeed = 1.0,                          -- Geschwindigkeit beim Wandern
}

Config.HeadshotBones = {
    31086,
    39317,
    65068
}

-- ====================================
-- KILL TRACKING & REWARDS
-- ====================================
Config.KillTracking = {
    Enabled = true,
    MetaDataKey = 'zombiekills',
    ShowKillNotification = true,
    Rewards = {
        Enabled = false,
        Money = { min = 5, max = 15 },
        MoneyAccount = 'cash',
    }
}

-- ====================================
-- DISCORD INTEGRATION
-- ====================================
Config.Discord = {
    Enabled = true,
    Webhooks = {
        AdminActions = 'YOUR_ADMIN_WEBHOOK_HERE',
        KillLeaderboard = 'YOUR_LEADERBOARD_WEBHOOK_HERE',
    },
    AutoLeaderboard = {
        Enabled = true,
        Interval = 86400000,
    },
    EmbedColor = 15158332,
    BotName = 'D4rk Zombies',
    BotAvatar = 'https://i.imgur.com/YOUR_IMAGE.png'
}

-- ====================================
-- ADMIN PERMISSIONS
-- ====================================
Config.AdminGroups = {
    'god',
    'admin',
    'moderator'
}

-- ====================================
-- UI & INTERACTION
-- ====================================
Config.Interaction = {
    LootLabel = '🧟 Leiche durchsuchen',
    LootIcon = 'fas fa-hand-holding',
    LootDistance = 2.0,
}

-- ====================================
-- OPTIMIZATION
-- ====================================
Config.Optimization = {
    DisableTraffic = true,
    DisableAmbientPeds = true,
    DisableScenarioPeds = true,
    MaxActiveZombies = 60, -- From your config
}

-- ====================================
-- COMMANDS
-- ====================================
Config.Commands = {
    ZoneMenu = 'zombiezone',
    AdminMenu = 'zombieadmin',
    ToggleInfection = 'zombieinfection',
    ResetStats = 'zombiereset',
    AddZonePoint = 'zadd', -- For polygon zones
    SaveZone = 'zsave',    -- For polygon zones
}

-- ====================================
-- ZONE DEBUG VISUALIZATION
-- ====================================
Config.ShowZoneDebug = Config.Debug -- Zeigt Zonen als PolyZone Debug

-- ====================================
-- HORDE EVENT SYSTEM
-- ====================================
Config.HordeSystem = {
    -- Camping Punishment (Spieler bleibt zu lange an Ort)
    CampingPunishment = {
        Enabled = true,
        TimeThreshold = 120,      -- Sekunden (2 Minuten)
        MovementThreshold = 15.0, -- Meter (Spieler muss sich mind. 15m bewegen)
        HordeSize = { min = 8, max = 15 },
        SpawnRadius = 30.0,
    },
    CampingCheckInterval = 10000, -- Check alle 10 Sekunden

    -- Random Events
    RandomEvents = {
        Enabled = true,
        IntervalMin = 1800000, -- Min 30 Minuten
        IntervalMax = 3600000, -- Max 60 Minuten

        Types = {
            { type = 'wandering_horde', chance = 50 }, -- 50% Chance
            { type = 'blood_moon',      chance = 30 }, -- 30% Chance
            { type = 'zone_siege',      chance = 20 }, -- 20% Chance
        }
    }
}

-- ====================================
-- IMPROVED AI CONFIGURATION
-- Füge dies am Ende von config/config.lua hinzu
-- ====================================

Config.ZombieAI = {
    -- Anti-Stuck System
    StuckDetectionEnabled = true,
    StuckThreshold = 10000, -- ms
    MaxUnstuckAttempts = 3,

    -- Group Behavior
    GroupBehaviorEnabled = true,
    MinGroupSize = 3,
    MaxGroupDistance = 20.0, -- Meter

    -- Sprint System
    SprintEnabled = true,
    SprintDistance = { min = 10.0, max = 30.0 }, -- Meter
    SprintSpeedMultiplier = 2.0,

    -- Pathfinding
    SmartPathfindingEnabled = true,
    ShortDistance = 10.0,
    MediumDistance = 50.0,

    -- Obstacles
    BreakThroughObjects = true, -- Zombies schlagen durch Hindernisse
    AlternatePathEnabled = true,

    -- Health-Based Behavior
    LowHealthThreshold = 30,      -- % HP
    CriticalHealthThreshold = 10, -- % HP
    LowHealthSpeedMult = 0.7,
    BerserkSpeedMult = 1.5,
    BerserkDamageMult = 1.5,

    -- Attack Variations
    MultipleAttackAnims = true,
    AttackVariety = 3, -- Anzahl verschiedener Anims pro Typ
}

-- ====================================
-- PARTICLE EFFECTS
-- ====================================

Config.ParticleEffects = {
    BloodOnHit = true,
    DeathExplosion = true, -- Für Exploder
    ObstacleBreak = true,
}

-- ====================================
-- SOUND EFFECTS
-- ====================================

Config.SoundEffects = {
    AttackSounds = true,
    ObstacleSounds = true,
    DeathSounds = true,
}
