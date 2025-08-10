fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'RSG Taxi System'
version '1.0.0'
author  'phil'
shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
    --'rsg-target',
    'ox_target'
}

lua54 'yes'