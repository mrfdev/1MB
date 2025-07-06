#!/usr/bin/env bash

# 1MB-VersionManifest.sh
# version 0.0.5, build 007, Floris Fiedeldij Dop - Feel free to use

# Description:
#   Checks Mojang's Minecraft Java Edition version manifest for the latest release,
#   compares with your locally known version, and lets you know if there is a new release.
#
#   Optionally, use -list to print all version IDs (release, snapshot, prerelease, etc).
#   Always prints Mojang and Wiki changelog links for the latest version.
#
#   On each run, can notify a Discord channel via webhook with release details.

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
#   Edit the config section below to set your Discord webhook if you want notifications.

# --- Config ---
LAST_KNOWN_VERSION_FILE="./last_minecraft_version.txt"
VERSION_MANIFEST_URL="https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"

# Set this to your Discord webhook URL if you want Discord notifications for new Minecraft releases.
# To create a webhook: Discord → Channel Settings → Integrations → Webhooks → New Webhook → Copy URL
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE"

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

# --- Changelog Links ---
MOJANG_VER="${LATEST_RELEASE//./-}"
MOJANG_CHANGELOG_URL="https://www.minecraft.net/en-us/article/minecraft-java-edition-$MOJANG_VER"
WIKI_CHANGELOG_URL="https://minecraft.wiki/w/Java_Edition_$LATEST_RELEASE"

printf "Mojang Changelog: %s\n" "$MOJANG_CHANGELOG_URL"
printf "Wiki Changelog:   %s\n" "$WIKI_CHANGELOG_URL"

# --- Compare with last known version file ---
if [[ -f "$LAST_KNOWN_VERSION_FILE" ]]; then
    LAST_KNOWN=$(cat "$LAST_KNOWN_VERSION_FILE")
    if [[ "$LATEST_RELEASE" != "$LAST_KNOWN" ]]; then
        printf "New release detected! Previous: %s, New: %s\n" "$LAST_KNOWN" "$LATEST_RELEASE"
        printf '%s' "$LATEST_RELEASE" > "$LAST_KNOWN_VERSION_FILE"
    else
        printf "No new release. Latest is still %s.\n" "$LATEST_RELEASE"
    fi
else
    # File doesn't exist; create it
    printf '%s' "$LATEST_RELEASE" > "$LAST_KNOWN_VERSION_FILE"
    printf "Initialized version file with %s\n" "$LATEST_RELEASE"
    LAST_KNOWN="(none)"
fi

# --- Always send Discord webhook if configured ---
if [[ "$DISCORD_WEBHOOK_URL" != "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE" && -n "$DISCORD_WEBHOOK_URL" ]]; then
    [ -z "$LAST_KNOWN" ] && LAST_KNOWN="(none)"
    DISCORD_JSON=$(jq -n \
      --arg title "Latest Minecraft Java Release" \
      --arg mojang "$MOJANG_CHANGELOG_URL" \
      --arg wiki "$WIKI_CHANGELOG_URL" \
      --arg last "$LAST_KNOWN" \
      --arg latest "$LATEST_RELEASE" \
      '{
        "embeds": [{
          "title": $title,
          "description": "Found latest Minecraft Java Edition release: `\($latest)` \n\n [Minecraft.net changelog](\($mojang))\n[Minecraft.wiki changelog](\($wiki))\n\nPrevious cached version: \($last)",
          "color": 3066993
        }]
      }'
    )
    curl -H "Content-Type: application/json" -X POST -d "$DISCORD_JSON" "$DISCORD_WEBHOOK_URL" >/dev/null 2>&1
fi
#EOF