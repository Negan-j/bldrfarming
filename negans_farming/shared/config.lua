Config = Config or {}

Config.Debug = false
Config.EventPrefix = 'negans_farming'

-- ox_inventory is the intended inventory for this package.
-- Change to 'auto' only if you want fallback support for qb-inventory/QBCore functions.
Config.Inventory = 'ox_inventory'

-- auto = ox_target when started, otherwise qb-target.
Config.Target = 'auto'

Config.RegisterMissingQBCoreItems = true

Config.SQL = {
    AutoCreate = true
}

Config.SkillInputs = { 'w', 'a', 's', 'd' }

Config.Levels = {
    [1] = 0,
    [2] = 120,
    [3] = 320,
    [4] = 680,
    [5] = 1150,
    [6] = 1800
}

Config.Reputation = {
    SellRepPerItem = 2,
    CraftRep = 3,
    DailyOrderRepPerItem = 4,
    Tiers = {
        { level = 1, label = 'Roadside Seller', required = 0, priceMultiplier = 0.00 },
        { level = 2, label = 'Market Regular', required = 180, priceMultiplier = 0.05 },
        { level = 3, label = 'Orchard Favorite', required = 475, priceMultiplier = 0.10 },
        { level = 4, label = 'Juice Baron', required = 950, priceMultiplier = 0.16 }
    }
}

Config.Tools = {
    farm_basket = {
        label = 'Harvest Basket',
        description = '+1 fruit yield while picking.',
        yieldBonus = 1
    },
    farm_gloves = {
        label = 'Farm Gloves',
        description = 'Easier picking skill checks.',
        skillEase = 1
    },
    farm_shears = {
        label = 'Pruning Shears',
        description = 'Shorter crop cooldowns and faster picking.',
        cooldownMultiplier = 0.75,
        durationMultiplier = 0.85
    }
}

Config.Orders = {
    Enabled = true,
    MaxActive = 3,
    RotateHourUTC = 6,
    Amount = { min = 4, max = 9 },
    BonusMultiplier = { min = 1.20, max = 1.45 },
    AllowRareRecipes = true
}

Config.Admin = {
    Permission = 'admin',
    Commands = {
        SetXP = 'farming_setxp',
        AddXP = 'farming_addxp',
        SetRep = 'farming_setrep',
        AddRep = 'farming_addrep',
        ResetRecipes = 'farming_resetrecipes',
        TestSick = 'farming_testsick',
        AddTree = 'farming_addtree',
        RemoveTree = 'farming_removetree',
        ListTrees = 'farming_trees',
        RefreshTrees = 'farming_refreshtrees'
    }
}

Config.TreeEditor = {
    Enabled = true,
    SaveFile = 'data/custom_trees.json',
    AddHeightOffset = 0.0
}

Config.SearchableTrees = {
    Enabled = true,
    Distance = 2.4,
    CooldownGridSize = 2.0,
    Label = 'Search %s',
    Models = {
        apple = {
            'prop_tree_oak_01',
            'prop_tree_eng_oak_01',
            'prop_tree_maple_02',
            'prop_tree_birch_03',
            'prop_tree_birch_05'
        },
        orange = {
            'prop_tree_cedar_02',
            'prop_tree_cedar_03',
            'prop_tree_cedar_04',
            'prop_tree_olive_01'
        },
        strawberry = {
            'prop_veg_crop_03_cab',
            'prop_plant_group_04',
            'prop_plant_int_02a'
        },
        peach = {
            'prop_tree_jacada_01',
            'prop_tree_jacada_02',
            'prop_tree_lficus_02',
            'prop_tree_lficus_03'
        },
        pineapple = {
            'prop_plant_group_04',
            'prop_plant_group_05',
            'prop_plant_int_02a'
        },
        dragonfruit = {
            'prop_plant_int_02a',
            'prop_plant_int_04a',
            'prop_plant_group_05'
        }
    }
}

Config.FruitOrder = {
    'apple',
    'orange',
    'strawberry',
    'peach',
    'pineapple',
    'dragonfruit'
}

Config.Picking = {
    CooldownSeconds = 35,
    Distance = 2.2,
    CreateBlips = true,
    -- Keep this false if you want to use real map trees or trees you place with a mapper/YMAP.
    -- Harvest targets will still be created at configured and custom tree coordinates.
    SpawnNodeProps = false,
    Progress = {
        durationMin = 4500,
        durationMax = 6500,
        label = 'Picking fruit',
        position = 'bottom',
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        }
    },
    Animation = {
        dict = 'amb@prop_human_movie_bulb@idle_a',
        clip = 'idle_a',
        flag = 49
    },
    Prop = {
        model = 'prop_fruit_basket',
        bone = 57005,
        pos = vec3(0.12, 0.02, -0.02),
        rot = vec3(-85.0, 10.0, 20.0)
    }
}

