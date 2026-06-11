local QBCore = exports['qb-core']:GetCoreObject()
local EventPrefix = Config.EventPrefix

local PlayerCache = {}
local DrinkLogs = {}
local CustomTrees = {}
local DailyOrders = {
    stamp = nil,
    orders = {}
}
local RecipeByItem = {}
local FruitByItem = {}
local AllowedMixtureItems = {
    farm_sugar = true,
    farm_ice = true
}

for fruitKey, fruit in pairs(Config.Fruits) do
    FruitByItem[fruit.item] = fruitKey
    AllowedMixtureItems[fruit.item] = true
end

for recipeKey, recipe in pairs(Config.Recipes) do
    RecipeByItem[recipe.item] = recipeKey
end

local function vecToTable(coords)
    return {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }
end

local function tableToVec(coords)
    return vec3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
end

local function modelHash(model)
    if type(model) == 'number' then return model end
    if type(model) ~= 'string' then return nil end
    if joaat then return joaat(model) end
    return GetHashKey(model)
end

local function isSearchableTreeModel(fruitKey, model)
    if not Config.SearchableTrees or not Config.SearchableTrees.Enabled then return false end

    local models = Config.SearchableTrees.Models[fruitKey]
    if not models then return false end

    local targetHash = tonumber(model)
    if not targetHash then return false end

    for _, configuredModel in ipairs(models) do
        if modelHash(configuredModel) == targetHash then
            return true
        end
    end

    return false
end

local function roundedWorldTreeKey(fruitKey, coords)
    local grid = Config.SearchableTrees and Config.SearchableTrees.CooldownGridSize or 2.0
    grid = grid > 0 and grid or 2.0

    local x = math.floor((coords.x / grid) + 0.5)
    local y = math.floor((coords.y / grid) + 0.5)
    local z = math.floor((coords.z / grid) + 0.5)
    return ('world:%s:%s:%s:%s'):format(fruitKey, x, y, z)
end

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

local function inventoryMode()
    if Config.Inventory ~= 'auto' then return Config.Inventory end
    if resourceStarted('ox_inventory') then return 'ox_inventory' end
    if resourceStarted('qb-inventory') then return 'qb-inventory' end
    return 'qb'
end

local function notify(src, data)
    TriggerClientEvent('ox_lib:notify', src, data)
end

local function hasAdminPermission(src)
    if src == 0 then return true end
    if QBCore.Functions.HasPermission then
        return QBCore.Functions.HasPermission(src, Config.Admin.Permission or 'admin')
    end

    return IsPlayerAceAllowed(src, 'command')
end

local function itemLabel(itemName)
    if QBCore.Shared.Items[itemName] and QBCore.Shared.Items[itemName].label then
        return QBCore.Shared.Items[itemName].label
    end

    if Config.OxItems[itemName] and Config.OxItems[itemName].label then
        return Config.OxItems[itemName].label
    end

    for _, fruit in pairs(Config.Fruits) do
        if fruit.item == itemName then return fruit.label end
    end

    for _, recipe in pairs(Config.Recipes) do
        if recipe.item == itemName then return recipe.label end
    end

    return itemName
end

local function loadCustomTrees()
    CustomTrees = {}

    if not Config.TreeEditor.Enabled then return end

    local raw = LoadResourceFile(GetCurrentResourceName(), Config.TreeEditor.SaveFile)
    if not raw or raw == '' then
        SaveResourceFile(GetCurrentResourceName(), Config.TreeEditor.SaveFile, '[]', -1)
        return
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        print(('[%s] Could not decode %s, using an empty custom tree list.'):format(GetCurrentResourceName(), Config.TreeEditor.SaveFile))
        CustomTrees = {}
        return
    end

    for _, tree in ipairs(decoded) do
        if tree.id and tree.fruit and tree.coords and Config.Fruits[tree.fruit] then
            CustomTrees[#CustomTrees + 1] = {
                id = tostring(tree.id),
                fruit = tree.fruit,
                coords = {
                    x = tonumber(tree.coords.x) or 0.0,
                    y = tonumber(tree.coords.y) or 0.0,
                    z = tonumber(tree.coords.z) or 0.0
                },
                heading = tonumber(tree.heading) or 0.0,
                label = tree.label,
                createdBy = tree.createdBy,
                createdAt = tree.createdAt
            }
        end
    end
end

local function saveCustomTrees()
    SaveResourceFile(GetCurrentResourceName(), Config.TreeEditor.SaveFile, json.encode(CustomTrees), -1)
end

local function getCustomTreeById(id)
    id = tostring(id)
    for index, tree in ipairs(CustomTrees) do
        if tree.id == id then
            return tree, index
        end
    end

    return nil
end

local function getCustomTreesGrouped()
    local grouped = {}

    for _, fruitKey in ipairs(Config.FruitOrder) do
        grouped[fruitKey] = {}
    end

    for _, tree in ipairs(CustomTrees) do
        grouped[tree.fruit] = grouped[tree.fruit] or {}
        grouped[tree.fruit][#grouped[tree.fruit] + 1] = {
            id = tree.id,
            fruit = tree.fruit,
            coords = tree.coords,
            heading = tree.heading,
            label = tree.label,
            custom = true
        }
    end

    return grouped
end

local Inventory = {}

function Inventory.Count(src, itemName)
    local mode = inventoryMode()
    if mode == 'ox_inventory' then
        return exports.ox_inventory:Search(src, 'count', itemName) or 0
    end

    if mode == 'qb-inventory' then
        local ok, count = pcall(function()
            return exports['qb-inventory']:GetItemCount(src, itemName)
        end)
        if ok and count then return count end
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return 0 end

    local item = Player.Functions.GetItemByName(itemName)
    return item and item.amount or 0
end

function Inventory.CanCarry(src, itemName, amount)
    local mode = inventoryMode()
    if mode == 'ox_inventory' then
        return exports.ox_inventory:CanCarryItem(src, itemName, amount)
    end

    if mode == 'qb-inventory' then
        local ok, canCarry = pcall(function()
            return exports['qb-inventory']:CanAddItem(src, itemName, amount)
        end)
        if ok then return canCarry end
    end

    return true
