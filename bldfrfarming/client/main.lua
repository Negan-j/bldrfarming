local QBCore = exports['qb-core']:GetCoreObject()
local farmZones = {}
local cropObjects = {}
local currentZone = nil
local cropRespawns = {}

local function CreateBlips()
    if Config.Blips.farm.enabled then
        local blip = AddBlipForCoord(Config.Zones.farm.coords.x, Config.Zones.farm.coords.y, Config.Zones.farm.coords.z)
        SetBlipSprite(blip, Config.Blips.farm.sprite)
        SetBlipColour(blip, Config.Blips.farm.color)
        SetBlipScale(blip, Config.Blips.farm.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Blips.farm.label)
        EndTextCommandSetBlipName(blip)
    end
    
    if Config.Blips.processing.enabled then
        local blip = AddBlipForCoord(Config.Zones.processing.coords.x, Config.Zones.processing.coords.y, Config.Zones.processing.coords.z)
        SetBlipSprite(blip, Config.Blips.processing.sprite)
        SetBlipColour(blip, Config.Blips.processing.color)
        SetBlipScale(blip, Config.Blips.processing.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Blips.processing.label)
        EndTextCommandSetBlipName(blip)
    end
    
    if Config.Blips.selling.enabled then
        local blip = AddBlipForCoord(Config.Zones.selling.coords.x, Config.Zones.selling.coords.y, Config.Zones.selling.coords.z)
        SetBlipSprite(blip, Config.Blips.selling.sprite)
        SetBlipColour(blip, Config.Blips.selling.color)
        SetBlipScale(blip, Config.Blips.selling.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Blips.selling.label)
        EndTextCommandSetBlipName(blip)
    end
end

local function SpawnCropObjects()
    for cropKey, cropData in pairs(Config.Crops) do
        cropObjects[cropKey] = {}
        for i, coords in ipairs(cropData.coords) do
            local model = GetHashKey(cropData.model)
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(0) end
            
            local obj = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)
            SetModelAsNoLongerNeeded(model)
            
            cropObjects[cropKey][i] = {
                entity = obj,
                coords = coords,
                available = true
            }
        end
    end
end

local function DeleteCropObjects()
    for cropKey, objects in pairs(cropObjects) do
        for i, objData in ipairs(objects) do
            if DoesEntityExist(objData.entity) then
                DeleteEntity(objData.entity)
            end
        end
    end
    cropObjects = {}
end

local function RespawnCrop(cropKey, index)
    local cropData = Config.Crops[cropKey]
    if not cropData then return end
    
    Wait(cropData.respawnTime)
    
    if cropObjects[cropKey] and cropObjects[cropKey][index] then
        cropObjects[cropKey][index].available = true
        
        if not DoesEntityExist(cropObjects[cropKey][index].entity) then
            local model = GetHashKey(cropData.model)
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(0) end
            
            local coords = cropObjects[cropKey][index].coords
            local obj = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)
            SetModelAsNoLongerNeeded(model)
            
            cropObjects[cropKey][index].entity = obj
        end
    end
end

local function OpenFarmingMenu(menuType)
    lib.callback('qb-farming:server:getData', false, function(data)
        if not data.success then
            if data.error == 'job_required' then
                lib.notify({ title = 'Farming', description = 'You need to be a farmer to use this!', type = 'error' })
            else
                lib.notify({ title = 'Farming', description = 'Failed to load data', type = 'error' })
            end
            return
        end
        
        NUI.Open({
            menuType = menuType,
            processing = data.processing,
            selling = data.selling
        })
    end)
end

