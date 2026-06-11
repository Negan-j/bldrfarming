Config.OxItems = {
    farm_apple = {
        label = 'Apple',
        weight = 100,
        stack = true,
        close = false,
        description = 'Freshly picked orchard apple.'
    },
    farm_orange = {
        label = 'Orange',
        weight = 110,
        stack = true,
        close = false,
        description = 'Bright citrus fruit ready for juicing.'
    },
    farm_strawberry = {
        label = 'Strawberry',
        weight = 35,
        stack = true,
        close = false,
        description = 'Small sweet berry from the field.'
    },
    farm_peach = {
        label = 'Peach',
        weight = 120,
        stack = true,
        close = false,
        description = 'Soft ripe peach for premium mixes.'
    },
    farm_pineapple = {
        label = 'Pineapple',
        weight = 450,
        stack = true,
        close = false,
        description = 'Tropical fruit with a sharp crown.'
    },
    farm_dragonfruit = {
        label = 'Dragon Fruit',
        weight = 260,
        stack = true,
        close = false,
        description = 'Rare fruit unlocked by experienced farmers.'
    },
    farm_empty_bottle = {
        label = 'Empty Juice Bottle',
        weight = 40,
        stack = true,
        close = false,
        description = 'Clean bottle for fresh juice.'
    },
    farm_sugar = {
        label = 'Sugar Scoop',
        weight = 20,
        stack = true,
        close = false,
        description = 'A measured scoop of sugar.'
    },
    farm_ice = {
        label = 'Ice Cup',
        weight = 35,
        stack = true,
        close = false,
        description = 'Chilled ice for blended drinks.'
    },
    farm_ruined_mash = {
        label = 'Ruined Fruit Mash',
        weight = 180,
        stack = true,
        close = true,
        description = 'A failed mixture. Someone might still compost it.'
    },
    farm_basket = {
        label = 'Harvest Basket',
        weight = 750,
        stack = false,
        close = true,
        description = 'A sturdy basket that improves fruit yield while carried.'
    },
    farm_gloves = {
        label = 'Farm Gloves',
        weight = 200,
        stack = false,
        close = true,
        description = 'Work gloves that make picking checks easier while carried.'
    },
    farm_shears = {
        label = 'Pruning Shears',
        weight = 450,
        stack = false,
        close = true,
        description = 'Sharp shears that reduce crop cooldowns while carried.'
    },
    farm_apple_juice = {
        label = 'Apple Juice',
        weight = 250,
        stack = true,
        close = true,
        description = 'A sealed bottle of fresh apple juice.',
        client = { event = Config.EventPrefix .. ':client:drinkItem' }
    },
    farm_orange_juice = {
        label = 'Orange Juice',
        weight = 250,
        stack = true,
        close = true,
        description = 'A sealed bottle of fresh orange juice.',
        client = { event = Config.EventPrefix .. ':client:drinkItem' }
    },
    farm_strawberry_blend = {
        label = 'Strawberry Blend',
        weight = 275,
        stack = true,
        close = true,
        description = 'A sweet berry juice blend.',
        client = { event = Config.EventPrefix .. ':client:drinkItem' }
    },
    farm_peach_punch = {
        label = 'Peach Punch',
        weight = 275,
        stack = true,
        close = true,
        description = 'Peach-heavy punch with a bright citrus finish.',
        client = { event = Config.EventPrefix .. ':client:drinkItem' }
    },
    farm_tropical_mix = {
        label = 'Tropical Mix',
        weight = 300,
        stack = true,
        close = true,
        description = 'A cold tropical bottled juice.',
        client = { event = Config.EventPrefix .. ':client:drinkItem' }
    },
    farm_dragon_smoothie = {
        label = 'Dragon Smoothie',
        weight = 320,
        stack = true,
        close = true,
        description = 'Rare smoothie made from high-level fruit.',
        client = { event = Config.EventPrefix .. ':client:drinkItem' }
    },
    farm_orchard_reserve = {
        label = 'Orchard Reserve',
        weight = 330,
        stack = true,
        close = true,
        description = 'Premium reserve juice for trusted farmers.',
        client = { event = Config.EventPrefix .. ':client:drinkItem' }
    },
    farm_negans_special = {
        label = "Negan's Special",
        weight = 350,
        stack = true,
        close = true,
        description = 'A rare signature blend with serious buyer demand.',
        client = { event = Config.EventPrefix .. ':client:drinkItem' }
    }
}

