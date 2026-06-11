fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Codex'
description "Negan's QBCore fruit farming, hidden juice recipes, XP unlocks, ox_lib UI, ox_inventory support"
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/items.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/recipes.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_inventory'
}

escrow_ignore {
    'shared/config.lua',
    'shared/items.lua',
    'README.md',
    'sql/install.sql',
    'data/custom_trees.json',
    'install/ox_inventory_items.lua',
    'install/qb_core_items.lua',
    'install/OX_INVENTORY_INSTALL.md'
}