local function SetupOxTarget()
    if Config.Target ~= 'ox_target' then return end
    
    local farmOptions = {}
    for cropKey, cropData in pairs(Config.Crops) do
        farmOptions[#farmOptions + 1] = {
            name = 'pick_' .. cropKey,
            label = 'Pick ' .. cropData.label,
            icon = 'fa-solid fa-hand',
            distance = 3.0,
            onSelect = function()
                local input = lib.inputDialog('Pick ' .. cropData.label, {
                    { type = 'number', label = 'Amount to pick', default = 1, min = 1, max = 10 }
                })
                
                if not input then return end
                
                local quantity = input[1] or 1
                
                for i = 1, quantity do
                    if lib.progressCircle({
                        duration = cropData.timer,
                        position = 'bottom',
                        label = 'Picking ' .. cropData.label,
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, car = true },
                        anim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' }
                    }) then
                        local result = lib.callback.await('qb-farming:server:pickCrop', false, cropKey)
                        
                        if result.success then
                            lib.notify({ 
                                title = 'Farming', 
                                description = 'Picked ' .. result.amount .. 'x ' .. cropData.label, 
                                type = 'success' 
                            })
                        else
                            if result.error == 'cooldown' then
                                lib.notify({ title = 'Farming', description = 'Wait ' .. math.ceil(result.remaining / 1000) .. 's', type = 'warning' })
                            elseif result.error == 'inventory_full' then
                                lib.notify({ title = 'Farming', description = 'Inventory full!', type = 'error' })
                            elseif result.error == 'too_far' then
                                lib.notify({ title = 'Farming', description = 'Too far from farm!', type = 'error' })
                            end
                            break
                        end
                    else
                        lib.notify({ title = 'Farming', description = 'Cancelled', type = 'inform' })
                        break
                    end
                end
            end
        }
    end
    
    farmOptions[#farmOptions + 1] = {
        name = 'open_farm_menu',
        label = 'Open Farm Menu',
        icon = 'fa-solid fa-warehouse',
        distance = 5.0,
        onSelect = function()
            OpenFarmingMenu('farm')
        end
    }
    
    exports.ox_target:addSphereZone({
        coords = Config.Zones.farm.coords,
        radius = Config.Zones.farm.radius,
        name = 'farm_zone',
        options = farmOptions
    })
    
    exports.ox_target:addSphereZone({
        coords = Config.Zones.processing.coords,
        radius = Config.Zones.processing.radius,
        name = 'processing_zone',
        options = {
            {
                name = 'open_processing_menu',
                label = 'Open Processing',
                icon = 'fa-solid fa-gears',
                distance = 5.0,
                onSelect = function()
                    OpenFarmingMenu('processing')
                end
            }
        }
    })
    
    exports.ox_target:addSphereZone({
        coords = Config.Zones.selling.coords,
        radius = Config.Zones.selling.radius,
        name = 'selling_zone',
        options = {
            {
                name = 'open_selling_menu',
                label = 'Open Sales',
                icon = 'fa-solid fa-dollar-sign',
                distance = 5.0,
                onSelect = function()
                    OpenFarmingMenu('selling')
                end
            }
        }
    })
end

local function SetupQbTarget()
    if Config.Target ~= 'qb-target' then return end
    
    local farmOptions = {}
    for cropKey, cropData in pairs(Config.Crops) do
        farmOptions[#farmOptions + 1] = {
            type = 'client',
            event = 'qb-farming:client:pickCropTarget',
            icon = 'fas fa-hand',
            label = 'Pick ' .. cropData.label,
            cropKey = cropKey
        }
    end
    
    farmOptions[#farmOptions + 1] = {
        type = 'client',
        event = 'qb-farming:client:openFarmMenu',
        icon = 'fas fa-warehouse',
        label = 'Open Farm Menu'
    }
    
    exports['qb-target']:AddCircleZone('farm_zone', Config.Zones.farm.coords, Config.Zones.farm.radius, {
        name = 'farm_zone',
        debugPoly = Config.Debug
    }, {
        options = farmOptions,
        distance = 3.0
    })
    
    exports['qb-target']:AddCircleZone('processing_zone', Config.Zones.processing.coords, Config.Zones.processing.radius, {
        name = 'processing_zone',
        debugPoly = Config.Debug
    }, {
        options = {
            {
                type = 'client',
                event = 'qb-farming:client:openProcessingMenu',
                icon = 'fas fa-gears',
                label = 'Open Processing'
            }
        },
        distance = 3.0
    })
    
    exports['qb-target']:AddCircleZone('selling_zone', Config.Zones.selling.coords, Config.Zones.selling.radius, {
        name = 'selling_zone',
        debugPoly = Config.Debug
    }, {
        options = {
            {
                type = 'client',
                event = 'qb-farming:client:openSellingMenu',
                icon = 'fas fa-dollar-sign',
                label = 'Open Sales'
            }
        },
        distance = 3.0
    })
end

local function SetupLibZones()
    farmZones.farm = lib.zones.sphere({
        coords = Config.Zones.farm.coords,
        radius = Config.Zones.farm.radius,
        debug = Config.Debug,
        onEnter = function()
            currentZone = 'farm'
            lib.notify({ title = 'Farming', description = 'Entered farm area', type = 'inform' })
        end,
        onExit = function()
            if currentZone == 'farm' then
                currentZone = nil
                if NUI.IsOpen() then NUI.Close() end
            end
        end
    })
    
    farmZones.processing = lib.zones.sphere({
        coords = Config.Zones.processing.coords,
        radius = Config.Zones.processing.radius,
        debug = Config.Debug,
        onEnter = function()
            currentZone = 'processing'
            lib.notify({ title = 'Farming', description = 'Entered processing area', type = 'inform' })
        end,
        onExit = function()
            if currentZone == 'processing' then
                currentZone = nil
                if NUI.IsOpen() then NUI.Close() end
            end
        end
    })
    
    farmZones.selling = lib.zones.sphere({
        coords = Config.Zones.selling.coords,
        radius = Config.Zones.selling.radius,
        debug = Config.Debug,
        onEnter = function()
            currentZone = 'selling'
            lib.notify({ title = 'Farming', description = 'Entered selling area', type = 'inform' })
        end,
        onExit = function()
            if currentZone == 'selling' then
                currentZone = nil
                if NUI.IsOpen() then NUI.Close() end
            end
        end
    })
