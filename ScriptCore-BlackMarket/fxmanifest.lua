fx_version 'cerulean'
game 'gta5'

name 'ScriptCore-BlackMarket'
author 'ScriptCore.dk'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory'
}
