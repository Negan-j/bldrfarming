# ox_inventory Install

1. Open `ox_inventory/data/items.lua`.
2. Copy every entry from `install/ox_inventory_items.lua`.
3. Paste them inside the item table in `items.lua`, before the final closing `}`.
4. Restart `ox_inventory`, then restart `negans_farming`.

Do not paste the `qb_core_items.lua` file if you use `ox_inventory`.

The drink items already call:

```lua
client = { event = 'negans_farming:client:drinkItem' }
```

Keep that line on each drink item or drinking/sickness will not run.