end

RegisterNetEvent('qb-farming:client:pickCropTarget', function(data)
    local cropKey = data.cropKey
    if not cropKey then return end
    
    local cropData = Config.Crops[cropKey]
    if not cropData then return end
    
    if lib.progressCircle({
        duration = cropData.timer,
        position = 'bottom',
        label = 'Picking ' .. cropData.label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true },
        anim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' }
    }) then
        local result = lib.callback.await('qb-farming:server:pickCrop', false, cropKey)
        
        if result.success then
            lib.notify({ title = 'Farming', description = 'Picked ' .. result.amount .. 'x ' .. cropData.label, type = 'success' })
        else
            if result.error == 'cooldown' then
                lib.notify({ title = 'Farming', description = 'Wait ' .. math.ceil(result.remaining / 1000) .. 's', type = 'warning' })
            elseif result.error == 'inventory_full' then
                lib.notify({ title = 'Farming', description = 'Inventory full!', type = 'error' })
            elseif result.error == 'too_far' then
                lib.notify({ title = 'Farming', description = 'Too far from farm!', type = 'error' })
            elseif result.error == 'job_required' then
                lib.notify({ title = 'Farming', description = 'You need to be a farmer!', type = 'error' })
            else
                lib.notify({ title = 'Farming', description = 'Failed to pick crop', type = 'error' })
            end
        end
    end
end)

RegisterNetEvent('qb-farming:client:openFarmMenu', function()
    OpenFarmingMenu('farm')
end)

RegisterNetEvent('qb-farming:client:openProcessingMenu', function()
    OpenFarmingMenu('processing')
end)

RegisterNetEvent('qb-farming:client:openSellingMenu', function()
    OpenFarmingMenu('selling')
end)

RegisterNetEvent('qb-farming:client:cropPicked', function(cropKey)
    local cropData = Config.Crops[cropKey]
    if not cropData then return end
    
    for i, objData in ipairs(cropObjects[cropKey] or {}) do
        if objData.available then
            objData.available = false
            if DoesEntityExist(objData.entity) then
                DeleteEntity(objData.entity)
            end
            CreateThread(function()
                RespawnCrop(cropKey, i)
            end)
            break
        end
    end
end)

RegisterNetEvent('qb-farming:client:jobCheckResult', function(hasJob)
    if not hasJob then
        lib.notify({ title = 'Farming', description = 'You need the farmer job!', type = 'error' })
    end
end)

RegisterNuiCallback('pickCrop', function(data, cb)
    local cropKey = data.cropKey
    if not cropKey then cb({ success = false, error = 'invalid_crop' }) return end
    
    local cropData = Config.Crops[cropKey]
    if not cropData then cb({ success = false, error = 'invalid_crop' }) return end
    
    if lib.progressCircle({
        duration = cropData.timer,
        position = 'bottom',
        label = 'Picking ' .. cropData.label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true },
        anim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' }
    }) then
        local result = lib.callback.await('qb-farming:server:pickCrop', false, cropKey)
        cb(result)
    else
        cb({ success = false, error = 'cancelled' })
    end
end)

RegisterNuiCallback('processCrop', function(data, cb)
    local processKey = data.processKey
    local quantity = tonumber(data.quantity) or 1
    
    if not processKey then cb({ success = false, error = 'invalid_process' }) return end
    
    local processData = Config.Processing[processKey]
    if not processData then cb({ success = false, error = 'invalid_process' }) return end
    
    local totalDuration = processData.timer * math.min(quantity, 10)
    
    if lib.progressCircle({
        duration = totalDuration,
        position = 'bottom',
        label = processData.label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true },
        anim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' }
    }) then
        local result = lib.callback.await('qb-farming:server:processCrop', false, processKey, quantity)
        cb(result)
    else
        cb({ success = false, error = 'cancelled' })
    end
end)

RegisterNuiCallback('sellItem', function(data, cb)
    local sellKey = data.sellKey
    local quantity = tonumber(data.quantity) or 1
    
    if not sellKey then cb({ success = false, error = 'invalid_item' }) return end
    
    local result = lib.callback.await('qb-farming:server:sellItem', false, sellKey, quantity)
    cb(result)
end)

RegisterNuiCallback('refreshData', function(_, cb)
    lib.callback('qb-farming:server:getData', false, function(data)
        cb(data)
    end)
end)

RegisterCommand('farm', function()
    if not currentZone then
        lib.notify({ title = 'Farming', description = 'You need to be in a farming zone!', type = 'warning' })
        return
    end
    
    OpenFarmingMenu(currentZone)
end, false)

CreateThread(function()
    CreateBlips()
    SpawnCropObjects()
    SetupLibZones()
    
    if Config.Target == 'ox_target' then
        SetupOxTarget()
    elseif Config.Target == 'qb-target' then
        SetupQbTarget()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteCropObjects()
    end
end)
