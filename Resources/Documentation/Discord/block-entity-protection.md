You can blocks and certain entities sometimes. 

For example: containers, such as hoppers, dispensers, barrels, shulkerboxes, chests, furnaces..
For example: doors, such as double doors, cherry door, trapdoor, iron door..
For example: entities, such as hopper minecart, banners, paintings..

This used to be handled by a legacy plugin called LWC, they provided, /lock and /unlock, and such.

We now use BOLT, and it has migrated all the LWC data, and we've mapped the old /lock, /unlock commands to the new /bolt commands. 

For best performance, and most pro usages: /bolt, with a sub command and parameter is giving you the best result. 

The Github (it's open source) and the tech Wiki, is here: <https://github.com/pop4959/Bolt/wiki>

But as a player; you probably just want to use /lock, /unlock, /cmodify, /cdisplay, and /trust.

Here are their /bolt equivelants:

## Lock
Usage: `/bolt lock [type] (alias: /lock [type])`
Description: Lock something. Optionally provide a protection type to lock with (defaults to private).
Basically the old /lock

## Unlock
Usage: `/bolt unlock (alias: /unlock)`
Description: Unlock something.
Basically the old /unlock

## Edit
Usage: `/bolt edit (add|remove) <player>`
Description: Edit a protection to add or remove a player's access.
Basically the old /cmodify

## Modify
Usage: `/bolt modify (add|remove) <access> <source-type> <sources...>`
Description: Add or remove sources with given access to a protection's access list (ACL).

There are a few notable built-in access source types:

player for players
password for passwords entered with /bolt password
permission for permission nodes
group for groups managed by /bolt group

## Group
Usage: `/bolt group (create|delete|add|remove|list) <group> [players...]`
Description: Manage custom player groups, which can be used in access lists (ACLs).

## Trust
Usage: `/bolt trust (add|remove) <source-type> <source> [access]`
Description: Prompt, list, or confirm changes to your trust access list.
Basically the old /trust

## Transfer
Usage: `/bolt transfer <player>`
Description: Transfer a protection that you own to another player.

## Password
Usage: `/bolt password <password>`
Description: Enter a password for a protection that has a password source added.

## Mode
Usage: `/bolt mode <mode>`
Description: Toggle a player mode. For example: persist, no lock, no spam.

## Help
Usage: `/bolt help [command]`
Description: Displays help.

## Info
Usage: `/bolt info`
Description: Display protection information.
Basically the old /cinfo

- Wilderness: should auto protect things you place
- Game type worlds such as oneblock: should not auto protect things you place

- if a chest is supposed to be public, but hopper items no longer go into it, try `/bolt lock withdraw` or even bolt lock public

- Ownership is important: if you have hoppers, minecarts with chests, barrels etc for sorters, make sure they're all owned by the same person.

- Sometimes things are a bit flaky due to old flags and or protections. In that case, remember that minecarts might need to be locked or unlocked as well. And you could use /cpersist and /lock or /unlock to make mass changes, then /cpersist again to stop persistance. And you could potentially just break the protections and place them again.

