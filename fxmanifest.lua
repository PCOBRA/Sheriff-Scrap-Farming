fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Pin Cobra'
description 'OX_LIB và OX_INVENVENTORY'
version '1.0.0'

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

dependencies {
    'ox_lib',
    'ox_inventory',
    'es_extended',
    'ox_target' -- Thêm ox_target
}