Config.Fruits = {
    apple = {
        label = 'Apples',
        item = 'farm_apple',
        minLevel = 1,
        harvest = { min = 2, max = 4 },
        xp = 9,
        skillCheck = { 'easy', 'easy' },
        nodeProp = 'prop_tree_oak_01',
        blip = { sprite = 85, color = 25, scale = 0.55 },
        zones = {
            { coords = vec3(2344.51, 5007.94, 41.68), heading = 235.67 },
            { coords = vec3(2330.34, 5021.84, 41.86), heading = 235.67 },
            { coords = vec3(2329.36, 5037.11, 43.45), heading = 5.77 }
        }
    },
    orange = {
        label = 'Oranges',
        item = 'farm_orange',
        minLevel = 2,
        harvest = { min = 2, max = 4 },
        xp = 12,
        skillCheck = { 'easy', 'medium' },
        nodeProp = 'prop_tree_cedar_03',
        blip = { sprite = 85, color = 17, scale = 0.55 },
        zones = {
            { coords = vec3(2316.51, 5023.64, 42.29), heading = 27.41 },
            { coords = vec3(2341.84, 5035.00, 43.33), heading = 344.28 },
            { coords = vec3(2357.20, 5020.55, 42.76), heading = 306.92 }
        }
    },
    strawberry = {
        label = 'Strawberries',
        item = 'farm_strawberry',
        minLevel = 3,
        harvest = { min = 4, max = 7 },
        xp = 8,
        skillCheck = { 'easy', 'medium', 'medium' },
        nodeProp = 'h4_prop_bush_bgnvla_med_01',
        blip = { sprite = 85, color = 1, scale = 0.55 },
        zones = {
            { coords = vec3(1849.72, 5026.29, 53.35), heading = 40.35 },
            { coords = vec3(1813.17, 5012.69, 54.88), heading = 40.20 },
            { coords = vec3(1924.00, 5098.17, 41.05), heading = 40.35 }
        }
    },
    peach = {
        label = 'Peaches',
        item = 'farm_peach',
        minLevel = 4,
        harvest = { min = 2, max = 4 },
        xp = 17,
        skillCheck = { 'medium', 'medium', 'hard' },
        nodeProp = 'prop_tree_jacada_01',
        blip = { sprite = 85, color = 8, scale = 0.55 },
        zones = {
            { coords = vec3(1932.04, 4818.50, 43.44), heading = 316.05 },
            { coords = vec3(1927.27, 4810.60, 43.43), heading = 124.21 },
            { coords = vec3(1919.01, 4805.60, 43.00), heading = 312.04 }
        }
    },
    pineapple = {
        label = 'Pineapples',
        item = 'farm_pineapple',
        minLevel = 5,
        harvest = { min = 1, max = 3 },
        xp = 25,
        skillCheck = { 'medium', 'hard', 'hard' },
        nodeProp = 'prop_plant_group_04',
        blip = { sprite = 85, color = 46, scale = 0.55 },
        zones = {
            { coords = vec3(1889.55, 4863.35, 45.16), heading = 0.0 },
            { coords = vec3(1896.16, 4871.36, 45.24), heading = 40.0 },
            { coords = vec3(1906.63, 4864.42, 45.34), heading = 90.0 }
        }
    },
    dragonfruit = {
        label = 'Dragon Fruit',
        item = 'farm_dragonfruit',
        minLevel = 6,
        harvest = { min = 1, max = 2 },
        xp = 38,
        skillCheck = { 'hard', 'hard', { areaSize = 22, speedMultiplier = 1.9 } },
        nodeProp = 'prop_plant_int_02a',
        blip = { sprite = 85, color = 27, scale = 0.55 },
        zones = {
            { coords = vec3(2522.64, 4357.44, 39.63), heading = 15.0 },
            { coords = vec3(2530.92, 4360.68, 39.62), heading = 55.0 },
            { coords = vec3(2537.45, 4350.21, 39.63), heading = 115.0 }
        }
    }
}

Config.Production = {
    MaxPerIngredient = 8,
    RequireBottle = true,
    BottleItem = 'farm_empty_bottle',
    ConsumeWrongMixtures = true,
    WrongMixtureConsumeRatio = 0.5,
    WrongMixtureReturn = { item = 'farm_ruined_mash', min = 1, max = 1 },
    SkillCheck = { 'easy', 'medium', 'medium' },
    Progress = {
        duration = 9000,
        label = 'Pressing juice',
        position = 'bottom',
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'amb@prop_human_bbq@male@idle_a',
            clip = 'idle_b',
            flag = 49
        },
        prop = {
            {
                model = 'prop_cs_bottle_opener',
                bone = 57005,
                pos = vec3(0.12, 0.02, -0.01),
                rot = vec3(-85.0, 0.0, 15.0)
            },
            {
                model = 'prop_cs_bowl_01',
                bone = 18905,
                pos = vec3(0.12, 0.04, 0.02),
                rot = vec3(20.0, 10.0, 80.0)
            }
        }
    },
    Stations = {
        {
            id = 'grapeseed_press',
            label = 'Grapeseed Juice Press',
            coords = vec3(1964.31, 5179.18, 47.94),
            heading = 270.0,
            size = vec3(2.3, 2.0, 2.0),
            prop = {
                model = 'prop_bar_fridge_03',
                coords = vec3(1964.84, 5179.21, 46.90),
                heading = 270.0
            },
            blip = { sprite = 499, color = 2, scale = 0.65 }
        }
    }
}

