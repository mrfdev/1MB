# NoMonsterPickup (v1.1.0)

Paper 1.21.8 plugin that prevents **all Monster** entities from picking up items / **except regular Piglins** (so gold bartering continues to work). Piglin Brutes and Zombified Piglins are still blocked.

## Build (Gradle)

1. Ensure Java 21+ and Gradle are installed.
2. In this folder, run:
   ```bash
   gradle build
   ```
   or with wrapper if you add it:
   ```bash
   ./gradlew build
   ```
3. Output JAR: `build/libs/NoMonsterPickup-1.1.0.jar`

## Install

- Drop the JAR into your server `plugins/` folder.
- Restart the server.
- No config or permissions required.

## Notes

- Uses `EntityPickupItemEvent` and checks `instanceof Monster` but **skips** cancel if entity is a `Piglin`.
- Designed for global behavior. If you want region-specific behavior later, we can add WorldGuard integration.

## Credits
- Simple base code by Killian
- Added bartering exception by Floris
- jar for 1MoreBlock.com