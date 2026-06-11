# negans_farming

Comprehensive QBCore fruit farming resource with:

- XP based fruit unlocks. Locked fruit targets and blips are not created until the player reaches the required level.
- 3rd eye picking through `ox_target`, with `qb-target` fallback.
- Real tree harvest spots. Existing map tree models can be searched directly, prop spawning is disabled by default, and admins can save extra harvest spots in game.
- `ox_lib` skill checks, input dialogs, context menus, notifications, and progress circles.
- Harvest, press, drink, and sell animations with props.
- Hidden juice mixtures. Players experiment with fruit, sugar, and ice; successful recipes are saved to their known recipe book.
- NUI farming journal with XP progress, reputation, buyer orders, tool status, locked fruit silhouettes, and discovered recipes.
- In-game tutorial with step-by-step guide, GPS waypoints, and `/farmingtutorial`.
- Daily buyer orders with capped per-player bonus payouts for selected juices.
- Farm tools that improve picking yield, skill checks, cooldowns, or animation time when carried.
- Reputation tiers that increase sale prices and unlock rare recipes.
- Admin commands for XP, reputation, recipe resets, and sickness testing.
- Drinkable juices. Drinking too many within the configured window makes the player sick.
- Selling buyer with a custom `ox_lib` UI instead of an inventory shop.
- Configured for `ox_inventory`.

## Dependencies

Required:

```cfg
ensure qb-core
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure negans_farming
```

`qb-target` can be used instead of `ox_target`, but this resource is tuned for ox.

## Install

1. Put `negans_farming` in your resources folder.
2. Add the ensure lines above after your core dependencies.
3. Import `sql/install.sql`, or leave `Config.SQL.AutoCreate = true`.
4. Add item definitions.

For `ox_inventory`, copy the paste-ready entries from `install/ox_inventory_items.lua` into `ox_inventory/data/items.lua`. Keep the drink item `client.event` values so drinks call this resource.

The `qb_core_items.lua` file is only included as a fallback reference. Since you use `ox_inventory`, you do not need to install the QBCore item block.

The install snippets include fruit, supplies, farm tools, failed mash, normal juices, and rare reputation drinks.

## Gameplay

Players start at level 1 and can only see apple picking spots. XP unlocks oranges, strawberries, peaches, pineapples, and dragon fruit. The juice press lets players enter ingredient counts without revealing recipes. Correct recipes produce bottled drinks and save to the player's known recipe UI. Wrong mixtures consume part of the batch and can return ruined mash.

The buyer ped opens a custom sell menu, shows sellable fruit and drinks with reputation-adjusted prices, flags daily order bonuses, runs a negotiation skill check, then pays cash and awards farming XP and reputation.

Use `/farmingtutorial` to open the step-by-step guide. Each tutorial step can set a GPS waypoint. Automatic tutorial popups are disabled by default so no farming UI opens on server/resource start.

Use `/farmingjournal` or the default `F7` keybind to open the NUI journal. The juice press and buyer menus include buttons for both the journal and tutorial.

Daily buyer orders rotate once per UTC day at `Config.Orders.RotateHourUTC`. Each order has a per-player sold amount, so bonus payouts stop after the daily request is fulfilled.

## Real Tree Setup

The script no longer spawns visual tree props by default. `Config.Picking.SpawnNodeProps = false`, so harvest targets attach to existing map/YMAP trees or saved coordinates.

`Config.SearchableTrees.Enabled = true` lets players third-eye existing world tree models directly. Tree model lists live in `Config.SearchableTrees.Models`. If a map tree does not show a search option, add that tree model name or hash to the right fruit list.

Admin tree editor commands:

- `/farming_addtree apple`
- `/farming_addtree orange`
- `/farming_addtree strawberry`
- `/farming_addtree peach`
- `/farming_addtree pineapple`
- `/farming_addtree dragonfruit`
- `/farming_trees`
- `/farming_removetree tree_id`
- `/farming_refreshtrees`

To add a custom saved spot, stand where players should third-eye the real tree, face it if you want, and run `/farming_addtree apple`. The spot is saved to `data/custom_trees.json` and refreshes for all players immediately.

The original config zones still work as invisible target spots. Remove or move entries in `Config.Fruits[*].zones` if you only want searchable model trees and your custom saved trees.

Carry these tools for passive bonuses:

- Harvest Basket: +1 fruit yield while picking.
- Farm Gloves: easier picking skill checks.
- Pruning Shears: shorter crop cooldowns and faster picking animations.

Reputation tiers improve selling prices and unlock rare blends:

- Roadside Seller: base pricing.
- Market Regular: +5% sale prices.
- Orchard Favorite: +10% sale prices and Orchard Reserve access.
- Juice Baron: +16% sale prices and Negan's Special access.

## Owner Recipe Spoilers

These are intentionally hidden from players:

- Apple Juice: 4 apples, 1 sugar
- Orange Juice: 4 oranges, 1 ice
- Strawberry Blend: 5 strawberries, 1 apple, 1 sugar, 1 ice
- Peach Punch: 3 peaches, 1 orange, 2 sugar, 1 ice
- Tropical Mix: 3 pineapples, 1 orange, 1 strawberry, 1 sugar, 2 ice
- Dragon Smoothie: 2 dragon fruit, 1 pineapple, 2 strawberries, 2 sugar, 2 ice
- Orchard Reserve: 2 peaches, 2 pineapples, 2 apples, 2 sugar, 2 ice. Requires Orchard Favorite reputation.
- Negan's Special: 3 dragon fruit, 2 pineapples, 1 peach, 2 strawberries, 3 sugar, 3 ice. Requires Juice Baron reputation.

Each successful recipe also requires one empty bottle when `Config.Production.RequireBottle = true`.

## Configuration

Edit `shared/config.lua` for:

- Fruit levels, XP, target locations, harvest amounts, props, and blips.
- Skill check difficulty.
- Juice press location and prop.
- Supply shop prices.
- Buyer ped, sale prices, money account, and negotiation bonus.
- Sickness threshold and visual effect duration.
- Reputation tiers, daily orders, admin command names, and farm tool bonuses.
- Tutorial text, first-time prompt behavior, command name, and waypoint locations.
- Searchable tree model lists, tree editor settings, and whether harvest props should spawn.

Edit `server/recipes.lua` for hidden recipe ingredients, drink items, craft XP, and thirst values.

## Notes

- If you want fruit to be harder to discover, keep recipe spoilers out of public docs and only rebalance `Config.Recipes` in `server/recipes.lua`.
- Some prop models may vary by game build. If a node prop does not appear, replace the `nodeProp` model in `Config.Fruits`.
- `ox_inventory` item images are not included; add PNGs matching item names if you want custom icons.

## Admin Commands

Permission defaults to `admin` and can be changed at `Config.Admin.Permission`.

- `/farming_setxp id amount`
- `/farming_addxp id amount`
- `/farming_setrep id amount`
- `/farming_addrep id amount`
- `/farming_resetrecipes id`
- `/farming_testsick id`

## Upgrade Ideas

- Save harvest cooldowns in the database if you want crops to stay depleted across reconnects.
- Add webhook logging for large sales, failed exploit checks, and high-value recipe crafting.
- Add optional illegal/rare recipes if you want a riskier late-game branch.
