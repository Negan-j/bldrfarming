local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}
local lastActionTime = {}

local function GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped then return nil end
    return GetEntityCoords(ped)
end

local function CheckCooldown(source, actionType)
    local identifier = tostring(source)
    local now = GetGameTimer()
    
    if not cooldowns[identifier] then
        cooldowns[identifier] = {}
    end
    
    local lastTime = cooldowns[identifier][actionType] or 0
    local cooldownTime = 0
    
    if actionType == 'pick' then
        cooldownTime = Config.Timers.pickCooldown
    elseif actionType == 'process' then
        cooldownTime = Config.Timers.processCooldown
    elseif actionType == 'sell' then
        cooldownTime = Config.Timers.sellCooldown
    end
    
    if now - lastTime < cooldownTime then
        return false, cooldownTime - (now - lastTime)
    end
    
    cooldowns[identifier][actionType] = now
    return true, 0
end

local function CheckJob(source)
    if not Config.Job.enabled then return true end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local job = Player.PlayerData.job
    if job.name ~= Config.Job.name then return false end
    if Config.Job.grade > 0 and job.grade.level < Config.Job.grade then return false end
    
    return true
end

local function CheckDistance(source, coords, zoneName)
    local playerCoords = GetPlayerCoords(source)
    if not playerCoords then return false end
    
    local zone = Config.Zones[zoneName]
    if not zone then return false end
    
    local distance = #(playerCoords - zone.coords)
    return distance <= Config.AntiExploit.maxDistance
end

local function HasItem(source, itemName, amount)
    local count = exports.ox_inventory:GetItemCount(source, itemName)
    return count >= amount, count
end

local function AddItem(source, itemName, amount)
    if not exports.ox_inventory:CanCarryItem(source, itemName, amount) then
        return false, 'inventory_full'
    end
    local success, response = exports.ox_inventory:AddItem(source, itemName, amount)
    return success, response
end

local function RemoveItem(source, itemName, amount)
    local success, response = exports.ox_inventory:RemoveItem(source, itemName, amount)
    return success, response
end

local function AddMoney(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    Player.Functions.AddMoney('cash', amount, 'farming-sale')
    return true
end

lib.callback.register('qb-farming:server:getData', function(source)
    if not CheckJob(source) then
        return { success = false, error = 'job_required' }
    end
    
    local processedItems = {}
    for key, data in pairs(Config.Processing) do
        local count = exports.ox_inventory:GetItemCount(source, data.input.item)
        processedItems[key] = {
            label = data.label,
            inputItem = data.input.item,
            inputAmount = data.input.amount,
            outputItem = data.output.item,
            outputAmount = data.output.amount,
            currentCount = count
        }
    end
    
    local sellableItems = {}
    for key, data in pairs(Config.Selling) do
        local count = exports.ox_inventory:GetItemCount(source, data.item)
        sellableItems[key] = {
            label = data.label,
            item = data.item,
            price = data.price,
            currentCount = count
        }
    end
    
    return {
        success = true,
        processing = processedItems,
        selling = sellableItems
    }
end)

lib.callback.register('qb-farming:server:pickCrop', function(source, cropKey)
    if not CheckJob(source) then
        return { success = false, error = 'job_required' }
    end
    
    local crop = Config.Crops[cropKey]
    if not crop then
        return { success = false, error = 'invalid_crop' }
    end
    
    local canPick, remaining = CheckCooldown(source, 'pick')
    if not canPick then
        return { success = false, error = 'cooldown', remaining = remaining }
    end
    
    if not CheckDistance(source, nil, 'farm') then
        return { success = false, error = 'too_far' }
    end
    
    local amount = math.random(crop.amount.min, crop.amount.max)
    local success, response = AddItem(source, crop.item, amount)
    
    if not success then
        return { success = false, error = response or 'cannot_carry' }
    end
    
    TriggerClientEvent('qb-farming:client:cropPicked', source, cropKey)
    
    return { success = true, amount = amount, item = crop.item }
end)

lib.callback.register('qb-farming:server:processCrop', function(source, processKey, quantity)
    if not CheckJob(source) then
        return { success = false, error = 'job_required' }
    end
    
    quantity = tonumber(quantity)
    if not quantity or quantity < 1 or quantity > Config.MaxProcessAmount then
        return { success = false, error = 'invalid_quantity' }
    end
    
    local process = Config.Processing[processKey]
    if not process then
        return { success = false, error = 'invalid_process' }
    end
    
    local canProcess, remaining = CheckCooldown(source, 'process')
    if not canProcess then
        return { success = false, error = 'cooldown', remaining = remaining }
    end
    
    if not CheckDistance(source, nil, 'processing') then
        return { success = false, error = 'too_far' }
    end
    
    local inputNeeded = process.input.amount * quantity
    
    local hasItems, currentCount = HasItem(source, process.input.item, inputNeeded)
    if not hasItems then
        return { success = false, error = 'not_enough_items', has = currentCount, needed = inputNeeded }
    end
    
    local outputAmount = process.output.amount * quantity
    
    if not exports.ox_inventory:CanCarryItem(source, process.output.item, outputAmount) then
        return { success = false, error = 'inventory_full' }
    end
    
    local removeSuccess, removeError = RemoveItem(source, process.input.item, inputNeeded)
    if not removeSuccess then
        return { success = false, error = 'remove_failed' }
    end
    
    local addSuccess, addError = AddItem(source, process.output.item, outputAmount)
    if not addSuccess then
        AddItem(source, process.input.item, inputNeeded)
        return { success = false, error = 'add_failed' }
    end
    
    return { 
        success = true, 
        processedAmount = outputAmount,
        outputItem = process.output.item
    }
end)

lib.callback.register('qb-farming:server:sellItem', function(source, sellKey, quantity)
    if not CheckJob(source) then
        return { success = false, error = 'job_required' }
    end
    
    quantity = tonumber(quantity)
    if not quantity or quantity < 1 then
        return { success = false, error = 'invalid_quantity' }
    end
    
    local sellData = Config.Selling[sellKey]
    if not sellData then
        return { success = false, error = 'invalid_item' }
    end
    
    local canSell, remaining = CheckCooldown(source, 'sell')
    if not canSell then
        return { success = false, error = 'cooldown', remaining = remaining }
    end
    
    if not CheckDistance(source, nil, 'selling') then
        return { success = false, error = 'too_far' }
    end
    
    local hasItems, currentCount = HasItem(source, sellData.item, quantity)
    if not hasItems then
        return { success = false, error = 'not_enough_items', has = currentCount, needed = quantity }
    end
    
    local removeSuccess, removeError = RemoveItem(source, sellData.item, quantity)
    if not removeSuccess then
        return { success = false, error = 'remove_failed' }
    end
    
    local totalPayout = sellData.price * quantity
    
    AddMoney(source, totalPayout)
    
    return { 
        success = true, 
        payout = totalPayout,
        item = sellData.item,
        quantity = quantity
    }
end)

RegisterNetEvent('qb-farming:server:checkJob', function()
    local src = source
    local hasJob = CheckJob(src)
    TriggerClientEvent('qb-farming:client:jobCheckResult', src, hasJob)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local identifier = tostring(src)
    cooldowns[identifier] = nil
    lastActionTime[identifier] = nil
end)
