#!/usr/bin/env bash

# File to store last known release version
LAST_KNOWN_VERSION_FILE="./last_minecraft_version.txt"

# Fetch the manifest
VERSION_MANIFEST_URL="https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
JSON=$(curl -s "$VERSION_MANIFEST_URL")

# Extract the latest release version
LATEST_RELEASE=$(echo "$JSON" | jq -r '.latest.release')

echo "Latest Minecraft Java Edition release: $LATEST_RELEASE"

# Check if last known file exists
if [[ -f "$LAST_KNOWN_VERSION_FILE" ]]; then
    LAST_KNOWN=$(cat "$LAST_KNOWN_VERSION_FILE")
    if [[ "$LATEST_RELEASE" != "$LAST_KNOWN" ]]; then
        echo "New release detected! Previous: $LAST_KNOWN, New: $LATEST_RELEASE"
        # You can trigger your announcement here, e.g.:
        # ./announce.sh "$LATEST_RELEASE"
        # Update the file
        echo "$LATEST_RELEASE" > "$LAST_KNOWN_VERSION_FILE"
    else
        echo "No new release. Latest is still $LATEST_RELEASE."
    fi
else
    # File doesn't exist; create it
    echo "$LATEST_RELEASE" > "$LAST_KNOWN_VERSION_FILE"
    echo "Initialized version file with $LATEST_RELEASE"
fi
