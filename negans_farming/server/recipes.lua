-- Server-only recipe data. Keeping this out of shared scripts prevents clients
-- from reading the correct mixtures without discovering them in game.
Config.Recipes = {
    apple_juice = {
        label = 'Apple Juice',
        item = 'farm_apple_juice',
        level = 1,
        amount = 1,
        xp = 32,
        thirst = 18,
        ingredients = {
            farm_apple = 4,
            farm_sugar = 1
        }
    },
    orange_juice = {
        label = 'Orange Juice',
        item = 'farm_orange_juice',
        level = 2,
        amount = 1,
        xp = 42,
        thirst = 20,
        ingredients = {
            farm_orange = 4,
            farm_ice = 1
        }
    },
    strawberry_blend = {
        label = 'Strawberry Blend',
        item = 'farm_strawberry_blend',
        level = 3,
        amount = 1,
        xp = 58,
        thirst = 24,
        ingredients = {
            farm_strawberry = 5,
            farm_apple = 1,
            farm_sugar = 1,
            farm_ice = 1
        }
    },
    peach_punch = {
        label = 'Peach Punch',
        item = 'farm_peach_punch',
        level = 4,
        amount = 1,
        xp = 78,
        thirst = 28,
        ingredients = {
            farm_peach = 3,
            farm_orange = 1,
            farm_sugar = 2,
            farm_ice = 1
        }
    },
    tropical_mix = {
        label = 'Tropical Mix',
        item = 'farm_tropical_mix',
        level = 5,
        amount = 1,
        xp = 105,
        thirst = 32,
        ingredients = {
            farm_pineapple = 3,
            farm_orange = 1,
            farm_strawberry = 1,
            farm_sugar = 1,
            farm_ice = 2
        }
    },
    dragon_smoothie = {
        label = 'Dragon Smoothie',
        item = 'farm_dragon_smoothie',
        level = 6,
        amount = 1,
        xp = 145,
        thirst = 38,
        ingredients = {
            farm_dragonfruit = 2,
            farm_pineapple = 1,
            farm_strawberry = 2,
            farm_sugar = 2,
            farm_ice = 2
        }
    },
    orchard_reserve = {
        label = 'Orchard Reserve',
        item = 'farm_orchard_reserve',
        level = 5,
        requiredTier = 3,
        rare = true,
        amount = 1,
        xp = 180,
        thirst = 42,
        ingredients = {
            farm_peach = 2,
            farm_pineapple = 2,
            farm_apple = 2,
            farm_sugar = 2,
            farm_ice = 2
        }
    },
    negans_special = {
        label = "Negan's Special",
        item = 'farm_negans_special',
        level = 6,
        requiredTier = 4,
        rare = true,
        amount = 1,
        xp = 260,
        thirst = 50,
        ingredients = {
            farm_dragonfruit = 3,
            farm_pineapple = 2,
            farm_peach = 1,
            farm_strawberry = 2,
            farm_sugar = 3,
            farm_ice = 3
        }
    }
}
