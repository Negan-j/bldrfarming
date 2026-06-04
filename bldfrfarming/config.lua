Config = {}

Config.Debug = false

Config.Job = {
    enabled = true,
    name = 'farmer',
    grade = 0
}

Config.Target = 'ox_target'

Config.Blips = {
    farm = {
        enabled = true,
        sprite = 439,
        color = 5,
        scale = 0.8,
        label = 'Farm'
    },
    processing = {
        enabled = true,
        sprite = 439,
        color = 17,
        scale = 0.7,
        label = 'Processing Plant'
    },
    selling = {
        enabled = true,
        sprite = 500,
        color = 2,
        scale = 0.7,
        label = 'Farm Sales'
    }
}

Config.Zones = {
    farm = {
        coords = vector3(2430.0, 4974.0, 46.0),
        radius = 30.0,
        marker = {
            type = 1,
            scale = vector3(2.0, 2.0, 1.0),
            color = { r = 50, g = 200, b = 50, a = 100 }
        }
    },
    processing = {
        coords = vector3(2420.0, 4950.0, 46.0),
        radius = 5.0,
        marker = {
            type = 1,
            scale = vector3(3.0, 3.0, 1.0),
            color = { r = 200, g = 200, b = 50, a = 100 }
        }
    },
    selling = {
        coords = vector3(2400.0, 4940.0, 46.0),
        radius = 5.0,
        marker = {
            type = 1,
            scale = vector3(3.0, 3.0, 1.0),
            color = { r = 50, g = 200, b = 200, a = 100 }
        }
    }
}

Config.Crops = {
    wheat = {
        label = 'Wheat',
        item = 'raw_wheat',
        model = 'prop_plant_fern_01a',
        coords = {
            vector3(2425.0, 4980.0, 46.0),
            vector3(2435.0, 4980.0, 46.0),
            vector3(2445.0, 4980.0, 46.0),
            vector3(2425.0, 4970.0, 46.0),
            vector3(2435.0, 4970.0, 46.0),
            vector3(2445.0, 4970.0, 46.0)
        },
        amount = { min = 1, max = 3 },
        timer = 5000,
        respawnTime = 300000
    },
    corn = {
        label = 'Corn',
        item = 'raw_corn',
        model = 'prop_plant_fern_02a',
        coords = {
            vector3(2425.0, 4960.0, 46.0),
            vector3(2435.0, 4960.0, 46.0),
            vector3(2445.0, 4960.0, 46.0),
            vector3(2425.0, 4950.0, 46.0),
            vector3(2435.0, 4950.0, 46.0),
            vector3(2445.0, 4950.0, 46.0)
        },
        amount = { min = 1, max = 2 },
        timer = 6000,
        respawnTime = 360000
    },
    tomato = {
        label = 'Tomato',
        item = 'raw_tomato',
        model = 'prop_plant_fern_03a',
        coords = {
            vector3(2425.0, 4990.0, 46.0),
            vector3(2435.0, 4990.0, 46.0),
            vector3(2445.0, 4990.0, 46.0)
        },
        amount = { min = 2, max = 5 },
        timer = 4000,
        respawnTime = 240000
    }
}

Config.Processing = {
    wheat = {
        input = { item = 'raw_wheat', amount = 5 },
        output = { item = 'flour', amount = 2 },
        timer = 8000,
        label = 'Process Wheat into Flour'
    },
    corn = {
        input = { item = 'raw_corn', amount = 3 },
        output = { item = 'canned_corn', amount = 1 },
        timer = 10000,
        label = 'Can Corn'
    },
    tomato = {
        input = { item = 'raw_tomato', amount = 6 },
        output = { item = 'tomato_sauce', amount = 2 },
        timer = 7000,
        label = 'Make Tomato Sauce'
    }
}

Config.Selling = {
    flour = {
        item = 'flour',
        price = 50,
        label = 'Flour'
    },
    canned_corn = {
        item = 'canned_corn',
        price = 75,
        label = 'Canned Corn'
    },
    tomato_sauce = {
        item = 'tomato_sauce',
        price = 60,
        label = 'Tomato Sauce'
    }
}

Config.Timers = {
    pickCooldown = 2000,
    processCooldown = 3000,
    sellCooldown = 1000
}

Config.MaxProcessAmount = 50

Config.AntiExploit = {
    maxDistance = 10.0,
    maxItemsPerSecond = 10,
    cooldownCheck = true
}
