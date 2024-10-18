A ShopChest is a plugin that lets a player place a chest, and use the item they're holding to create a shop.

A player can also buy from someone's ShopChest by interacting with it, or sell to it, if that's set up.

There are admin-shops which have infinite quota, and player-shops, which need to be restocked by the player.

Keep the value of /worth in mind, so you don't sell something cheap, that others then can /sell for more. Stuff like that.

To create a shopchest, place a chest, hold the item, and if you want to sell 5 of them at once, for a total price of $500, and not allow players to sell it back to you, type this:
```
/shops create 5 500 0
```
Then hit the chest with the item. It will show you if it's successfully created a shopchest.

Note: Each shopchest you create will cost you $500.

Any money regarding this plugin goes through the global /balance

ShopChests can be created in all worlds.

Players: right-click an existing ShopChest to BUY the items from the owner of the shopchest. If you have enough money then you get the items, and the money disappears from your /balance
And if they allow you to sell back to the shopchest, left-click.