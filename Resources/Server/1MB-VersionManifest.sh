#!/usr/bin/env bash

# 1MB-VersionManifest.sh
# version 0.0.1, build 003, Floris Fiedeldij Dop - Feel free to use

# Checks the latest Minecraft Java Edition release version using Mojang's public API.
# Stores the last-seen version in last_minecraft_version.txt.
# Notifies if a new version is detected.

# REQUIREMENTS:
#   - curl (default on macOS/Ubuntu)
#   - jq: macOS: brew install jq | Ubuntu: sudo apt install jq

# USAGE:
#   1. Make executable: chmod +x 1MB-VersionManifest.sh
#   2. Run manually:   ./1MB-VersionManifest.sh
#   3. Automate:       Add to cron or a scheduled task for regular checks

# Customize the "New release detected!" section for announcements/webhooks.

# Config
LAST_KNOWN_VERSION_FILE="./last_minecraft_version.txt"
VERSION_MANIFEST_URL="https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"

# Internal config
JSON=$(curl -s "$VERSION_MANIFEST_URL")
LATEST_RELEASE=$(printf '%s' "$JSON" | jq -r '.latest.release')

# Let's get started
printf "Latest Minecraft Java Edition release: %s\n" "$LATEST_RELEASE"

if [[ -f "$LAST_KNOWN_VERSION_FILE" ]]; then
    LAST_KNOWN=$(cat "$LAST_KNOWN_VERSION_FILE")
    if [[ "$LATEST_RELEASE" != "$LAST_KNOWN" ]]; then
        printf "New release detected! Previous: %s, New: %s\n" "$LAST_KNOWN" "$LATEST_RELEASE"
        # Add your announcement or update logic here (e.g. webhook, Discord, etc)
        printf '%s' "$LATEST_RELEASE" > "$LAST_KNOWN_VERSION_FILE"
    else
        printf "No new release. Latest is still %s.\n" "$LATEST_RELEASE"
    fi
else
    printf '%s' "$LATEST_RELEASE" > "$LAST_KNOWN_VERSION_FILE"
    printf "Initialized version file with %s\n" "$LATEST_RELEASE"
fi
# EOF
