# CmiSlowChat

A tiny Paper 1.21.10+ add-on that adds a global slow-chat cooldown for all players,
with an optional short `/cmi mute` to integrate with CMI's mute system.

## Features

- Paper-only (uses `AsyncChatEvent`)
- Global cooldown for all normal chat messages
- Bypass permission: `cmi.slowchat.bypass`
- Configurable cooldown seconds
- Optional integration with CMI:
  - If enabled and CMI is present, issues `/cmi mute <player> <duration> <reason>` when a player hits the cooldown.

## Build

You need **Java 21+** and **Gradle** installed (or use the Gradle wrapper if you add one).

```bash
cd CmiSlowChat
gradle build
```

The compiled plugin jar will be in `build/libs/CmiSlowChat-1.0.0.jar`.

## Install

1. Drop the jar into your `plugins/` folder on a Paper 1.21.10+ server.
2. Start/restart the server.
3. Edit `plugins/CmiSlowChat/config.yml` if you want to adjust:
   - `cooldown-seconds`
   - `use-cmi-mute`
   - `cmi-mute-duration`
   - `cmi-mute-reason`
4. Reload/restart to apply config changes, or use a plugin manager.

## Permissions

- `cmi.slowchat.bypass` — players with this permission are not affected by the slow-chat cooldown.
