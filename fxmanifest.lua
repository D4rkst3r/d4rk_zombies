fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'D4rk Development'
description 'Ultimate Modular Zombie Survival System for QBCore'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/*.lua',
    'locale/*.lua'

}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'client/*.lua',
    'modules/client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
    'modules/server/*.lua'
}


dependencies {
    'qb-core',
    'ox_lib',
    'ox_target',
    'PolyZone',
    'd4rk_lib' -- Das hier sorgt dafür, dass d4rk_lib zuerst startet!
}

files {
    'zones.json'
}
