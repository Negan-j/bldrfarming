-- Paste these entries inside ox_inventory/data/items.lua.
-- Keep the drink client events so ox_inventory item use calls negans_farming.

['farm_apple'] = {
    label = 'Apple',
    weight = 100,
    stack = true,
    close = false,
    description = 'Freshly picked orchard apple.'
},

['farm_orange'] = {
    label = 'Orange',
    weight = 110,
    stack = true,
    close = false,
    description = 'Bright citrus fruit ready for juicing.'
},

['farm_strawberry'] = {
    label = 'Strawberry',
    weight = 35,
    stack = true,
    close = false,
    description = 'Small sweet berry from the field.'
},

['farm_peach'] = {
    label = 'Peach',
    weight = 120,
    stack = true,
    close = false,
    description = 'Soft ripe peach for premium mixes.'
},

['farm_pineapple'] = {
    label = 'Pineapple',
    weight = 450,
    stack = true,
    close = false,
    description = 'Tropical fruit with a sharp crown.'
},

['farm_dragonfruit'] = {
    label = 'Dragon Fruit',
    weight = 260,
    stack = true,
    close = false,
    description = 'Rare fruit unlocked by experienced farmers.'
},

['farm_empty_bottle'] = {
    label = 'Empty Juice Bottle',
    weight = 40,
    stack = true,
    close = false,
    description = 'Clean bottle for fresh juice.'
},

['farm_sugar'] = {
    label = 'Sugar Scoop',
    weight = 20,
    stack = true,
    close = false,
    description = 'A measured scoop of sugar.'
},

['farm_ice'] = {
    label = 'Ice Cup',
    weight = 35,
    stack = true,
    close = false,
    description = 'Chilled ice for blended drinks.'
},

['farm_ruined_mash'] = {
    label = 'Ruined Fruit Mash',
    weight = 180,
    stack = true,
    close = true,
    description = 'A failed mixture. Someone might still compost it.'
},

['farm_basket'] = {
    label = 'Harvest Basket',
    weight = 750,
    stack = false,
    close = true,
    description = 'A sturdy basket that improves fruit yield while carried.'
},

['farm_gloves'] = {
    label = 'Farm Gloves',
    weight = 200,
    stack = false,
    close = true,
    description = 'Work gloves that make picking checks easier while carried.'
},

['farm_shears'] = {
    label = 'Pruning Shears',
    weight = 450,
    stack = false,
    close = true,
    description = 'Sharp shears that reduce crop cooldowns while carried.'
},

['farm_apple_juice'] = {
    label = 'Apple Juice',
    weight = 250,
    stack = true,
    close = true,
    description = 'A sealed bottle of fresh apple juice.',
    client = { event = 'negans_farming:client:drinkItem' }
},

['farm_orange_juice'] = {
    label = 'Orange Juice',
    weight = 250,
    stack = true,
    close = true,
    description = 'A sealed bottle of fresh orange juice.',
    client = { event = 'negans_farming:client:drinkItem' }
},

['farm_strawberry_blend'] = {
    label = 'Strawberry Blend',
    weight = 275,
    stack = true,
    close = true,
    description = 'A sweet berry juice blend.',
    client = { event = 'negans_farming:client:drinkItem' }
},

['farm_peach_punch'] = {
    label = 'Peach Punch',
    weight = 275,
    stack = true,
    close = true,
    description = 'Peach-heavy punch with a bright citrus finish.',
    client = { event = 'negans_farming:client:drinkItem' }
},

['farm_tropical_mix'] = {
    label = 'Tropical Mix',
    weight = 300,
    stack = true,
    close = true,
    description = 'A cold tropical bottled juice.',
    client = { event = 'negans_farming:client:drinkItem' }
},

['farm_dragon_smoothie'] = {
    label = 'Dragon Smoothie',
    weight = 320,
    stack = true,
    close = true,
    description = 'Rare smoothie made from high-level fruit.',
    client = { event = 'negans_farming:client:drinkItem' }
},

['farm_orchard_reserve'] = {
    label = 'Orchard Reserve',
    weight = 330,
    stack = true,
    close = true,
    description = 'Premium reserve juice for trusted farmers.',
    client = { event = 'negans_farming:client:drinkItem' }
},

['farm_negans_special'] = {
    label = "Negan's Special",
    weight = 350,
    stack = true,
    close = true,
    description = 'A rare signature blend with serious buyer demand.',
    client = { event = 'negans_farming:client:drinkItem' }
},