end

function Inventory.AddItem(src, itemName, amount, metadata)
    local mode = inventoryMode()
    if mode == 'ox_inventory' then
        return exports.ox_inventory:AddItem(src, itemName, amount, metadata)
    end

    if mode == 'qb-inventory' then
        local ok, added = pcall(function()
            return exports['qb-inventory']:AddItem(src, itemName, amount, false, metadata, EventPrefix)
        end)
        if ok then return added end
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local added = Player.Functions.AddItem(itemName, amount, false, metadata)
    if added and QBCore.Shared.Items[itemName] then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add', amount)
    end
    return added
end

function Inventory.RemoveItem(src, itemName, amount, slot)
    local mode = inventoryMode()
    if mode == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(src, itemName, amount, nil, slot)
    end

    if mode == 'qb-inventory' then
        local ok, removed = pcall(function()
            return exports['qb-inventory']:RemoveItem(src, itemName, amount, slot, EventPrefix)
        end)
        if ok then return removed end
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local removed = Player.Functions.RemoveItem(itemName, amount, slot)
    if removed and QBCore.Shared.Items[itemName] then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove', amount)
    end
    return removed
end

local function getIdentifier(src)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player and Player.PlayerData and Player.PlayerData.citizenid
end

local function getLevelFromXP(xp)
    local level = 1
    for lvl, required in pairs(Config.Levels) do
        if xp >= required and lvl > level then
            level = lvl
        end
    end
    return level
end

local function getNextLevelXP(level)
    local nextLevel = level + 1
    return Config.Levels[nextLevel]
end

local function getReputationTier(reputation)
    local current = Config.Reputation.Tiers[1]

    for _, tier in ipairs(Config.Reputation.Tiers) do
        if reputation >= tier.required then
            current = tier
        end
    end

    return current
end

local function getNextReputationTier(reputation)
    for _, tier in ipairs(Config.Reputation.Tiers) do
        if reputation < tier.required then
            return tier
        end
    end

    return nil
end

