negans_farming is a QBCore farming and juice-making job for FiveM. Players harvest fruit from searchable trees, learn hidden juice mixtures, sell drinks to a buyer, build XP and reputation, and unlock rarer fruit and recipes over time.

The script is built around ox_lib, ox_inventory, and ox_target, with a qb-target fallback for targeting.

What This Script Does
Adds a full fruit farming job loop: pick fruit, buy supplies, craft juice, drink juice, and sell products.
Uses 3rd eye targeting for harvesting fruit from existing world trees, saved admin tree spots, or invisible configured zones.
Gives each player farming XP, levels, reputation, discovered recipes, and daily buyer progress.
Hides locked fruit until the player reaches the required level.
Makes juice recipes discovery based. Players must figure out the correct fruit, sugar, ice, and bottle mixture.
Saves discovered recipes to a NUI recipe journal.
Adds daily buyer orders that pay bonus money for specific juices.
Adds farm tools such as baskets, gloves, and shears for better harvests and easier skill checks.
Adds drinkable juice items with thirst restoration.
Adds a sickness system when players drink too many juices too quickly.
Adds animations and props for picking, pressing juice, drinking, and selling.
Adds an in-game tutorial so players can learn the job without reading server documentation.
Adds admin commands for XP, reputation, recipe resets, sickness testing, and custom tree setup.
Player Job Loop
Players start with low farming XP and can only harvest beginner fruit.
They use 3rd eye on searchable trees or configured harvest spots to pick fruit.
Picking uses an ox_lib skill check, animation, and prop.
Fruit gives farming XP and can unlock new fruit types at higher levels.
Players buy supplies like sugar, ice, and empty bottles.
At the juice press, players enter ingredient amounts and try to discover recipes.
Correct mixtures produce bottled juices and save the recipe to the player's journal.
Wrong mixtures can waste part of the batch and may return failed mash.
Players sell fruit and juice to the buyer through a custom sell UI.
Selling gives cash, XP, reputation, and possible daily order bonuses.
Main Features
Farming XP and Fruit Unlocks
Fruit is locked by level. Locked fruit does not show targets or blips until the player has enough XP.

Default progression:

Level 1: Apple
Level 2: Orange
Level 3: Strawberry
Level 4: Peach
Level 5: Pineapple
Level 6: Dragon fruit
You can change levels, XP rewards, harvest amounts, and blips in shared/config.lua.

Searchable Real Trees
The script is set up so players can search existing map trees instead of relying on spawned tree props.

Important defaults:

Config.Picking.SpawnNodeProps = false
Config.SearchableTrees.Enabled = true
Tree model lists are in Config.SearchableTrees.Models. If a tree in your map does not show the farming option, add that model name or hash to the correct fruit list.

Admins can also create saved harvest spots in game:

/farming_addtree apple
/farming_addtree orange
/farming_addtree strawberry
/farming_addtree peach
/farming_addtree pineapple
/farming_addtree dragonfruit
/farming_trees
/farming_removetree tree_id
/farming_refreshtrees
Saved custom tree spots are stored in data/custom_trees.json.

Juice Crafting and Hidden Recipes
The juice press does not reveal recipe ingredients. Players enter ingredient counts through ox_lib input dialogs and must discover the correct mixtures.

When a player discovers a recipe:

The server validates the recipe.
Ingredients are removed.
The juice item is given.
Crafting XP is awarded.
The recipe is saved to that player's discovered recipe journal.
Rare recipes can require reputation tiers before they can be crafted.

NUI Farming Journal
Players can open the farming journal with:

/farmingjournal
Default keybind: F7
The journal shows:

Farming XP and level progress
Reputation tier progress
Daily buyer orders
Tool status
Fruit unlocks with locked silhouettes
Discovered recipes
The journal is hidden on resource start and only opens when the player uses the command/keybind or presses a UI button from the farming menus.

Daily Buyer Orders
Daily orders rotate once per UTC day using Config.Orders.RotateHourUTC.

Orders request specific juices and pay bonus money until that player's daily amount is fulfilled. After the requested amount is sold, the player can still sell the juice at the normal price.

Reputation Tiers
Selling fruit and juice gives farming reputation. Higher reputation improves sale prices and unlocks rare recipes.

Default tiers:

Roadside Seller: base pricing
Market Regular: +5% sale prices
Orchard Favorite: +10% sale prices and Orchard Reserve access
Juice Baron: +16% sale prices and Negan's Special access
Farm Tools
Players get passive bonuses by carrying the right tool items.

Harvest Basket: increases fruit yield by 1.
Farm Gloves: makes harvest skill checks easier.
Pruning Shears: lowers harvest cooldowns and speeds up picking.
Tool bonuses are configured in shared/config.lua.