Config.Supplies = {
    Enabled = true,
    UseOxShop = true,
    ShopId = 'NegansFarmingSupplies',
    Label = 'Orchard Supplies',
    Items = {
        { name = 'farm_empty_bottle', price = 4 },
        { name = 'farm_sugar', price = 3 },
        { name = 'farm_ice', price = 2 },
        { name = 'farm_basket', price = 185 },
        { name = 'farm_gloves', price = 145 },
        { name = 'farm_shears', price = 260 }
    }
}

Config.Seller = {
    Account = 'cash',
    Distance = 3.0,
    SellXPPerItem = 4,
    SkillBonus = 0.12,
    SkillCheck = { 'easy', 'medium' },
    Ped = {
        model = 's_m_m_autoshop_01',
        coords = vec4(1695.84, 4923.27, 42.06, 324.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD'
    },
    Blip = { sprite = 605, color = 2, scale = 0.7, label = 'Fresh Juice Buyer' },
    Progress = {
        duration = 5000,
        label = 'Selling produce',
        position = 'bottom',
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a',
            flag = 49
        },
        prop = {
            model = 'prop_notepad_01',
            bone = 18905,
            pos = vec3(0.11, 0.02, 0.05),
            rot = vec3(10.0, 0.0, 0.0)
        }
    },
    Prices = {
        farm_apple = 5,
        farm_orange = 7,
        farm_strawberry = 4,
        farm_peach = 11,
        farm_pineapple = 16,
        farm_dragonfruit = 28,
        farm_apple_juice = 65,
        farm_orange_juice = 78,
        farm_strawberry_blend = 105,
        farm_peach_punch = 138,
        farm_tropical_mix = 185,
        farm_dragon_smoothie = 260,
        farm_orchard_reserve = 360,
        farm_negans_special = 520
    }
}

Config.Tutorial = {
    Enabled = true,
    AutoPrompt = false,
    Command = 'farmingtutorial',
    Keybind = '',
    Steps = {
        {
            title = '1. Check The Journal',
            description = 'Open the farming journal to see your XP, reputation, daily buyer orders, tools, locked fruit, and discovered recipes.',
            icon = 'clipboard-list',
            coords = vec3(1695.84, 4923.27, 42.06),
            button = 'Open Journal'
        },
        {
            title = '2. Buy Supplies',
            description = 'Go to the juice press and buy empty bottles, sugar, ice, and optional farm tools. Bottles are required for finished drinks.',
            icon = 'basket-shopping',
            coords = vec3(1964.31, 5179.18, 47.94)
        },
        {
            title = '3. Pick Fruit',
            description = 'Use third eye on visible fruit spots. New fruit spots are hidden until your farming level is high enough.',
            icon = 'hand',
            coords = vec3(2342.77, 5006.78, 42.73)
        },
        {
            title = '4. Make Juice',
            description = 'At the press, experiment with fruit, sugar, and ice. Correct mixtures unlock saved recipes; wrong mixtures ruin part of the batch.',
            icon = 'flask',
            coords = vec3(1964.31, 5179.18, 47.94)
        },
        {
            title = '5. Sell Orders',
            description = 'Sell fruit and drinks to the buyer. Daily orders pay bonus money until your personal order amount is complete.',
            icon = 'cash-register',
            coords = vec3(1695.84, 4923.27, 42.06)
        },
        {
            title = '6. Build Reputation',
            description = 'Crafting and selling raises reputation. Higher tiers increase prices and unlock rare recipes.',
            icon = 'star',
            coords = vec3(1695.84, 4923.27, 42.06)
        }
    }
}

Config.Drinks = {
    WindowSeconds = 600,
    MaxSafeDrinks = 3,
    SickDuration = 45000,
    SickDurationPerExtra = 12000,
    DamagePerExtraDrink = 4,
    RagdollChance = 30,
    Progress = {
        duration = 3500,
        label = 'Drinking juice',
        position = 'bottom',
        canCancel = false,
        disable = {
            car = true,
            combat = true
        },
        anim = {
            dict = 'mp_player_intdrink',
            clip = 'loop_bottle',
            flag = 49
        },
        prop = {
            model = 'prop_ld_flow_bottle',
            bone = 18905,
            pos = vec3(0.12, 0.02, 0.03),
            rot = vec3(240.0, -60.0, 0.0)
        }
    }
}