local function createTables()
    if not Config.SQL.AutoCreate then return end

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `negans_farming_xp` (
            `citizenid` varchar(64) NOT NULL,
            `xp` int(11) NOT NULL DEFAULT 0,
            `reputation` int(11) NOT NULL DEFAULT 0,
            `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    pcall(function()
        MySQL.query.await('ALTER TABLE `negans_farming_xp` ADD COLUMN `reputation` int(11) NOT NULL DEFAULT 0')
    end)

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `negans_farming_recipes` (
            `citizenid` varchar(64) NOT NULL,
            `recipe` varchar(64) NOT NULL,
            `discovered_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`citizenid`, `recipe`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `negans_farming_order_progress` (
            `citizenid` varchar(64) NOT NULL,
            `order_key` varchar(96) NOT NULL,
            `sold` int(11) NOT NULL DEFAULT 0,
            `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`citizenid`, `order_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function loadDiscovered(citizenid)
    local discovered = {}
    local rows = MySQL.query.await('SELECT recipe FROM negans_farming_recipes WHERE citizenid = ?', { citizenid }) or {}
    for _, row in ipairs(rows) do
        discovered[row.recipe] = true
    end
    return discovered
end

local function ensurePlayer(src)
    if PlayerCache[src] then return PlayerCache[src] end

    local citizenid = getIdentifier(src)
    if not citizenid then
        return { xp = 0, level = 1, reputation = 0, tier = getReputationTier(0), discovered = {}, lastPick = {} }
    end

    local row = MySQL.single.await('SELECT xp, reputation FROM negans_farming_xp WHERE citizenid = ?', { citizenid })
    local xp = row and tonumber(row.xp) or 0
    local reputation = row and tonumber(row.reputation) or 0

    if not row then
        MySQL.insert.await('INSERT INTO negans_farming_xp (citizenid, xp, reputation) VALUES (?, ?, ?)', { citizenid, xp, reputation })
    end

    PlayerCache[src] = {
        citizenid = citizenid,
        xp = xp,
        level = getLevelFromXP(xp),
        reputation = reputation,
        tier = getReputationTier(reputation),
        discovered = loadDiscovered(citizenid),
        lastPick = {}
    }

    return PlayerCache[src]
end

local function savePlayer(src)
    local data = PlayerCache[src]
    if not data or not data.citizenid then return end

    MySQL.update.await('UPDATE negans_farming_xp SET xp = ?, reputation = ? WHERE citizenid = ?', {
        data.xp,
        data.reputation,
        data.citizenid
    })
end

local function addXP(src, amount, reason)
    if not amount or amount <= 0 then return nil end

    local data = ensurePlayer(src)
    local oldLevel = data.level
    data.xp = data.xp + amount
    data.level = getLevelFromXP(data.xp)
    savePlayer(src)

    TriggerClientEvent(EventPrefix .. ':client:xpUpdated', src, {
        xp = data.xp,
        level = data.level,
        oldLevel = oldLevel,
        reputation = data.reputation,
        tier = data.tier,
        amount = amount,
        reason = reason
    })

    return oldLevel, data.level
end

local function syncProgress(src, amount, reason)
    local data = ensurePlayer(src)
    TriggerClientEvent(EventPrefix .. ':client:xpUpdated', src, {
        xp = data.xp,
        level = data.level,
        reputation = data.reputation,
        tier = data.tier,
        amount = amount or 0,
        reason = reason
    })
end

local function addReputation(src, amount, reason)
    if not amount or amount <= 0 then return nil end

    local data = ensurePlayer(src)
    local oldTier = data.tier.level
    data.reputation = data.reputation + amount
    data.tier = getReputationTier(data.reputation)
    savePlayer(src)
    syncProgress(src, 0, reason)

    if data.tier.level > oldTier then
        notify(src, {
            type = 'success',
            title = 'Farming Reputation',
            description = ('New reputation tier: %s.'):format(data.tier.label)
        })
    end

    return oldTier, data.tier.level
end

local function isNear(src, coords, distance)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - coords) <= distance
end

local function getHarvestZone(fruitKey, zoneRef)
    local fruit = Config.Fruits[fruitKey]
    if not fruit then return nil end

    if type(zoneRef) == 'table' and zoneRef.type == 'world' then
        local coords = zoneRef.coords
        local model = tonumber(zoneRef.model)
        if type(coords) ~= 'table' or not model then return nil end
        if not isSearchableTreeModel(fruitKey, model) then return nil end

        local treeCoords = tableToVec(coords)
        return {
            coords = treeCoords,
            heading = 0.0,
            world = true,
            model = model
        }, roundedWorldTreeKey(fruitKey, treeCoords)
    end

    local staticIndex = tonumber(zoneRef)
    if staticIndex and fruit.zones[staticIndex] then
        return fruit.zones[staticIndex], ('static:%s:%s'):format(fruitKey, staticIndex)
    end

    local tree = getCustomTreeById(zoneRef)
    if tree and tree.fruit == fruitKey then
        return {
            coords = tableToVec(tree.coords),
            heading = tree.heading,
            label = tree.label,
            custom = true
        }, ('custom:%s'):format(tree.id)
    end

    return nil
end

local function isNearFruitZone(src, fruitKey, zoneRef)
    local zone = getHarvestZone(fruitKey, zoneRef)
    if not zone then return false end

    return isNear(src, zone.coords, (Config.Picking.Distance or 2.0) + 3.0)
end

local function isNearStation(src, stationId)
    for _, station in ipairs(Config.Production.Stations) do
        if station.id == stationId then
            return isNear(src, station.coords, 4.0), station
        end
    end

    return false
end

local function isNearSeller(src)
    local coords = Config.Seller.Ped.coords
    return isNear(src, vec3(coords.x, coords.y, coords.z), Config.Seller.Distance + 2.0)
end

local function discoverRecipe(src, recipeKey)
    local data = ensurePlayer(src)
    if data.discovered[recipeKey] then return false end

    data.discovered[recipeKey] = true
    if data.citizenid then
        MySQL.insert.await('INSERT IGNORE INTO negans_farming_recipes (citizenid, recipe) VALUES (?, ?)', {
            data.citizenid,
            recipeKey
        })
    end

    return true
end

local function hasIngredients(src, ingredients, extraItem, extraAmount)
    for itemName, amount in pairs(ingredients) do
        if Inventory.Count(src, itemName) < amount then
            return false, ('Missing %sx %s.'):format(amount, itemLabel(itemName))
        end
    end

    if extraItem and extraAmount and extraAmount > 0 and Inventory.Count(src, extraItem) < extraAmount then
        return false, ('Missing %sx %s.'):format(extraAmount, itemLabel(extraItem))
    end

    return true
end

local function removeIngredients(src, ingredients, extraItem, extraAmount)
    for itemName, amount in pairs(ingredients) do
        if amount > 0 and not Inventory.RemoveItem(src, itemName, amount) then
            return false
        end
    end

    if extraItem and extraAmount and extraAmount > 0 then
        return Inventory.RemoveItem(src, extraItem, extraAmount)
    end

    return true
end

local function sanitizeMixture(input)
    if type(input) ~= 'table' then
        return nil, 'Invalid mixture.'
    end

    local mixture = {}
    local total = 0

    for itemName, amount in pairs(input) do
        local count = math.floor(tonumber(amount) or 0)
        if count > 0 then
            if not AllowedMixtureItems[itemName] then
                return nil, 'That ingredient cannot be used here.'
            end

            if count > Config.Production.MaxPerIngredient then
                return nil, ('Too much %s in one batch.'):format(itemLabel(itemName))
            end

            mixture[itemName] = count
            total = total + count
        end
    end

    if total == 0 then
        return nil, 'Add at least one ingredient.'
    end

    return mixture
end

local function ingredientsMatch(recipeIngredients, mixture)
    for itemName, amount in pairs(recipeIngredients) do
        if mixture[itemName] ~= amount then
            return false
        end
    end

    for itemName, amount in pairs(mixture) do
        if amount > 0 and recipeIngredients[itemName] ~= amount then
            return false
        end
    end

    return true
end

local function getRecipeAccess(data, recipe)
    local tier = data.tier or getReputationTier(data.reputation or 0)
    if data.level < recipe.level then
        return false, ('Requires farming level %s.'):format(recipe.level)
    end

    if recipe.requiredTier and tier.level < recipe.requiredTier then
        local required = Config.Reputation.Tiers[recipe.requiredTier]
        return false, ('Requires %s reputation.'):format(required and required.label or ('tier ' .. recipe.requiredTier))
    end

    return true
end

local function findRecipeForMixture(mixture, data)
    for recipeKey, recipe in pairs(Config.Recipes) do
        if ingredientsMatch(recipe.ingredients, mixture) then
            local hasAccess, reason = getRecipeAccess(data, recipe)
            if not hasAccess then
                return nil, nil, reason
            end

            return recipeKey, recipe
        end
    end

    return nil
end

local function consumeWrongMixture(src, mixture)
    if not Config.Production.ConsumeWrongMixtures then return true end

    local toRemove = {}
    for itemName, amount in pairs(mixture) do
        toRemove[itemName] = math.max(1, math.floor(amount * Config.Production.WrongMixtureConsumeRatio))
    end

    local ok, message = hasIngredients(src, toRemove)
    if not ok then return false, message end

    if not removeIngredients(src, toRemove) then
        return false, 'Could not consume the failed ingredients.'
    end

    local reward = Config.Production.WrongMixtureReturn
    if reward and reward.item then
        local amount = math.random(reward.min or 1, reward.max or 1)
        if Inventory.CanCarry(src, reward.item, amount) then
            Inventory.AddItem(src, reward.item, amount)
        end
    end

    return true
end

local function formatIngredientList(ingredients)
    local parts = {}
    for itemName, amount in pairs(ingredients) do
        parts[#parts + 1] = ('%sx %s'):format(amount, itemLabel(itemName))
    end
    table.sort(parts)
    return table.concat(parts, ', ')
end

local function addMoney(src, account, amount, reason)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    Player.Functions.AddMoney(account, amount, reason or EventPrefix)
    return true
end

local function removeMoney(src, account, amount, reason)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    local current = Player.PlayerData.money and Player.PlayerData.money[account] or 0
    if current < amount then return false end

    Player.Functions.RemoveMoney(account, amount, reason or EventPrefix)
    return true
end

local function getToolState(src)
    local state = {
        yieldBonus = 0,
        skillEase = 0,
        cooldownMultiplier = 1.0,
        durationMultiplier = 1.0,
        tools = {}
    }

    for itemName, tool in pairs(Config.Tools) do
        local count = Inventory.Count(src, itemName)
        if count and count > 0 then
            state.tools[#state.tools + 1] = {
                item = itemName,
                label = tool.label,
                description = tool.description,
                count = count
            }

            state.yieldBonus = state.yieldBonus + (tool.yieldBonus or 0)
            state.skillEase = state.skillEase + (tool.skillEase or 0)
            state.cooldownMultiplier = math.min(state.cooldownMultiplier, tool.cooldownMultiplier or 1.0)
            state.durationMultiplier = math.min(state.durationMultiplier, tool.durationMultiplier or 1.0)
        end
    end

    return state
end

local function getOrderStamp()
    local now = os.time()
    local utc = os.date('!*t', now)
    if utc.hour < (Config.Orders.RotateHourUTC or 0) then
        now = now - 86400
    end

    return os.date('!%Y%m%d', now), os.date('!%Y-%m-%d', now)
end

local function seedFromText(text)
    local seed = 0
    for i = 1, #text do
        seed = seed + (string.byte(text, i) * i)
    end
    return seed
end

local function getActiveOrders()
    if not Config.Orders.Enabled then return {} end

    local stamp, displayDate = getOrderStamp()
    if DailyOrders.stamp == stamp then
        return DailyOrders.orders
    end

    local keys = {}
    for recipeKey, recipe in pairs(Config.Recipes) do
        if Config.Seller.Prices[recipe.item] and (Config.Orders.AllowRareRecipes or not recipe.rare) then
            keys[#keys + 1] = recipeKey
        end
    end
    table.sort(keys)

    local seed = seedFromText(stamp)
    local used = {}
    local orders = {}
    local maxOrders = math.min(Config.Orders.MaxActive or 3, #keys)

    for i = 1, maxOrders do
        local index = ((seed + (i * 19)) % #keys) + 1
        while used[keys[index]] do
            index = (index % #keys) + 1
        end

        local recipeKey = keys[index]
        local recipe = Config.Recipes[recipeKey]
        local amountRange = Config.Orders.Amount
        local bonusRange = Config.Orders.BonusMultiplier
        local amountSpan = (amountRange.max - amountRange.min) + 1
        local bonusSpan = math.floor((bonusRange.max - bonusRange.min) * 100)
        local amount = amountRange.min + ((seed + i * 7) % amountSpan)
        local bonus = bonusRange.min + (((seed + i * 13) % (bonusSpan + 1)) / 100)

        orders[#orders + 1] = {
            key = ('%s:%s'):format(stamp, recipeKey),
            date = displayDate,
            recipe = recipeKey,
            item = recipe.item,
            label = recipe.label,
            amount = amount,
            bonusMultiplier = bonus,
            basePrice = Config.Seller.Prices[recipe.item],
            requiredTier = recipe.requiredTier,
            rare = recipe.rare == true,
            reset = ('%02d:00 UTC'):format(Config.Orders.RotateHourUTC or 0)
        }

        used[recipeKey] = true
    end

    DailyOrders.stamp = stamp
    DailyOrders.orders = orders
    return orders
end

local function getOrderProgress(citizenid, orderKey)
    if not citizenid then return 0 end

    local row = MySQL.single.await('SELECT sold FROM negans_farming_order_progress WHERE citizenid = ? AND order_key = ?', {
        citizenid,
        orderKey
    })

    return row and tonumber(row.sold) or 0
end

local function addOrderProgress(citizenid, orderKey, amount)
    if not citizenid or amount <= 0 then return end

    MySQL.insert.await([[
        INSERT INTO negans_farming_order_progress (citizenid, order_key, sold)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE sold = sold + VALUES(sold)
    ]], {
        citizenid,
        orderKey,
        amount
    })
end

local function getBestOrderMatch(data, itemName, amount)
    local best

    for _, order in ipairs(getActiveOrders()) do
        if order.item == itemName then
            local sold = getOrderProgress(data.citizenid, order.key)
            local remaining = math.max(0, order.amount - sold)
            local matched = math.min(amount, remaining)
            if matched > 0 then
                best = {
                    order = order,
                    sold = sold,
                    remaining = remaining,
                    matched = matched
                }
                break
            end
        end
    end

    return best
end

local function getOrdersForPlayer(data)
    local orders = {}

    for _, order in ipairs(getActiveOrders()) do
        local sold = getOrderProgress(data.citizenid, order.key)
        local remaining = math.max(0, order.amount - sold)
        orders[#orders + 1] = {
            key = order.key,
            item = order.item,
            label = order.label,
            amount = order.amount,
            sold = sold,
            remaining = remaining,
            bonusMultiplier = order.bonusMultiplier,
            basePrice = order.basePrice,
            requiredTier = order.requiredTier,
            rare = order.rare,
            reset = order.reset,
            complete = remaining <= 0
        }
    end

    return orders
end

local function getToolListForPlayer(src)
    local tools = {}

    for itemName, tool in pairs(Config.Tools) do
        local count = Inventory.Count(src, itemName)
        tools[#tools + 1] = {
            item = itemName,
            label = tool.label,
            description = tool.description,
            count = count or 0,
            owned = count and count > 0
        }
    end

    table.sort(tools, function(a, b)
        return a.label < b.label
    end)

    return tools
end

local function buildJournalData(src)
    local data = ensurePlayer(src)
    local currentLevelXP = Config.Levels[data.level] or 0
    local nextLevelXP = getNextLevelXP(data.level)
    local nextTier = getNextReputationTier(data.reputation)
    local fruits = {}
    local recipes = {}

    for _, fruitKey in ipairs(Config.FruitOrder) do
        local fruit = Config.Fruits[fruitKey]
        fruits[#fruits + 1] = {
            key = fruitKey,
            label = fruit.label,
            minLevel = fruit.minLevel,
            unlocked = data.level >= fruit.minLevel
        }
    end

    for recipeKey, recipe in pairs(Config.Recipes) do
        local hasAccess, lockReason = getRecipeAccess(data, recipe)
        local discovered = data.discovered[recipeKey] and hasAccess
        local requiredTier = recipe.requiredTier and Config.Reputation.Tiers[recipe.requiredTier]

        recipes[#recipes + 1] = {
            key = recipeKey,
            label = discovered and recipe.label or (recipe.rare and 'Rare Blend' or 'Unknown Blend'),
            level = recipe.level,
            requiredTier = recipe.requiredTier,
            requiredTierLabel = requiredTier and requiredTier.label or nil,
            rare = recipe.rare == true,
            discovered = discovered == true,
            locked = not hasAccess,
            lockReason = lockReason,
            ingredients = discovered and formatIngredientList(recipe.ingredients) or nil
        }
    end

    table.sort(recipes, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.key < b.key
    end)

    return {
        player = {
            xp = data.xp,
            level = data.level,
            currentLevelXP = currentLevelXP,
            nextLevelXP = nextLevelXP,
            reputation = data.reputation,
            tier = data.tier,
            nextTier = nextTier
        },
        fruits = fruits,
        recipes = recipes,
        orders = getOrdersForPlayer(data),
        tools = getToolListForPlayer(src)
    }
end

local function applyDrinkStats(src, itemName)
    local recipeKey = RecipeByItem[itemName]
    local recipe = recipeKey and Config.Recipes[recipeKey]
    if not recipe then return nil end

    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData.metadata then
        local thirst = tonumber(Player.PlayerData.metadata.thirst) or 0
        Player.Functions.SetMetaData('thirst', math.min(100, thirst + (recipe.thirst or 15)))
    end

    local now = os.time()
    DrinkLogs[src] = DrinkLogs[src] or {}
    local log = DrinkLogs[src]
    local fresh = {}

    for _, timestamp in ipairs(log) do
        if now - timestamp <= Config.Drinks.WindowSeconds then
            fresh[#fresh + 1] = timestamp
        end
    end

    fresh[#fresh + 1] = now
    DrinkLogs[src] = fresh

    local extra = math.max(0, #fresh - Config.Drinks.MaxSafeDrinks)
    return {
        item = itemName,
        label = recipe.label,
        thirst = recipe.thirst or 15,
        count = #fresh,
        sick = extra > 0,
        sickLevel = extra,
        duration = Config.Drinks.SickDuration + (extra * Config.Drinks.SickDurationPerExtra)
    }
end

local function consumeDrink(src, itemName, slot)
    if not RecipeByItem[itemName] then
        return { ok = false, type = 'error', message = 'That drink is not registered.' }
    end

    if not Inventory.RemoveItem(src, itemName, 1, slot) then
        return { ok = false, type = 'error', message = ('Missing %s.'):format(itemLabel(itemName)) }
    end

    local effect = applyDrinkStats(src, itemName)
    return {
        ok = true,
        effect = effect,
        message = ('You drank %s.'):format(effect.label)
    }
end

lib.callback.register(EventPrefix .. ':server:getState', function(src)
    local data = ensurePlayer(src)
    return {
        xp = data.xp,
        level = data.level,
        nextLevelXP = getNextLevelXP(data.level),
        reputation = data.reputation,
        tier = data.tier,
        nextTier = getNextReputationTier(data.reputation),
        discovered = data.discovered
    }
end)

lib.callback.register(EventPrefix .. ':server:getToolState', function(src)
    return getToolState(src)
end)

lib.callback.register(EventPrefix .. ':server:getJournalData', function(src)
    return buildJournalData(src)
end)

lib.callback.register(EventPrefix .. ':server:getCustomTrees', function()
    return getCustomTreesGrouped()
end)

lib.callback.register(EventPrefix .. ':server:getCustomTreeList', function(src)
    if not hasAdminPermission(src) then
        return {}
    end

    local list = {}
    for _, tree in ipairs(CustomTrees) do
        local fruit = Config.Fruits[tree.fruit]
        list[#list + 1] = {
            id = tree.id,
            fruit = tree.fruit,
            fruitLabel = fruit and fruit.label or tree.fruit,
            coords = tree.coords,
            heading = tree.heading,
            label = tree.label
        }
    end

    table.sort(list, function(a, b)
        return a.id < b.id
    end)

    return list
end)

lib.callback.register(EventPrefix .. ':server:harvestFruit', function(src, fruitKey, zoneRef)
    local fruit = Config.Fruits[fruitKey]
    local zone, cooldownKey = getHarvestZone(fruitKey, zoneRef)

    if not fruit or not zone then
        return { ok = false, type = 'error', message = 'Invalid harvest spot.' }
    end

    local data = ensurePlayer(src)
    if data.level < fruit.minLevel then
        return { ok = false, type = 'error', message = 'Your farming level is too low for this fruit.' }
    end

    if not isNearFruitZone(src, fruitKey, zoneRef) then
        return { ok = false, type = 'error', message = 'You are too far from that crop.' }
    end

    local tools = getToolState(src)
    local now = os.time()
    local lastPick = data.lastPick[cooldownKey] or 0
    local cooldown = math.floor(Config.Picking.CooldownSeconds * tools.cooldownMultiplier)
    if now - lastPick < cooldown then
        return { ok = false, type = 'error', message = 'This crop needs a moment to regrow.' }
    end

    local amount = math.random(fruit.harvest.min, fruit.harvest.max) + tools.yieldBonus
    if not Inventory.CanCarry(src, fruit.item, amount) then
        return { ok = false, type = 'error', message = 'You cannot carry more fruit.' }
    end

    if not Inventory.AddItem(src, fruit.item, amount) then
        return { ok = false, type = 'error', message = 'Could not add fruit to your inventory.' }
    end

    data.lastPick[cooldownKey] = now
    addXP(src, fruit.xp * amount, 'harvest')

    return {
        ok = true,
        type = 'success',
        title = fruit.label,
        message = ('Picked %sx %s.'):format(amount, itemLabel(fruit.item))
    }
end)

lib.callback.register(EventPrefix .. ':server:craftJuice', function(src, stationId, input)
    local nearStation = isNearStation(src, stationId)
    if not nearStation then
        return { ok = false, type = 'error', message = 'You are too far from the juice press.' }
    end

    local mixture, errorMessage = sanitizeMixture(input)
    if not mixture then
        return { ok = false, type = 'error', message = errorMessage }
    end

    local data = ensurePlayer(src)
    local recipeKey, recipe, accessReason = findRecipeForMixture(mixture, data)

    if not recipe then
        if accessReason then
            return {
                ok = false,
                type = 'error',
                title = 'Recipe Locked',
                message = accessReason
            }
        end

        local ok, failMessage = consumeWrongMixture(src, mixture)
        if not ok then
            return { ok = false, type = 'error', message = failMessage }
        end

        return {
            ok = false,
            type = 'warning',
            title = 'Wrong Mixture',
            message = 'That recipe did not work. Some of the batch was ruined.'
        }
    end

    local bottleItem = Config.Production.RequireBottle and Config.Production.BottleItem or nil
    local bottleAmount = bottleItem and (recipe.amount or 1) or 0

    local ok, missing = hasIngredients(src, recipe.ingredients, bottleItem, bottleAmount)
    if not ok then
        return { ok = false, type = 'error', message = missing }
    end

    if not Inventory.CanCarry(src, recipe.item, recipe.amount or 1) then
        return { ok = false, type = 'error', message = 'You cannot carry the finished drinks.' }
    end

    if not removeIngredients(src, recipe.ingredients, bottleItem, bottleAmount) then
        return { ok = false, type = 'error', message = 'Could not consume ingredients.' }
    end

    if not Inventory.AddItem(src, recipe.item, recipe.amount or 1, { recipe = recipeKey }) then
        for itemName, amount in pairs(recipe.ingredients) do
            Inventory.AddItem(src, itemName, amount)
        end
        if bottleItem and bottleAmount > 0 then
            Inventory.AddItem(src, bottleItem, bottleAmount)
        end
        return { ok = false, type = 'error', message = 'Could not add the finished juice.' }
    end

    local discoveredNew = discoverRecipe(src, recipeKey)
    addXP(src, recipe.xp, 'craft')
    addReputation(src, Config.Reputation.CraftRep, 'craft')

    return {
        ok = true,
        type = 'success',
        title = recipe.label,
        message = discoveredNew and ('Discovered and bottled %s.'):format(recipe.label) or ('Bottled %s.'):format(recipe.label)
    }
end)

lib.callback.register(EventPrefix .. ':server:getKnownRecipes', function(src)
    local data = ensurePlayer(src)
    local recipes = {}

    for recipeKey, recipe in pairs(Config.Recipes) do
        local hasAccess = getRecipeAccess(data, recipe)
        if data.discovered[recipeKey] and hasAccess then
            recipes[#recipes + 1] = {
                key = recipeKey,
                label = recipe.label,
                level = recipe.level,
                rare = recipe.rare == true,
                ingredients = formatIngredientList(recipe.ingredients)
            }
        end
    end

    table.sort(recipes, function(a, b)
        return a.level < b.level
    end)

    return recipes
end)

lib.callback.register(EventPrefix .. ':server:getSellableItems', function(src)
    local items = {}
    local data = ensurePlayer(src)
    local tier = data.tier or getReputationTier(data.reputation or 0)
    local priceMultiplier = tier.priceMultiplier or 0

    for itemName, price in pairs(Config.Seller.Prices) do
        local count = Inventory.Count(src, itemName)
        if count and count > 0 then
            local orderMatch = getBestOrderMatch(data, itemName, count)
            items[#items + 1] = {
                name = itemName,
                label = itemLabel(itemName),
                count = count,
                price = math.floor(price * (1.0 + priceMultiplier)),
                basePrice = price,
                reputationTier = tier.label,
                reputationBonus = priceMultiplier,
                order = orderMatch and {
                    label = orderMatch.order.label,
                    amount = orderMatch.order.amount,
                    remaining = orderMatch.remaining,
                    matched = orderMatch.matched,
                    bonusMultiplier = orderMatch.order.bonusMultiplier
                } or nil,
                isDrink = RecipeByItem[itemName] ~= nil
            }
        end
    end

    table.sort(items, function(a, b)
        if a.isDrink ~= b.isDrink then return a.isDrink end
        return a.label < b.label
    end)

    return items
end)

lib.callback.register(EventPrefix .. ':server:sellItem', function(src, itemName, amount, bonus)
    amount = math.floor(tonumber(amount) or 0)
    local price = Config.Seller.Prices[itemName]

    if not price or amount < 1 then
        return { ok = false, type = 'error', message = 'Invalid sale.' }
    end

    if not isNearSeller(src) then
        return { ok = false, type = 'error', message = 'You are too far from the buyer.' }
    end

    if Inventory.Count(src, itemName) < amount then
        return { ok = false, type = 'error', message = ('Missing %s.'):format(itemLabel(itemName)) }
    end

    if not Inventory.RemoveItem(src, itemName, amount) then
        return { ok = false, type = 'error', message = 'Could not remove items for sale.' }
    end

    local data = ensurePlayer(src)
    local tier = data.tier or getReputationTier(data.reputation or 0)
    local reputationMultiplier = tier.priceMultiplier or 0
    local total = math.floor(price * amount * (1.0 + reputationMultiplier))
    local orderBonus = 0
    local orderMessage = ''
    local orderMatch = getBestOrderMatch(data, itemName, amount)

    if orderMatch then
        orderBonus = math.floor(price * orderMatch.matched * (orderMatch.order.bonusMultiplier - 1.0))
        total = total + orderBonus
        addOrderProgress(data.citizenid, orderMatch.order.key, orderMatch.matched)
        addReputation(src, Config.Reputation.DailyOrderRepPerItem * orderMatch.matched, 'daily_order')
        orderMessage = (' Daily order bonus applied to %sx.'):format(orderMatch.matched)
    end

    if bonus then
        total = math.floor(total * (1.0 + Config.Seller.SkillBonus))
    end

    addMoney(src, Config.Seller.Account, total, 'negans-farming-sale')
    addXP(src, Config.Seller.SellXPPerItem * amount, 'sell')
    addReputation(src, Config.Reputation.SellRepPerItem * amount, 'sell')

    return {
        ok = true,
        type = 'success',
        title = 'Fresh Juice Buyer',
        message = ('Sold %sx %s for $%s%s.%s'):format(
            amount,
            itemLabel(itemName),
            total,
            bonus and ' with a negotiation bonus' or '',
            orderMessage
        )
    }
end)

lib.callback.register(EventPrefix .. ':server:buySupply', function(src, stationId, itemName, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then
        return { ok = false, type = 'error', message = 'Invalid amount.' }
    end

    local nearStation = isNearStation(src, stationId)
    if not nearStation then
        return { ok = false, type = 'error', message = 'You are too far from the supply shelf.' }
    end

    local supply
    for _, item in ipairs(Config.Supplies.Items) do
        if item.name == itemName then
            supply = item
            break
        end
    end

    if not supply then
        return { ok = false, type = 'error', message = 'Invalid supply item.' }
    end

    local total = supply.price * amount
    if not Inventory.CanCarry(src, itemName, amount) then
        return { ok = false, type = 'error', message = 'You cannot carry that many supplies.' }
    end

    if not removeMoney(src, Config.Seller.Account, total, 'negans-farming-supplies') then
        return { ok = false, type = 'error', message = ('You need $%s.'):format(total) }
    end

    if not Inventory.AddItem(src, itemName, amount) then
        addMoney(src, Config.Seller.Account, total, 'negans-farming-supply-refund')
        return { ok = false, type = 'error', message = 'Could not add supplies, money refunded.' }
    end

    return {
        ok = true,
        type = 'success',
        title = Config.Supplies.Label,
        message = ('Bought %sx %s for $%s.'):format(amount, itemLabel(itemName), total)
    }
end)

lib.callback.register(EventPrefix .. ':server:consumeDrink', function(src, itemName, slot)
    return consumeDrink(src, itemName, slot)
end)

local function registerUseableDrinks()
    for itemName in pairs(RecipeByItem) do
        QBCore.Functions.CreateUseableItem(itemName, function(source, itemData)
            local slot = itemData and itemData.slot
            local result = consumeDrink(source, itemName, slot)
            if result.ok then
                TriggerClientEvent(EventPrefix .. ':client:drinkConsumed', source, result.effect)
            else
                notify(source, { type = 'error', description = result.message })
            end
        end)
    end
end

local function registerQBCoreItems()
    if not Config.RegisterMissingQBCoreItems then return end
    if not Config.QBItems then return end

    for itemName, item in pairs(Config.QBItems) do
        if not QBCore.Shared.Items[itemName] then
            QBCore.Shared.Items[itemName] = item
        end
    end
end

local function registerSupplyShop()
    if not Config.Supplies.Enabled or not Config.Supplies.UseOxShop then return end
    if not resourceStarted('ox_inventory') then return end

    local locations = {}
    for _, station in ipairs(Config.Production.Stations) do
        locations[#locations + 1] = station.coords
    end

    exports.ox_inventory:RegisterShop(Config.Supplies.ShopId, {
        name = Config.Supplies.Label,
        inventory = Config.Supplies.Items,
        locations = locations
    })
end

local function getCommandTarget(src, args)
    local target = tonumber(args[1])
    if not target then
        notify(src, { type = 'error', description = 'Invalid player ID.' })
        return nil
    end

    local Player = QBCore.Functions.GetPlayer(target)
    if not Player then
        notify(src, { type = 'error', description = 'Player is not online.' })
        return nil
    end

    return target, Player
end

local function setPlayerXP(src, target, amount)
    local data = ensurePlayer(target)
    data.xp = math.max(0, amount)
    data.level = getLevelFromXP(data.xp)
    savePlayer(target)
    syncProgress(target, 0, 'admin_setxp')
    notify(src, { type = 'success', description = ('Set player %s farming XP to %s.'):format(target, data.xp) })
end

local function setPlayerReputation(src, target, amount)
    local data = ensurePlayer(target)
    data.reputation = math.max(0, amount)
    data.tier = getReputationTier(data.reputation)
    savePlayer(target)
    syncProgress(target, 0, 'admin_setrep')
    notify(src, { type = 'success', description = ('Set player %s farming reputation to %s.'):format(target, data.reputation) })
end

RegisterNetEvent(EventPrefix .. ':server:addCustomTree', function(fruitKey, coords, heading)
    local src = source
    if not Config.TreeEditor.Enabled then return end

    if not hasAdminPermission(src) then
        notify(src, { type = 'error', description = 'You do not have permission to add farming trees.' })
        return
    end

    if not Config.Fruits[fruitKey] then
        notify(src, { type = 'error', description = 'Invalid fruit type.' })
        return
    end

    if type(coords) ~= 'table' then
        notify(src, { type = 'error', description = 'Invalid tree coordinates.' })
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    local id = ('%s_%s'):format(fruitKey, os.time() .. math.random(1000, 9999))
    local zOffset = Config.TreeEditor.AddHeightOffset or 0.0

    CustomTrees[#CustomTrees + 1] = {
        id = id,
        fruit = fruitKey,
        coords = {
            x = tonumber(coords.x) or 0.0,
            y = tonumber(coords.y) or 0.0,
            z = (tonumber(coords.z) or 0.0) + zOffset
        },
        heading = tonumber(heading) or 0.0,
        label = Config.Fruits[fruitKey].label,
        createdBy = Player and Player.PlayerData and Player.PlayerData.citizenid or 'console',
        createdAt = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }

    saveCustomTrees()
    TriggerClientEvent(EventPrefix .. ':client:refreshCustomTrees', -1)
    notify(src, {
        type = 'success',
        title = 'Tree Saved',
        description = ('Added %s harvest tree `%s`.'):format(Config.Fruits[fruitKey].label, id)
    })
end)

RegisterNetEvent(EventPrefix .. ':server:removeCustomTree', function(treeId)
    local src = source
    if not Config.TreeEditor.Enabled then return end

    if not hasAdminPermission(src) then
        notify(src, { type = 'error', description = 'You do not have permission to remove farming trees.' })
        return
    end

    local tree, index = getCustomTreeById(treeId)
    if not tree then
        notify(src, { type = 'error', description = 'Custom tree ID not found.' })
        return
    end

    table.remove(CustomTrees, index)
    saveCustomTrees()
    TriggerClientEvent(EventPrefix .. ':client:refreshCustomTrees', -1)
    notify(src, {
        type = 'success',
        title = 'Tree Removed',
        description = ('Removed %s tree `%s`.'):format(tree.fruit, tree.id)
    })
end)

RegisterNetEvent(EventPrefix .. ':server:reloadCustomTrees', function()
    local src = source
    if not hasAdminPermission(src) then return end

    loadCustomTrees()
    TriggerClientEvent(EventPrefix .. ':client:refreshCustomTrees', -1)
    notify(src, { type = 'success', description = 'Reloaded custom farming trees.' })
end)

local function registerAdminCommands()
    local permission = Config.Admin.Permission or 'admin'
    local commands = Config.Admin.Commands

    QBCore.Commands.Add(commands.SetXP, 'Set a player farming XP', {
        { name = 'id', help = 'Player ID' },
        { name = 'amount', help = 'XP amount' }
    }, true, function(source, args)
        local target = getCommandTarget(source, args)
        if not target then return end

        setPlayerXP(source, target, math.floor(tonumber(args[2]) or 0))
    end, permission)

    QBCore.Commands.Add(commands.AddXP, 'Add farming XP to a player', {
        { name = 'id', help = 'Player ID' },
        { name = 'amount', help = 'XP amount' }
    }, true, function(source, args)
        local target = getCommandTarget(source, args)
        if not target then return end

        addXP(target, math.max(0, math.floor(tonumber(args[2]) or 0)), 'admin_addxp')
        notify(source, { type = 'success', description = ('Added farming XP to player %s.'):format(target) })
    end, permission)

    QBCore.Commands.Add(commands.SetRep, 'Set a player farming reputation', {
        { name = 'id', help = 'Player ID' },
        { name = 'amount', help = 'Reputation amount' }
    }, true, function(source, args)
        local target = getCommandTarget(source, args)
        if not target then return end

        setPlayerReputation(source, target, math.floor(tonumber(args[2]) or 0))
    end, permission)

    QBCore.Commands.Add(commands.AddRep, 'Add farming reputation to a player', {
        { name = 'id', help = 'Player ID' },
        { name = 'amount', help = 'Reputation amount' }
    }, true, function(source, args)
        local target = getCommandTarget(source, args)
        if not target then return end

        addReputation(target, math.max(0, math.floor(tonumber(args[2]) or 0)), 'admin_addrep')
        notify(source, { type = 'success', description = ('Added farming reputation to player %s.'):format(target) })
    end, permission)

    QBCore.Commands.Add(commands.ResetRecipes, 'Reset a player discovered farming recipes', {
        { name = 'id', help = 'Player ID' }
    }, true, function(source, args)
        local target, Player = getCommandTarget(source, args)
        if not target then return end

        local citizenid = Player.PlayerData.citizenid
        MySQL.query.await('DELETE FROM negans_farming_recipes WHERE citizenid = ?', { citizenid })
        local data = ensurePlayer(target)
        data.discovered = {}
        syncProgress(target, 0, 'admin_resetrecipes')
        notify(source, { type = 'success', description = ('Reset discovered recipes for player %s.'):format(target) })
    end, permission)

    QBCore.Commands.Add(commands.TestSick, 'Trigger farming drink sickness on a player', {
        { name = 'id', help = 'Player ID' }
    }, true, function(source, args)
        local target = getCommandTarget(source, args)
        if not target then return end

        TriggerClientEvent(EventPrefix .. ':client:drinkConsumed', target, {
            label = 'Sickness Test',
            sick = true,
            sickLevel = 2,
            duration = Config.Drinks.SickDuration
        })
        notify(source, { type = 'success', description = ('Triggered sickness test for player %s.'):format(target) })
    end, permission)
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if Player and Player.PlayerData then
        ensurePlayer(Player.PlayerData.source)
    end
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    savePlayer(src)
    PlayerCache[src] = nil
    DrinkLogs[src] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    savePlayer(src)
    PlayerCache[src] = nil
    DrinkLogs[src] = nil
end)

CreateThread(function()
    math.randomseed(os.time())
    loadCustomTrees()
    createTables()
    registerQBCoreItems()
    registerUseableDrinks()
    registerSupplyShop()
    registerAdminCommands()
    print(('[%s] Started with %s inventory mode.'):format(GetCurrentResourceName(), inventoryMode()))
end)
