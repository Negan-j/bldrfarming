fx_version 'cerulean'
game 'gta5'

author 'Farming Job'
description 'QBCore Farming Job with custom NUI'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'web/build/index.html'

files {
    'web/build/**/*'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_inventory',
    'oxmysql'
}

provide 'qb-farming'