Drinkable Juices and Sickness
Juices are usable items through ox_inventory. Drinking a juice plays an animation, restores thirst, and counts toward the sickness system.

If a player drinks too many juices within the configured time window, they get sick and receive the configured screen/movement effects.

This keeps juices useful while preventing players from spamming them endlessly.

In-Game Tutorial
Players can open the tutorial with:

/farmingtutorial
The tutorial walks players through the job and can set GPS waypoints for important locations such as harvesting, supplies, the juice press, and the buyer.

Automatic tutorial prompts are disabled by default, so the tutorial will not open on server/resource start.

Dependencies
Required:

ensure qb-core
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure negans_farming
qb-target can be used instead of ox_target, but this resource is tuned for ox_target.

Installation
Put the negans_farming folder in your server resources.
Add the ensure lines above after your core dependencies.
Import sql/install.sql, or leave Config.SQL.AutoCreate = true.
Add the ox_inventory item definitions from install/ox_inventory_items.lua.
Restart the server or ensure the resource after dependencies are loaded.
For ox_inventory, copy the paste-ready entries from:

install/ox_inventory_items.lua
Paste them into:

ox_inventory/data/items.lua
Keep the drink item client.event values. Those events are what make the drinks usable and connect them back to this script.

The included install/qb_core_items.lua file is only a fallback reference. Since this setup uses ox_inventory, you do not need to install the QBCore item block.

The item snippets include:

Fruit
Sugar, ice, and empty bottles
Farm tools
Failed mash
Normal juices
Rare reputation drinks
Configuration Files
shared/config.lua: main gameplay config, locations, XP, tools, orders, sickness, tutorial, trees, and sale prices.
server/recipes.lua: hidden juice recipes, recipe rewards, required reputation, drink thirst values, and craft XP.
shared/items.lua: item labels and shared item helpers used by the resource.
install/ox_inventory_items.lua: paste-ready ox_inventory items.
sql/install.sql: database tables for XP, reputation, recipes, tutorials, and daily orders.
data/custom_trees.json: admin-created searchable tree spots.
Owner Recipe Spoilers
These recipes are intentionally hidden from players. Do not put this section in public player-facing documentation if you want recipe discovery to matter.

Apple Juice: 4 apples, 1 sugar
Orange Juice: 4 oranges, 1 ice
Strawberry Blend: 5 strawberries, 1 apple, 1 sugar, 1 ice
Peach Punch: 3 peaches, 1 orange, 2 sugar, 1 ice
Tropical Mix: 3 pineapples, 1 orange, 1 strawberry, 1 sugar, 2 ice
Dragon Smoothie: 2 dragon fruit, 1 pineapple, 2 strawberries, 2 sugar, 2 ice
Orchard Reserve: 2 peaches, 2 pineapples, 2 apples, 2 sugar, 2 ice. Requires Orchard Favorite reputation.
Negan's Special: 3 dragon fruit, 2 pineapples, 1 peach, 2 strawberries, 3 sugar, 3 ice. Requires Juice Baron reputation.
Each successful recipe also requires one empty bottle when Config.Production.RequireBottle = true.

Commands
Player commands:

/farmingjournal: opens the farming journal.
/farmingtutorial: opens the job tutorial.
Admin commands:

/farming_setxp id amount
/farming_addxp id amount
/farming_setrep id amount
/farming_addrep id amount
/farming_resetrecipes id
/farming_testsick id
/farming_addtree fruit
/farming_trees
/farming_removetree tree_id
/farming_refreshtrees
Admin permission defaults to admin and can be changed at Config.Admin.Permission.

Notes
This resource is configured for ox_inventory.
Item images are not included. Add PNGs matching item names to your inventory image folder if you want custom icons.
If the farming UI opens on start, make sure you are using the included web/index.html, web/app.js, and latest client/main.lua.
If players cannot see a harvest option on a real tree, add that tree model to Config.SearchableTrees.Models.
If you want only real searchable trees, remove or move the default entries in Config.Fruits[*].zones.
If you want the job to be harder, increase skill check difficulty, lower harvest amounts, raise recipe costs, or reduce sale prices.
If you want the economy to be more generous, increase daily order bonuses, reputation multipliers, or XP rewards.
Upgrade Ideas
Save harvest cooldowns in the database so picked trees stay depleted across reconnects.
Add Discord webhook logging for rare recipe crafts, large sales, and suspicious activity.
Add illegal or premium recipes for a riskier late-game branch.
Add seasonal fruit rotations or event-only daily buyer orders.
