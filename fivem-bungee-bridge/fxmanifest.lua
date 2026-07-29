fx_version 'cerulean'
game 'gta5'

author 'TMG_Manic'
description 'Virtualized Master Gateway Bridge'
version '1.0.0'

shared_script 'config.lua'

dependencies {
    'oxmysql'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/app.js'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/bridge.lua',
    'server/commands.lua',
    'server/social.lua',
    'server/watchdog.lua' -- Watchdog initialized
}

client_scripts {
    'client/bridge.lua'
}