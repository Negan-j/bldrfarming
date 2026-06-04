# Farming Job Resource

A FiveM farming job resource for QBCore framework with ox_inventory, ox_lib, and React NUI support.

## Features

- Pick crops at farm zones (wheat, corn, tomato)
- Process raw crops into sellable products
- Sell processed goods at the market
- Progress bar animations with ox_lib
- Beautiful React NUI menu
- Support for qb-target and ox_target
- Secure server-side validation with anti-exploit measures

## Requirements

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)
- [qb-target](https://github.com/qbcore-framework/qb-target) OR [ox_target](https://github.com/overextended/ox_target)

## Installation

### 1. Add Items to ox_inventory

Copy the contents of `shared/items.lua` into your ox_inventory items file (usually `ox_inventory/data/items.lua`).

### 2. Ensure Proper Load Order

Add to your server.cfg ensuring dependencies load first:

```
ensure qb-core
ensure ox_lib
ensure oxmysql
ensure ox_inventory
ensure qb-target  # or ox_target
ensure farmingjob
```

### 3. Configure Zones (Optional)

Edit `config.lua` to customize:
- Zone coordinates for picking, processing, and selling
- Crop types and their properties
- Processing rewards
- Sell prices

### 4. Build the UI (Development Only)

If you modified the React UI:

```bash
cd web
npm install
npm run build
```

## Usage

### For Players

1. Go to the farm location (marked with blip on map)
2. Target crop zones and select "Pick [Crop]"
3. Bring raw crops to the processing station
4. Process raw crops into sellable products
5. Sell products at the market location

### Configuration

Edit `config.lua` to customize the resource:

```lua
Config.UseQbTarget = false  -- Set to true for qb-target, false for ox_target

Config.Zones = {
    Picking = {
        coords = vector3(0.0, 0.0, 0.0),
        radius = 10.0
    },
    Processing = {
        coords = vector3(0.0, 0.0, 0.0)
    },
    Selling = {
        coords = vector3(0.0, 0.0, 0.0)
    }
}

Config.Crops = {
    wheat = {
        label = "Wheat",
        rawItem = "wheat",
        processedItem = "flour",
        processTime = 5000,
        pickTime = 3000
    },
    -- Add more crops...
}
```

## Items

Add these items to your ox_inventory:

| Item | Label | Description |
|------|-------|-------------|
| wheat | Wheat | Raw wheat |
| corn | Corn | Raw corn |
| tomato | Tomato | Fresh tomato |
| flour | Flour | Processed wheat |
| cornmeal | Cornmeal | Processed corn |
| tomatosauce | Tomato Sauce | Processed tomatoes |

## API Events

### Client Events

```lua
TriggerEvent('farmingjob:client:openMenu')
```

### Server Events

```lua
TriggerServerEvent('farmingjob:server:pickCrop', cropName)
TriggerServerEvent('farmingjob:server:processCrop', cropName)
TriggerServerEvent('farmingjob:server:sellItem', itemName, amount)
```

## Security Features

- Distance validation on all actions
- Item existence verification before processing/selling
- Cooldown system to prevent spam
- Server-side rate limiting

## License

This resource is provided as-is for educational purposes.
# Farming Job Resource

A FiveM farming job resource for QBCore framework with ox_inventory, ox_lib, and React NUI support.

## Features

- Pick crops at farm zones (wheat, corn, tomato)
- Process raw crops into sellable products
- Sell processed goods at the market
- Progress bar animations with ox_lib
- Beautiful React NUI menu
- Support for qb-target and ox_target
- Secure server-side validation with anti-exploit measures

## Requirements

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)
- [qb-target](https://github.com/qbcore-framework/qb-target) OR [ox_target](https://github.com/overextended/ox_target)

## Installation

### 1. Add Items to ox_inventory

Copy the contents of `shared/items.lua` into your ox_inventory items file (usually `ox_inventory/data/items.lua`).

### 2. Ensure Proper Load Order

Add to your server.cfg ensuring dependencies load first:

```
ensure qb-core
ensure ox_lib
ensure oxmysql
ensure ox_inventory
ensure qb-target  # or ox_target
ensure farmingjob
```

### 3. Configure Zones (Optional)

Edit `config.lua` to customize:
- Zone coordinates for picking, processing, and selling
- Crop types and their properties
- Processing rewards
- Sell prices

### 4. Build the UI (Development Only)

If you modified the React UI:

```bash
cd web
npm install
npm run build
```

## Usage

### For Players

1. Go to the farm location (marked with blip on map)
2. Target crop zones and select "Pick [Crop]"
3. Bring raw crops to the processing station
4. Process raw crops into sellable products
5. Sell products at the market location

### Configuration

Edit `config.lua` to customize the resource:

```lua
Config.UseQbTarget = false  -- Set to true for qb-target, false for ox_target

Config.Zones = {
    Picking = {
        coords = vector3(0.0, 0.0, 0.0),
        radius = 10.0
    },
    Processing = {
        coords = vector3(0.0, 0.0, 0.0)
    },
    Selling = {
        coords = vector3(0.0, 0.0, 0.0)
    }
}

Config.Crops = {
    wheat = {
        label = "Wheat",
        rawItem = "wheat",
        processedItem = "flour",
        processTime = 5000,
        pickTime = 3000
    },
    -- Add more crops...
}
```

## Items

Add these items to your ox_inventory:

| Item | Label | Description |
|------|-------|-------------|
| wheat | Wheat | Raw wheat |
| corn | Corn | Raw corn |
| tomato | Tomato | Fresh tomato |
| flour | Flour | Processed wheat |
| cornmeal | Cornmeal | Processed corn |
| tomatosauce | Tomato Sauce | Processed tomatoes |



['raw_wheat'] = {
    label = 'Raw Wheat',
    weight = 100,
    stack = true,
    close = true,
    description = 'Fresh wheat picked from the farm'
},

['raw_corn'] = {
    label = 'Raw Corn',
    weight = 150,
    stack = true,
    close = true,
    description = 'Fresh corn from the farm'
},

['raw_tomato'] = {
    label = 'Raw Tomato',
    weight = 80,
    stack = true,
    close = true,
    description = 'Fresh tomatoes from the farm'
},

['flour'] = {
    label = 'Flour',
    weight = 200,
    stack = true,
    close = true,
    description = 'Processed flour from wheat'
},

['canned_corn'] = {
    label = 'Canned Corn',
    weight = 250,
    stack = true,
    close = true,
    description = 'Canned corn ready for sale'
},

['tomato_sauce'] = {
    label = 'Tomato Sauce',
    weight = 300,
    stack = true,
    close = true,
    description = 'Fresh tomato sauce ready for sale'
},



