# 1MB-Debug

```
# @Package: 1MB-Debug
# @Version: 1.0, build 002
# @Release: September 6th, 2020
# @Description: This helps you quickly add a 1.16.1 debug world to your multiplayer server.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: floris#0233 on https://discord.gg/KzTDhxv
# @URL: Latest update, wiki, & support: https://scripts.1moreblock.com/
```

## Information:

You can manage the your server how you want, basically you just want to import the world into your existing setup.

This is made for Paper 1.16.1, not for any other version. Once my own server goes to 1.16.2, I will update this package.

The world is a singleplayer world that's been created, chunks loaded, states saved, etc. And converted to work with Paper 1.16.1 specifically. Though it should be fine loading this in Spigot or Tuinity. 

### Important to understand: Touch anything, and chunks update, meaning game mechanics come into play. Things will 'pop off', etc. This is meant as a 'view only' world.


## Installation:

- Put the /debug/ world folder in the same directory as your other worlds.

- Then in-game, type: /mvimport debug normal

- Optionally, make sure players are in spectator mode, and that your spawnpoint is set properly. I've included my worlds.yml file as an example guilde.

- To manually do this, you can go to the world: /mvtp debug, once you're in the right spot, change to creative mode, and land on a block. Then type: /mvset spawn, and go back into spectator mode. Then /mvm set gamemode spectator. And /save-all

- Don't forget to add the permission to the group for those who should have access to this world: /lp group GROUPNAME permission set multiverse.access.debug true

- Optionally, you can set a worldborder (note that in spectator mode players can go past the Mojang worldborder, I use worldborder plugin to prevent this) Worldborder plugin: /wb set 200 200 135 135, Mojang worldborder: /minecraft:worldborder center 135 135, and then /minecraft:worldborder set 400

