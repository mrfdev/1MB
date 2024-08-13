# 1MB-Debug: A Minecraft Debug World on MultiPlayer servers
```
@Package: 1MB-Debug
@Version: 2.1, build 004
@Release: August 13th, 2024
@Description: Quickly add a 1.21.1 debug world to your multiplayer server.
@Contact: I am @floris on Twitter, and mrfloris in MineCraft.
@Discord: mrfloris on https://discord.gg/floris
@URL: Latest update, wiki, & support: https://scripts.1moreblock.com/
```

## Overview

The 1MB-Debug package allows you to easily integrate a pre-configured debug world into your multiplayer server running Paper 1.21.1. This world is designed as a "view-only" environment, where game mechanics should not be altered. However, note that interacting with the world may cause chunks to update, triggering in-game mechanics.

This package is specifically tailored for Paper 1.21.1 and may not be compatible with other versions. Once my server updates to 1.22, I plan to release an updated version of this package.

## Installation Guide

### Step 1: Import the Debug World
1. Place the `/debug/` world folder into the directory containing your server’s other worlds.
2. In-game, run the following command:  
   ```
   /mvimport debug normal
   ```

### Step 2: Configure the World (Optional)
- Ensure players are in spectator mode, and set your spawn point correctly. An example `worlds.yml` file is included as a guide.
- The `worlds.yml` is not set to auto-load. To load the world manually on your next server start, use:  
  ```
  /mvload debug
  ```

### Step 3: Set Up the World
1. Teleport to the debug world:  
   ```
   /mvtp debug
   ```
2. Switch to creative mode, position yourself, then set the spawn point:  
   ```
   /mvsetspawn
   ```
3. Switch back to spectator mode and set the default game mode:  
   ```
   /mvm set gamemode spectator
   ```
4. Save your settings:  
   ```
   /save-all flush
   ```

### Step 4: Manage Permissions
- Grant access to the debug world for the appropriate group using LuckPerms:  
  ```
  /lp group GROUPNAME permission set multiverse.access.debug true
  ```

### Step 5: Set a World Border (Optional)
- To prevent players in spectator mode from bypassing the world border, you can set a custom world border using the WorldBorder plugin:
  ```
  /wb set 200 200 135 135
  ```
- Set the Mojang world border:
  ```
  /minecraft:worldborder center 135 135
  /minecraft:worldborder set 400
  ```
  *(Adjust the values based on your server’s requirements for version 1.21.1, as the world size may vary with each release.)*
