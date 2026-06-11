local QBCore = exports['qb-core']:GetCoreObject()
local EventPrefix = Config.EventPrefix

local PlayerState = {
    xp = 0,
    level = 1,
    reputation = 0,
    tier = nil,
    discovered = {}
}

local activeAction = false
local journalOpen = false
local CustomHarvestZones = {}
local harvestZones = {}
local modelTargets = {}
local workZones = {}
local harvestProps = {}
local workProps = {}
local harvestBlips = {}
local workBlips = {}
local sellerPed
local startPickingWorldTree

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

local function notify(data)
    if lib and lib.notify then
        lib.notify(data)
        return
    end

    QBCore.Functions.Notify(data.description or data.title or 'Notification', data.type or 'primary')
end

local function normalizeProp(prop)
    if not prop then return nil end

    local function normalizeOne(entry)
        local copy = {}
        for k, v in pairs(entry) do
            copy[k] = v
        end

        if type(copy.model) == 'string' then
            copy.model = joaat(copy.model)
        end

        return copy
    end

    if prop[1] then
        local props = {}
        for i = 1, #prop do
            props[i] = normalizeOne(prop[i])
        end
        return props
    end

    return normalizeOne(prop)
end

local function runProgress(data)
    local progress = {}
    for k, v in pairs(data) do
        progress[k] = v
    end

    progress.prop = normalizeProp(progress.prop)
    return lib.progressCircle(progress)
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(25)
        if GetGameTimer() > timeout then return nil end
    end

    return hash
end