Config.QBItems = {
    farm_apple = { name = 'farm_apple', label = 'Apple', weight = 100, type = 'item', image = 'farm_apple.png', unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Freshly picked orchard apple.' },
    farm_orange = { name = 'farm_orange', label = 'Orange', weight = 110, type = 'item', image = 'farm_orange.png', unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Bright citrus fruit ready for juicing.' },
    farm_strawberry = { name = 'farm_strawberry', label = 'Strawberry', weight = 35, type = 'item', image = 'farm_strawberry.png', unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Small sweet berry from the field.' },
    farm_peach = { name = 'farm_peach', label = 'Peach', weight = 120, type = 'item', image = 'farm_peach.png', unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Soft ripe peach for premium mixes.' },
    farm_pineapple = { name = 'farm_pineapple', label = 'Pineapple', weight = 450, type = 'item', image = 'farm_pineapple.png', unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Tropical fruit with a sharp crown.' },
    farm_dragonfruit = { name = 'farm_dragonfruit', label = 'Dragon Fruit', weight = 260, type = 'item', image = 'farm_dragonfruit.png', unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Rare fruit unlocked by experienced farmers.' },
    farm_empty_bottle = { name = 'farm_empty_bottle', label = 'Empty Juice Bottle', weight = 40, type = 'item', image = 'farm_empty_bottle.png', unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Clean bottle for fresh juice.' },
    farm_sugar = { name = 'farm_sugar', label = 'Sugar Scoop', weight = 20, type = 'item', image = 'farm_sugar.png', unique = false, useable = false, shouldClose = false, combinable = nil, description = 'A measured scoop of sugar.' },
    farm_ice = { name = 'farm_ice', label = 'Ice Cup', weight = 35, type = 'item', image = 'farm_ice.png', unique = false, useable = false, shouldClose = false, combinable = nil, description = 'Chilled ice for blended drinks.' },
    farm_ruined_mash = { name = 'farm_ruined_mash', label = 'Ruined Fruit Mash', weight = 180, type = 'item', image = 'farm_ruined_mash.png', unique = false, useable = false, shouldClose = true, combinable = nil, description = 'A failed mixture. Someone might still compost it.' },
    farm_basket = { name = 'farm_basket', label = 'Harvest Basket', weight = 750, type = 'item', image = 'farm_basket.png', unique = false, useable = false, shouldClose = true, combinable = nil, description = 'A sturdy basket that improves fruit yield while carried.' },
    farm_gloves = { name = 'farm_gloves', label = 'Farm Gloves', weight = 200, type = 'item', image = 'farm_gloves.png', unique = false, useable = false, shouldClose = true, combinable = nil, description = 'Work gloves that make picking checks easier while carried.' },
    farm_shears = { name = 'farm_shears', label = 'Pruning Shears', weight = 450, type = 'item', image = 'farm_shears.png', unique = false, useable = false, shouldClose = true, combinable = nil, description = 'Sharp shears that reduce crop cooldowns while carried.' },
    farm_apple_juice = { name = 'farm_apple_juice', label = 'Apple Juice', weight = 250, type = 'item', image = 'farm_apple_juice.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'A sealed bottle of fresh apple juice.' },
    farm_orange_juice = { name = 'farm_orange_juice', label = 'Orange Juice', weight = 250, type = 'item', image = 'farm_orange_juice.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'A sealed bottle of fresh orange juice.' },
    farm_strawberry_blend = { name = 'farm_strawberry_blend', label = 'Strawberry Blend', weight = 275, type = 'item', image = 'farm_strawberry_blend.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'A sweet berry juice blend.' },
    farm_peach_punch = { name = 'farm_peach_punch', label = 'Peach Punch', weight = 275, type = 'item', image = 'farm_peach_punch.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'Peach-heavy punch with a bright citrus finish.' },
    farm_tropical_mix = { name = 'farm_tropical_mix', label = 'Tropical Mix', weight = 300, type = 'item', image = 'farm_tropical_mix.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'A cold tropical bottled juice.' },
    farm_dragon_smoothie = { name = 'farm_dragon_smoothie', label = 'Dragon Smoothie', weight = 320, type = 'item', image = 'farm_dragon_smoothie.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'Rare smoothie made from high-level fruit.' },
    farm_orchard_reserve = { name = 'farm_orchard_reserve', label = 'Orchard Reserve', weight = 330, type = 'item', image = 'farm_orchard_reserve.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'Premium reserve juice for trusted farmers.' },
    farm_negans_special = { name = 'farm_negans_special', label = "Negan's Special", weight = 350, type = 'item', image = 'farm_negans_special.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'A rare signature blend with serious buyer demand.' }
}
