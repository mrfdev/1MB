#!/usr/bin/env bash

# 1MB-VersionManifest.sh
# version 0.0.2, build 004, Floris Fiedeldij Dop - Feel free to use

# Description:
#   Checks Mojang's Minecraft Java Edition version manifest for the latest release,
#   compares with your locally known version, and lets you know if there is a new release.
#
#   Optionally, use -list to print all version IDs (release, snapshot, prerelease, etc).

# Requirements:
#   - curl (default on macOS/Ubuntu)
#   - jq: macOS: brew install jq | Ubuntu: sudo apt install jq

# Usage:
#   Make executable: chmod +x 1MB-VersionManifest.sh
#   Automate:       Add to cron or a scheduled task for regular checks
#   ./1MB-VersionManifest.sh           # Check latest release and compare
#   ./1MB-VersionManifest.sh -list     # Print all known version IDs

# Notes:
#   Stores last known release in ./last_minecraft_version.txt (in the current directory).
#   Edit the script to trigger your own announcements or webhooks when a new release is found.

# Config
LAST_KNOWN_VERSION_FILE="./last_minecraft_version.txt"
VERSION_MANIFEST_URL="https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"

# --- Dependency check ---
for cmd in curl jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf "Error: Required dependency '%s' is not installed or not in PATH.\n" "$cmd"
        exit 1
    fi
done

# --- Get the JSON ---
JSON=$(curl -fsSL "$VERSION_MANIFEST_URL")
if [ $? -ne 0 ] || [ -z "$JSON" ]; then
    printf "Error: Failed to fetch version manifest from Mojang.\n"
    exit 1
fi

# --- List all versions if -list param is given ---
if [ "$1" = "-list" ]; then
    printf "Available Minecraft Java Edition versions:\n"
    printf '%s\n' "$JSON" | jq -r '.versions[].id'
    exit 0
fi

# --- Get the latest release version ---
LATEST_RELEASE=$(printf '%s' "$JSON" | jq -r '.latest.release')
printf "Latest Minecraft Java Edition release: %s\n" "$LATEST_RELEASE"

# --- Compare with last known version file ---
if [[ -f "$LAST_KNOWN_VERSION_FILE" ]]; then
    LAST_KNOWN=$(cat "$LAST_KNOWN_VERSION_FILE")
    if [[ "$LATEST_RELEASE" != "$LAST_KNOWN" ]]; then
        printf "New release detected! Previous: %s, New: %s\n" "$LAST_KNOWN" "$LATEST_RELEASE"
        # You can trigger your own webhook/announcement logic here
        printf '%s' "$LATEST_RELEASE" > "$LAST_KNOWN_VERSION_FILE"
    else
        printf "No new release. Latest is still %s.\n" "$LATEST_RELEASE"
    fi
else
    # File doesn't exist; create it
    printf '%s' "$LATEST_RELEASE" > "$LAST_KNOWN_VERSION_FILE"
    printf "Initialized version file with %s\n" "$LATEST_RELEASE"
fi