local function spawnStaticProp(model, coords, heading, list)
    local hash = loadModel(model)
    if not hash then return nil end

    local object = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(object, heading or 0.0)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)
    SetEntityAsMissionEntity(object, true, true)
    SetModelAsNoLongerNeeded(hash)

    local targetList = list or harvestProps
    targetList[#targetList + 1] = object
    return object
end

local function deleteEntity(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local function addBlip(coords, data, label)
    if not data then return nil end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, data.sprite or 1)
    SetBlipColour(blip, data.color or 2)
    SetBlipScale(blip, data.scale or 0.65)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(data.label or label)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function removeBlips(list)
    for _, blip in ipairs(list) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end

local function removeProps(list)
    for _, object in ipairs(list) do
        deleteEntity(object)
    end
end

local function targetMode()
    if Config.Target ~= 'auto' then return Config.Target end
    if resourceStarted('ox_target') then return 'ox_target' end
    if resourceStarted('qb-target') then return 'qb-target' end
    return nil
end

local function addSphereTarget(name, coords, radius, option)
    local mode = targetMode()
    if mode == 'ox_target' then
        local id = exports.ox_target:addSphereZone({
            name = name,
            coords = coords,
            radius = radius,
            debug = Config.Debug,
            options = { option }
        })
        return { mode = mode, id = id }
    end

    if mode == 'qb-target' then
        exports['qb-target']:AddCircleZone(name, coords, radius, {
            name = name,
            debugPoly = Config.Debug
        }, {
            options = {
                {
                    icon = option.icon,
                    label = option.label,
                    action = option.onSelect,
                    canInteract = option.canInteract
                }
            },
            distance = option.distance or radius + 0.5
        })
        return { mode = mode, id = name }
    end

    return nil
end

local function addBoxTarget(name, coords, size, heading, option)
    local mode = targetMode()
    if mode == 'ox_target' then
        local id = exports.ox_target:addBoxZone({
            name = name,
            coords = coords,
            size = size,
            rotation = heading or 0.0,
            debug = Config.Debug,
            options = { option }
        })
        return { mode = mode, id = id }
    end

    if mode == 'qb-target' then
        exports['qb-target']:AddBoxZone(name, coords, size.x, size.y, {
            name = name,
            heading = heading or 0.0,
            debugPoly = Config.Debug,
            minZ = coords.z - (size.z / 2),
            maxZ = coords.z + (size.z / 2)
        }, {
            options = {
                {
                    icon = option.icon,
                    label = option.label,
                    action = option.onSelect,
                    canInteract = option.canInteract
                }
            },
            distance = option.distance or 2.5
        })
        return { mode = mode, id = name }
    end

    return nil
end

local function addModelTarget(models, option)
    local mode = targetMode()
    if mode == 'ox_target' then
        exports.ox_target:addModel(models, { option })
        return { mode = mode, models = models, optionName = option.name }
    end

    if mode == 'qb-target' then
        exports['qb-target']:AddTargetModel(models, {
            options = {
                {
                    icon = option.icon,
                    label = option.label,
                    action = function(entity)
                        option.onSelect({ entity = entity })
                    end,
                    canInteract = function(entity, distance)
                        if option.canInteract then
                            return option.canInteract(entity, distance)
                        end
                        return true
                    end
                }
            },
            distance = option.distance or Config.Picking.Distance
        })
        return { mode = mode, models = models, label = option.label }
    end

    return nil
end

local function removeTarget(target)
    if not target then return end

    if target.mode == 'ox_target' then
        exports.ox_target:removeZone(target.id)
    elseif target.mode == 'qb-target' then
        exports['qb-target']:RemoveZone(target.id)
    end
end

local function removeModelTarget(target)
    if not target then return end

    if target.mode == 'ox_target' then
        exports.ox_target:removeModel(target.models, target.optionName)
    elseif target.mode == 'qb-target' then
        pcall(function()
            exports['qb-target']:RemoveTargetModel(target.models, target.label)
        end)
    end
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

local function isFruitUnlocked(fruitKey)
    local fruit = Config.Fruits[fruitKey]
    return fruit and PlayerState.level >= fruit.minLevel
end

local function toVec3(coords)
    return vec3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
end

local function loadCustomTrees()
    CustomHarvestZones = lib.callback.await(EventPrefix .. ':server:getCustomTrees', false) or {}

    for fruitKey, trees in pairs(CustomHarvestZones) do
        for index, tree in ipairs(trees) do
            if type(tree.coords) == 'table' then
                CustomHarvestZones[fruitKey][index].coords = toVec3(tree.coords)
            end
            CustomHarvestZones[fruitKey][index].custom = true
        end
    end
end

local function getFruitZones(fruitKey, fruit)
    local zones = {}

    for index, zone in ipairs(fruit.zones or {}) do
        zones[#zones + 1] = {
            ref = index,
            coords = zone.coords,
            heading = zone.heading,
            prop = zone.prop,
            custom = false
        }
    end

    for _, zone in ipairs(CustomHarvestZones[fruitKey] or {}) do
        zones[#zones + 1] = {
            ref = zone.id,
            coords = zone.coords,
            heading = zone.heading,
            label = zone.label,
            custom = true
        }
    end

    return zones
end

local function easeSkillCheck(checks, amount)
    if not amount or amount <= 0 then return checks end

    local eased = {}
    local map = {
        hard = 'medium',
        medium = 'easy',
        easy = 'easy'
    }

    for index, check in ipairs(checks) do
        if type(check) == 'string' then
            local value = check
            for _ = 1, amount do
                value = map[value] or value
            end
            eased[index] = value
        elseif type(check) == 'table' then
            local copy = {}
            for k, v in pairs(check) do
                copy[k] = v
            end
            copy.areaSize = math.min(80, (copy.areaSize or 30) + (amount * 8))
            copy.speedMultiplier = math.max(0.75, (copy.speedMultiplier or 1.0) - (amount * 0.18))
            eased[index] = copy
        else
            eased[index] = check
        end
    end

    return eased
end

local function clearHarvestWorld()
    for _, target in ipairs(harvestZones) do
        removeTarget(target)
    end

    harvestZones = {}

    for _, target in ipairs(modelTargets) do
        removeModelTarget(target)
    end
    modelTargets = {}

    removeBlips(harvestBlips)
    harvestBlips = {}

    removeProps(harvestProps)
    harvestProps = {}
end

local function createSearchableTreeTargets()
    if not Config.SearchableTrees or not Config.SearchableTrees.Enabled then return end

    for _, fruitKey in ipairs(Config.FruitOrder) do
        local fruit = Config.Fruits[fruitKey]
        local models = Config.SearchableTrees.Models[fruitKey]
        if fruit and models and #models > 0 and isFruitUnlocked(fruitKey) then
            local optionName = ('%s_search_model_%s'):format(EventPrefix, fruitKey)
            local target = addModelTarget(models, {
                name = optionName,
                icon = 'fa-solid fa-magnifying-glass',
                label = (Config.SearchableTrees.Label or 'Search %s'):format(fruit.label),
                distance = Config.SearchableTrees.Distance or Config.Picking.Distance,
                canInteract = function(entity)
                    return entity and entity ~= 0 and DoesEntityExist(entity) and isFruitUnlocked(fruitKey) and not activeAction
                end,
                onSelect = function(data)
                    startPickingWorldTree(fruitKey, data)
                end
            })

            if target then
                modelTargets[#modelTargets + 1] = target
            end
        end
    end
end

local function clearWorkWorld()
    for _, target in ipairs(workZones) do
        removeTarget(target)
    end
    workZones = {}

    removeBlips(workBlips)
    workBlips = {}

    removeProps(workProps)
    workProps = {}

    if sellerPed then
        deleteEntity(sellerPed)
        sellerPed = nil
    end
end

local function showXPToast(oldLevel, newLevel, amount)
    if amount and amount > 0 then
        notify({
            type = 'success',
            title = 'Farming XP',
            description = ('+%s XP (%s / Level %s)'):format(amount, PlayerState.xp, PlayerState.level)
        })
    end

    if newLevel > oldLevel then
        notify({
            type = 'success',
            title = 'New fruit unlocked',
            description = ('You reached farming level %s. Check the orchard for new crops.'):format(newLevel)
        })
    end
end

local function handleResult(result)
    if not result then
        notify({ type = 'error', description = 'No response from the farm.' })
        return
    end

    notify({
        type = result.type or (result.ok and 'success' or 'error'),
        title = result.title,
        description = result.message or 'Done.'
    })
end

local function startPicking(fruitKey, zoneRef)
    if activeAction then return end

    local fruit = Config.Fruits[fruitKey]
    if not fruit or not isFruitUnlocked(fruitKey) then return end

    activeAction = true

    local tools = lib.callback.await(EventPrefix .. ':server:getToolState', false) or {}
    local skillCheck = easeSkillCheck(fruit.skillCheck or Config.Picking.SkillCheck or { 'easy' }, tools.skillEase or 0)
    local skillPassed = lib.skillCheck(skillCheck, Config.SkillInputs)
    if not skillPassed then
        notify({ type = 'error', description = 'The fruit slipped before you could pick it clean.' })
        activeAction = false
        return
    end

    local progress = Config.Picking.Progress
    local duration = math.floor(math.random(progress.durationMin or 4500, progress.durationMax or 6500) * (tools.durationMultiplier or 1.0))
    local completed = runProgress({
        duration = duration,
        label = ('Picking %s'):format(fruit.label),
        position = progress.position,
        canCancel = progress.canCancel,
        disable = progress.disable,
        anim = fruit.anim or Config.Picking.Animation,
        prop = fruit.prop or Config.Picking.Prop
    })

    if completed then
        local result = lib.callback.await(EventPrefix .. ':server:harvestFruit', false, fruitKey, zoneRef)
        handleResult(result)
    else
        notify({ type = 'error', description = 'Picking cancelled.' })
    end

    activeAction = false
end

startPickingWorldTree = function(fruitKey, data)
    local entity = data and data.entity
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        notify({ type = 'error', description = 'No tree found to search.' })
        return
    end

    local coords = GetEntityCoords(entity)
    startPicking(fruitKey, {
        type = 'world',
        model = GetEntityModel(entity),
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
    })
end

local function createHarvestWorld()
    clearHarvestWorld()

    for _, fruitKey in ipairs(Config.FruitOrder) do
        local fruit = Config.Fruits[fruitKey]
        if fruit and isFruitUnlocked(fruitKey) then
            local zones = getFruitZones(fruitKey, fruit)
            if Config.Picking.CreateBlips and zones[1] then
                harvestBlips[#harvestBlips + 1] = addBlip(zones[1].coords, fruit.blip, fruit.label)
            end

            for index, zone in ipairs(zones) do
                local targetName = ('%s_%s_%s'):format(EventPrefix, fruitKey, zone.ref or index)
                local target = addSphereTarget(targetName, zone.coords, Config.Picking.Distance, {
                    name = targetName,
                    icon = 'fa-solid fa-hand',
                    label = ('Pick %s'):format(zone.label or fruit.label),
                    distance = Config.Picking.Distance + 0.5,
                    canInteract = function()
                        return isFruitUnlocked(fruitKey) and not activeAction
                    end,
                    onSelect = function()
                        startPicking(fruitKey, zone.ref or index)
                    end
                })

                if target then
                    harvestZones[#harvestZones + 1] = target
                end

                if Config.Picking.SpawnNodeProps and not zone.custom and (zone.prop or fruit.nodeProp) then
                    spawnStaticProp(zone.prop or fruit.nodeProp, zone.coords, zone.heading, harvestProps)
                end
            end
        end
    end

    createSearchableTreeTargets()
end

local function buildMixtureInput()
    local rows = {}
    local fields = {}

    for _, fruitKey in ipairs(Config.FruitOrder) do
        local fruit = Config.Fruits[fruitKey]
        if fruit and isFruitUnlocked(fruitKey) then
            rows[#rows + 1] = {
                type = 'number',
                label = fruit.label,
                description = 'How many pieces to add',
                icon = 'apple-whole',
                min = 0,
                max = Config.Production.MaxPerIngredient,
                default = 0,
                required = true
            }
            fields[#fields + 1] = fruit.item
        end
    end

    rows[#rows + 1] = {
        type = 'number',
        label = 'Sugar Scoops',
        icon = 'cube',
        min = 0,
        max = Config.Production.MaxPerIngredient,
        default = 0,
        required = true
    }
    fields[#fields + 1] = 'farm_sugar'

    rows[#rows + 1] = {
        type = 'number',
        label = 'Ice Cups',
        icon = 'snowflake',
        min = 0,
        max = Config.Production.MaxPerIngredient,
        default = 0,
        required = true
    }
    fields[#fields + 1] = 'farm_ice'

    local input = lib.inputDialog('Juice Mixture', rows, { size = 'md' })
    if not input then return nil end

    local mixture = {}
    local total = 0
    for index, itemName in ipairs(fields) do
        local amount = math.floor(tonumber(input[index]) or 0)
        if amount > 0 then
            mixture[itemName] = amount
            total = total + amount
        end
    end

    if total == 0 then
        notify({ type = 'error', description = 'Add at least one ingredient.' })
        return nil
    end

    return mixture
end

local function startCrafting(stationId)
    if activeAction then return end

    local mixture = buildMixtureInput()
    if not mixture then return end

    activeAction = true

    local skillPassed = lib.skillCheck(Config.Production.SkillCheck, Config.SkillInputs)
    if not skillPassed then
        notify({ type = 'error', description = 'The press jammed and the batch failed.' })
        activeAction = false
        return
    end

    local progress = Config.Production.Progress
    local completed = runProgress({
        duration = progress.duration,
        label = progress.label,
        position = progress.position,
        canCancel = progress.canCancel,
        disable = progress.disable,
        anim = progress.anim,
        prop = progress.prop
    })

    if completed then
        local result = lib.callback.await(EventPrefix .. ':server:craftJuice', false, stationId, mixture)
        handleResult(result)
    else
        notify({ type = 'error', description = 'Juice pressing cancelled.' })
    end

    activeAction = false
end

local function openJournal()
    local data = lib.callback.await(EventPrefix .. ':server:getJournalData', false)
    if not data then
        notify({ type = 'error', description = 'Could not open the farming journal.' })
        return
    end

    journalOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = data
    })
end

local function closeJournal()
    journalOpen = false
    SetNuiFocus(false, false)
    if lib and lib.hideContext then
        lib.hideContext(false)
    end
    SendNUIMessage({ action = 'close' })
end

local function setTutorialWaypoint(step)
    if not step or not step.coords then return end

    SetNewWaypoint(step.coords.x, step.coords.y)
    notify({
        type = 'inform',
        title = step.title,
        description = 'GPS waypoint set.'
    })
end

local function showTutorialStep(index)
    local step = Config.Tutorial.Steps[index]
    if not step then return end

    local options = {
        {
            title = step.title,
            description = step.description,
            icon = step.icon or 'circle-info',
            readOnly = true
        }
    }

    if step.coords then
        options[#options + 1] = {
            title = 'Set GPS',
            description = 'Place a waypoint for this step.',
            icon = 'location-dot',
            onSelect = function()
                setTutorialWaypoint(step)
            end
        }
    end

    if step.button == 'Open Journal' then
        options[#options + 1] = {
            title = 'Open Journal',
            description = 'Open the full farming journal.',
            icon = 'clipboard-list',
            onSelect = openJournal
        }
    end

    if Config.Tutorial.Steps[index + 1] then
        options[#options + 1] = {
            title = 'Next Step',
            icon = 'arrow-right',
            onSelect = function()
                showTutorialStep(index + 1)
            end
        }
    end

    if index > 1 then
        options[#options + 1] = {
            title = 'Previous Step',
            icon = 'arrow-left',
            onSelect = function()
                showTutorialStep(index - 1)
            end
        }
    end

    options[#options + 1] = {
        title = 'All Steps',
        icon = 'list',
        onSelect = function()
            lib.showContext(EventPrefix .. ':tutorial')
        end
    }

    lib.registerContext({
        id = EventPrefix .. ':tutorial_step_' .. index,
        title = 'Farming Tutorial',
        menu = EventPrefix .. ':tutorial',
        options = options
    })

    lib.showContext(EventPrefix .. ':tutorial_step_' .. index)
end

local function openTutorial()
    if not Config.Tutorial.Enabled then return end

    local options = {
        {
            title = 'Start Guided Tutorial',
            description = 'Walk through the farming job from supplies to selling.',
            icon = 'route',
            onSelect = function()
                showTutorialStep(1)
            end
        },
        {
            title = 'Open Farming Journal',
            description = 'View XP, reputation, tools, recipes, fruit unlocks, and daily buyer orders.',
            icon = 'clipboard-list',
            onSelect = openJournal
        }
    }

    for index, step in ipairs(Config.Tutorial.Steps) do
        options[#options + 1] = {
            title = step.title,
            description = step.description,
            icon = step.icon or 'circle-info',
            onSelect = function()
                showTutorialStep(index)
            end
        }
    end

    lib.registerContext({
        id = EventPrefix .. ':tutorial',
        title = 'Farming Tutorial',
        options = options
    })

    lib.showContext(EventPrefix .. ':tutorial')
end

local function maybePromptTutorial()
    if not Config.Tutorial.Enabled or not Config.Tutorial.AutoPrompt then return end

    local key = ('%s_tutorial_seen'):format(EventPrefix)
    if GetResourceKvpInt(key) == 1 then return end

    SetResourceKvpInt(key, 1)
    SetTimeout(3500, function()
        notify({
            type = 'inform',
            title = 'New Farming Job',
            description = ('Use /%s for a quick tutorial, or press F7 for the journal.'):format(Config.Tutorial.Command)
        })

        lib.registerContext({
            id = EventPrefix .. ':tutorial_prompt',
            title = 'Learn Negan\'s Farming',
            options = {
                {
                    title = 'Start Tutorial',
                    description = 'Learn how to pick, mix, sell, and level up.',
                    icon = 'route',
                    onSelect = openTutorial
                },
                {
                    title = 'Open Journal',
                    description = 'Skip the guide and view your farming progress.',
                    icon = 'clipboard-list',
                    onSelect = openJournal
                }
            }
        })

        lib.showContext(EventPrefix .. ':tutorial_prompt')
    end)
end

local function openKnownRecipes()
    local recipes = lib.callback.await(EventPrefix .. ':server:getKnownRecipes', false)
    local options = {}

    if not recipes or #recipes == 0 then
        options[#options + 1] = {
            title = 'No recipes discovered',
            description = 'Experiment with fruit, sugar, and ice to learn recipes.',
            icon = 'flask'
        }
    else
        for _, recipe in ipairs(recipes) do
            options[#options + 1] = {
                title = recipe.label,
                description = recipe.ingredients,
                icon = 'bottle-water'
            }
        end
    end

    options[#options + 1] = {
        title = 'Back',
        icon = 'arrow-left',
        onSelect = function()
            lib.showContext(EventPrefix .. ':press')
        end
    }

    lib.registerContext({
        id = EventPrefix .. ':known_recipes',
        title = 'Known Juice Recipes',
        menu = EventPrefix .. ':press',
        options = options
    })
    lib.showContext(EventPrefix .. ':known_recipes')
end

local function openSupplyShop(stationId)
    if resourceStarted('ox_inventory') and Config.Supplies.UseOxShop then
        exports.ox_inventory:openInventory('shop', { type = Config.Supplies.ShopId, id = 1 })
        return
    end

    local options = {}
    for _, item in ipairs(Config.Supplies.Items) do
        options[#options + 1] = {
            title = Config.OxItems[item.name] and Config.OxItems[item.name].label or item.name,
            description = ('$%s each'):format(item.price),
            icon = 'basket-shopping',
            onSelect = function()
                local input = lib.inputDialog('Buy Supplies', {
                    {
                        type = 'number',
                        label = 'Amount',
                        min = 1,
                        max = 100,
                        default = 1,
                        required = true
                    }
                })

                if not input then return end
                local amount = math.floor(tonumber(input[1]) or 0)
                if amount < 1 then return end

                local result = lib.callback.await(EventPrefix .. ':server:buySupply', false, stationId, item.name, amount)
                handleResult(result)
            end
        }
    end

    lib.registerContext({
        id = EventPrefix .. ':supplies',
        title = Config.Supplies.Label,
        menu = EventPrefix .. ':press',
        options = options
    })
    lib.showContext(EventPrefix .. ':supplies')
end

local function openPress(stationId)
    lib.registerContext({
        id = EventPrefix .. ':press',
        title = 'Juice Press',
        options = {
            {
                title = 'Experiment With Mixture',
                description = 'Use unlocked fruit, sugar, and ice. Correct recipes are not shown until discovered.',
                icon = 'flask',
                onSelect = function()
                    startCrafting(stationId)
                end
            },
            {
                title = 'Known Recipes',
                description = 'Review recipes you have successfully made.',
                icon = 'book-open',
                onSelect = openKnownRecipes
            },
            {
                title = 'Farming Journal',
                description = 'View XP, reputation, tools, locked fruit, recipes, and buyer orders.',
                icon = 'clipboard-list',
                onSelect = openJournal
            },
            {
                title = 'Job Tutorial',
                description = 'Get a guided explanation of the farming job.',
                icon = 'route',
                onSelect = openTutorial
            },
            {
                title = 'Buy Bottles and Supplies',
                description = 'Purchase empty bottles, sugar, and ice.',
                icon = 'basket-shopping',
                disabled = not Config.Supplies.Enabled,
                onSelect = function()
                    openSupplyShop(stationId)
                end
            },
            {
                title = ('Farming Level %s'):format(PlayerState.level),
                description = ('%s XP earned'):format(PlayerState.xp),
                icon = 'seedling',
                readOnly = true
            }
        }
    })

    lib.showContext(EventPrefix .. ':press')
end

local function createWorkStations()
    for _, station in ipairs(Config.Production.Stations) do
        if station.prop then
            spawnStaticProp(station.prop.model, station.prop.coords, station.prop.heading, workProps)
        end

        workBlips[#workBlips + 1] = addBlip(station.coords, station.blip, station.label)

        local targetName = ('%s_press_%s'):format(EventPrefix, station.id)
        local target = addBoxTarget(targetName, station.coords, station.size, station.heading, {
            name = targetName,
            icon = 'fa-solid fa-blender',
            label = station.label,
            distance = 2.5,
            canInteract = function()
                return not activeAction
            end,
            onSelect = function()
                openPress(station.id)
            end
        })

        if target then
            workZones[#workZones + 1] = target
        end
    end
end

local function startSelling(item)
    if activeAction then return end

    local input = lib.inputDialog('Sell Produce', {
        {
            type = 'number',
            label = ('Amount to sell (max %s)'):format(item.count),
            min = 1,
            max = item.count,
            default = item.count,
            required = true
        }
    })

    if not input then return end
    local amount = math.floor(tonumber(input[1]) or 0)
    if amount < 1 then return end

    activeAction = true

    local bonus = lib.skillCheck(Config.Seller.SkillCheck, Config.SkillInputs)
    if not bonus then
        notify({ type = 'inform', description = 'No negotiation bonus this time.' })
    end

    local progress = Config.Seller.Progress
    local completed = runProgress({
        duration = progress.duration,
        label = progress.label,
        position = progress.position,
        canCancel = progress.canCancel,
        disable = progress.disable,
        anim = progress.anim,
        prop = progress.prop
    })

    if completed then
        local result = lib.callback.await(EventPrefix .. ':server:sellItem', false, item.name, amount, bonus)
        handleResult(result)
    else
        notify({ type = 'error', description = 'Sale cancelled.' })
    end

    activeAction = false
end

local function openSeller()
    local items = lib.callback.await(EventPrefix .. ':server:getSellableItems', false)
    local options = {
        {
            title = 'Farming Journal',
            description = 'Check daily buyer orders, XP, reputation, and discovered recipes.',
            icon = 'clipboard-list',
            onSelect = openJournal
        },
        {
            title = 'Job Tutorial',
            description = 'Review how picking, pressing, selling, orders, and reputation work.',
            icon = 'route',
            onSelect = openTutorial
        }
    }

    if not items or #items == 0 then
        options[#options + 1] = {
            title = 'Nothing to sell',
            description = 'Bring fruit or bottled juice back here.',
            icon = 'cash-register'
        }
    else
        for _, item in ipairs(items) do
            local description = ('$%s each'):format(item.price)
            if item.order then
                description = description .. (' | Daily order: %sx at +%s%%'):format(
                    item.order.remaining,
                    math.floor((item.order.bonusMultiplier - 1.0) * 100)
                )
            elseif item.reputationBonus and item.reputationBonus > 0 then
                description = description .. (' | %s pricing'):format(item.reputationTier)
            end

            options[#options + 1] = {
                title = ('%s x%s'):format(item.label, item.count),
                description = description,
                icon = item.isDrink and 'bottle-water' or 'apple-whole',
                onSelect = function()
                    startSelling(item)
                end
            }
        end
    end

    options[#options + 1] = {
        title = ('Farming Level %s'):format(PlayerState.level),
        description = ('%s XP earned'):format(PlayerState.xp),
        icon = 'seedling',
        readOnly = true
    }

    lib.registerContext({
        id = EventPrefix .. ':seller',
        title = 'Fresh Juice Buyer',
        options = options
    })

    lib.showContext(EventPrefix .. ':seller')
end

local function createSeller()
    local pedConfig = Config.Seller.Ped
    local hash = loadModel(pedConfig.model)
    if not hash then return end

    sellerPed = CreatePed(0, hash, pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z - 1.0, pedConfig.coords.w, false, false)
    SetEntityHeading(sellerPed, pedConfig.coords.w)
    FreezeEntityPosition(sellerPed, true)
    SetEntityInvincible(sellerPed, true)
    SetBlockingOfNonTemporaryEvents(sellerPed, true)
    if pedConfig.scenario then
        TaskStartScenarioInPlace(sellerPed, pedConfig.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(hash)

    local targetName = EventPrefix .. '_seller'
    local target = addSphereTarget(targetName, vec3(pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z), Config.Seller.Distance, {
        name = targetName,
        icon = 'fa-solid fa-cash-register',
        label = 'Sell Fruit and Juices',
        distance = Config.Seller.Distance,
        canInteract = function()
            return not activeAction
        end,
        onSelect = openSeller
    })

    if target then
        workZones[#workZones + 1] = target
    end

    local blip = addBlip(vec3(pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z), Config.Seller.Blip, Config.Seller.Blip.label)
    if blip then
        workBlips[#workBlips + 1] = blip
    end
end

local function applyDrinkEffect(effect)
    if not effect then return end

    notify({
        type = effect.sick and 'warning' or 'success',
        title = effect.label,
        description = effect.sick and 'You drank too much juice and feel sick.' or 'Refreshing.'
    })

    RestorePlayerStamina(PlayerId(), 1.0)

    if not effect.sick then return end

    local ped = PlayerPedId()
    local duration = effect.duration or Config.Drinks.SickDuration
    local sickLevel = effect.sickLevel or 1

    SetPedMotionBlur(ped, true)
    SetPedIsDrunk(ped, true)
    ShakeGameplayCam('DRUNK_SHAKE', math.min(1.0, 0.25 + (sickLevel * 0.12)))
    SetTimecycleModifier('spectator5')
    SetRunSprintMultiplierForPlayer(PlayerId(), 0.75)
    AnimpostfxPlay('DrugsMichaelAliensFight', duration, false)

    if math.random(100) <= Config.Drinks.RagdollChance then
        SetPedToRagdoll(ped, 2500, 2500, 0, false, false, false)
    end

    if Config.Drinks.DamagePerExtraDrink > 0 then
        local health = GetEntityHealth(ped)
        SetEntityHealth(ped, math.max(101, health - (Config.Drinks.DamagePerExtraDrink * sickLevel)))
    end

    CreateThread(function()
        Wait(duration)
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
        AnimpostfxStop('DrugsMichaelAliensFight')
        SetPedMotionBlur(PlayerPedId(), false)
        SetPedIsDrunk(PlayerPedId(), false)
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    end)
end

local function drinkWithEffect(effect)
    local progress = Config.Drinks.Progress
    runProgress({
        duration = progress.duration,
        label = effect and ('Drinking %s'):format(effect.label) or progress.label,
        position = progress.position,
        canCancel = progress.canCancel,
        disable = progress.disable,
        anim = progress.anim,
        prop = progress.prop
    })
    applyDrinkEffect(effect)
end

RegisterNetEvent(EventPrefix .. ':client:drinkConsumed', function(effect)
    drinkWithEffect(effect)
end)

RegisterNetEvent(EventPrefix .. ':client:drinkItem', function(data)
    if activeAction then return end

    local itemName
    local slot

    if type(data) == 'table' then
        itemName = data.name or data.item or data.itemName
        slot = data.slot
    else
        itemName = data
    end

    if not itemName then return end

    activeAction = true
    local progress = Config.Drinks.Progress
    local completed = runProgress({
        duration = progress.duration,
        label = progress.label,
        position = progress.position,
        canCancel = true,
        disable = progress.disable,
        anim = progress.anim,
        prop = progress.prop
    })

    if completed then
        local result = lib.callback.await(EventPrefix .. ':server:consumeDrink', false, itemName, slot)
        if result and result.ok then
            applyDrinkEffect(result.effect)
        else
            handleResult(result)
        end
    end

    activeAction = false
end)

RegisterNUICallback('close', function(_, cb)
    journalOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNetEvent(EventPrefix .. ':client:openJournal', openJournal)

RegisterCommand('farmingjournal', function()
    openJournal()
end, false)

RegisterKeyMapping('farmingjournal', 'Open farming journal', 'keyboard', 'F7')

RegisterCommand(Config.Tutorial.Command, function()
    openTutorial()
end, false)

if Config.Tutorial.Keybind and Config.Tutorial.Keybind ~= '' then
    RegisterKeyMapping(Config.Tutorial.Command, 'Open farming tutorial', 'keyboard', Config.Tutorial.Keybind)
end

RegisterCommand(Config.Admin.Commands.AddTree, function(_, args)
    if not Config.TreeEditor.Enabled then return end

    local fruitKey = args[1]
    if not fruitKey or not Config.Fruits[fruitKey] then
        notify({
            type = 'error',
            title = 'Tree Editor',
            description = ('Usage: /%s apple|orange|strawberry|peach|pineapple|dragonfruit'):format(Config.Admin.Commands.AddTree)
        })
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent(EventPrefix .. ':server:addCustomTree', fruitKey, {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }, GetEntityHeading(ped))
end, false)

RegisterCommand(Config.Admin.Commands.RemoveTree, function(_, args)
    if not Config.TreeEditor.Enabled then return end

    local treeId = args[1]
    if not treeId then
        notify({
            type = 'error',
            title = 'Tree Editor',
            description = ('Usage: /%s tree_id'):format(Config.Admin.Commands.RemoveTree)
        })
        return
    end

    TriggerServerEvent(EventPrefix .. ':server:removeCustomTree', treeId)
end, false)

RegisterCommand(Config.Admin.Commands.RefreshTrees, function()
    if not Config.TreeEditor.Enabled then return end

    TriggerServerEvent(EventPrefix .. ':server:reloadCustomTrees')
end, false)

RegisterCommand(Config.Admin.Commands.ListTrees, function()
    if not Config.TreeEditor.Enabled then return end

    local trees = lib.callback.await(EventPrefix .. ':server:getCustomTreeList', false) or {}
    local options = {}

    if #trees == 0 then
        options[#options + 1] = {
            title = 'No custom trees saved',
            description = ('Stand by a real tree and use /%s fruitname.'):format(Config.Admin.Commands.AddTree),
            icon = 'tree'
        }
    else
        for _, tree in ipairs(trees) do
            options[#options + 1] = {
                title = ('%s - %s'):format(tree.id, tree.fruitLabel),
                description = ('%.2f, %.2f, %.2f'):format(tree.coords.x, tree.coords.y, tree.coords.z),
                icon = 'tree',
                onSelect = function()
                    lib.registerContext({
                        id = EventPrefix .. ':tree_' .. tree.id,
                        title = tree.id,
                        menu = EventPrefix .. ':custom_trees',
                        options = {
                            {
                                title = 'Set GPS',
                                icon = 'location-dot',
                                onSelect = function()
                                    SetNewWaypoint(tree.coords.x, tree.coords.y)
                                end
                            },
                            {
                                title = 'Remove Tree',
                                description = 'Delete this saved harvest spot.',
                                icon = 'trash',
                                onSelect = function()
                                    TriggerServerEvent(EventPrefix .. ':server:removeCustomTree', tree.id)
                                end
                            }
                        }
                    })
                    lib.showContext(EventPrefix .. ':tree_' .. tree.id)
                end
            }
        end
    end

    lib.registerContext({
        id = EventPrefix .. ':custom_trees',
        title = 'Custom Farming Trees',
        options = options
    })

    lib.showContext(EventPrefix .. ':custom_trees')
end, false)

RegisterNetEvent(EventPrefix .. ':client:xpUpdated', function(data)
    local oldLevel = PlayerState.level
    PlayerState.xp = data.xp or PlayerState.xp
    PlayerState.level = data.level or getLevelFromXP(PlayerState.xp)
    PlayerState.reputation = data.reputation or PlayerState.reputation
    PlayerState.tier = data.tier or PlayerState.tier

    showXPToast(oldLevel, PlayerState.level, data.amount)

    if PlayerState.level ~= oldLevel then
        createHarvestWorld()
    end

    if journalOpen then
        CreateThread(function()
            local journalData = lib.callback.await(EventPrefix .. ':server:getJournalData', false)
            if journalData then
                SendNUIMessage({ action = 'refresh', data = journalData })
            end
        end)
    end
end)

local function loadState()
    local state = lib.callback.await(EventPrefix .. ':server:getState', false)
    if state then
        PlayerState.xp = state.xp or 0
        PlayerState.level = state.level or getLevelFromXP(PlayerState.xp)
        PlayerState.reputation = state.reputation or 0
        PlayerState.tier = state.tier
        PlayerState.discovered = state.discovered or {}
    end
end

local function setupWorld()
    closeJournal()
    loadState()
    loadCustomTrees()
    createHarvestWorld()
    clearWorkWorld()
    createWorkStations()
    createSeller()
    maybePromptTutorial()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    setupWorld()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    closeJournal()
    clearHarvestWorld()
    clearWorkWorld()
end)

RegisterNetEvent(EventPrefix .. ':client:refreshCustomTrees', function()
    loadCustomTrees()
    createHarvestWorld()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    closeJournal()
    clearHarvestWorld()
    clearWorkWorld()
end)

CreateThread(function()
    closeJournal()
    Wait(500)
    closeJournal()
    Wait(1500)
    closeJournal()
    setupWorld()
end)
