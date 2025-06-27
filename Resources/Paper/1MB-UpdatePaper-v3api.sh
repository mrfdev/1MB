#!/usr/bin/env bash

set -e

##############################################################################
# PaperMC Server Updater Script - mrfloris-paper-script/1.0
# Maintainer: mrfloris (https://github.com/mrfdev/1MB)
#
# This script manages downloading/updating PaperMC jars, using the v3 API.
# Features:
#   - Maintains a cache of the current project, version, build, channel.
#   - Checks Paper's API for new builds, downloads only if new.
#   - Respects Paper's v3 requirements (custom User-Agent, download URLs).
#   - Cross-platform: works on macOS and Ubuntu.
#   - Does not run as root/sudo for safety.
##############################################################################

# ------------- User Settings & Variables -------------
CACHE_FILE=".papercache.json"
DEFAULT_PROJECT="paper"
DEFAULT_VERSION="1.21.6"         # Change as needed
DEFAULT_CHANNEL="STABLE"         # Options: STABLE, BETA, ALPHA, RECOMMENDED
USER_AGENT="mrfloris-paper-script/1.0 (https://github.com/mrfdev/1MB)"
API_BASE="https://fill.papermc.io/v3"

DEBUG=1   # Set to 1 for extra API output, 0 to disable

# ------------- Safeguards & Dependency Checks -------------

# Prevent running as root
if [ "$EUID" -eq 0 ]; then
    printf "\n[ERROR] *!* This script should NOT be run as root or with sudo.\n"
    printf "        Please run as your normal user.\n\n"
    exit 1
fi

# Check for jq (JSON parser)
if ! command -v jq >/dev/null 2>&1; then
    printf "\n[ERROR] The 'jq' command is required but was not found.\n"
    printf "Install it with:\n"
    printf "  macOS:  brew install jq\n"
    printf "  Ubuntu: sudo apt update && sudo apt install jq\n\n"
    exit 1
fi

# ------------- Cache Handling -------------
load_cache() {
    if [ -f "$CACHE_FILE" ]; then
        PROJECT=$(jq -r '.project' "$CACHE_FILE")
        VERSION=$(jq -r '.version' "$CACHE_FILE")
        BUILD=$(jq -r '.build' "$CACHE_FILE")
        CHANNEL=$(jq -r '.channel' "$CACHE_FILE")
    else
        PROJECT="$DEFAULT_PROJECT"
        VERSION="$DEFAULT_VERSION"
        BUILD="0"
        CHANNEL="$DEFAULT_CHANNEL"
        save_cache
    fi
}

save_cache() {
    printf '{\n'        > "$CACHE_FILE"
    printf '  "project": "%s",\n' "$PROJECT" >> "$CACHE_FILE"
    printf '  "version": "%s",\n' "$VERSION" >> "$CACHE_FILE"
    printf '  "build": "%s",\n' "$BUILD" >> "$CACHE_FILE"
    printf '  "channel": "%s"\n' "$CHANNEL" >> "$CACHE_FILE"
    printf '}\n'        >> "$CACHE_FILE"
}

# ------------- Paper API Query Logic -------------
fetch_latest_build_info() {
    API_URL="$API_BASE/projects/$PROJECT/versions/$VERSION/builds/latest"
    printf "[INFO] Querying PaperMC API for latest build...\n"
    printf "       URL: %s\n" "$API_URL"
    printf "       Channel: %s\n" "$CHANNEL"

    RESPONSE=$(curl -sSL -H "User-Agent: $USER_AGENT" "$API_URL")

    # DEBUG: Print raw response if debug mode is on
    if [ "$DEBUG" -eq 1 ]; then
        printf "\n[DEBUG] Raw API response:\n"
        printf "%s\n\n" "$RESPONSE"
    fi

    LATEST_BUILD_NUMBER=$(printf '%s' "$RESPONSE" | jq -r '.id')
    LATEST_DOWNLOAD_URL=$(printf '%s' "$RESPONSE" | jq -r '.downloads."server:default".url')
    LATEST_MC_VERSION="$VERSION"

    if [ -z "$LATEST_BUILD_NUMBER" ] || [ "$LATEST_BUILD_NUMBER" = "null" ]; then
        printf "\n[ERROR] Could not find a valid build number for version %s\n" "$VERSION"
        exit 1
    fi
    if [ -z "$LATEST_DOWNLOAD_URL" ] || [ "$LATEST_DOWNLOAD_URL" = "null" ]; then
        printf "\n[ERROR] Download URL missing in API response for build %s\n" "$LATEST_BUILD_NUMBER"
        exit 1
    fi

    printf "[INFO] Latest build for %s %s: %s\n" "$PROJECT" "$VERSION" "$LATEST_BUILD_NUMBER"
    printf "       Download URL: %s\n" "$LATEST_DOWNLOAD_URL"
    printf "       MC Version:   %s\n" "$LATEST_MC_VERSION"

    # Export for next steps
    LATEST_BUILD_INFO=(
        "$LATEST_BUILD_NUMBER"
        "$LATEST_DOWNLOAD_URL"
        "$LATEST_MC_VERSION"
    )
}

# ------------- MAIN SCRIPT FLOW -------------

load_cache

printf "\n[INFO] Loaded cache state:\n"
cat "$CACHE_FILE"
printf "\n"

fetch_latest_build_info

# Variables for this update/check session
LATEST_BUILD_NUMBER="${LATEST_BUILD_INFO[0]}"
LATEST_DOWNLOAD_URL="${LATEST_BUILD_INFO[1]}"
LATEST_MC_VERSION="${LATEST_BUILD_INFO[2]}"
JAR_BASENAME="paper-${VERSION}-${LATEST_BUILD_NUMBER}.jar"
JAR_PATH="./${JAR_BASENAME}"
BACKUP_DIR="./backups"

# --- Step 3: Compare, Download, and Backup if Needed ---

printf "\n[INFO] Cached build: %s\n" "$BUILD"
printf "[INFO] Latest build: %s\n" "$LATEST_BUILD_NUMBER"

if [ "$BUILD" = "$LATEST_BUILD_NUMBER" ]; then
    printf "\n[INFO] You already have the latest build (%s). No update needed.\n" "$BUILD"
    exit 0
fi

printf "\n[INFO] Newer build detected! Updating from build %s to %s\n" "$BUILD" "$LATEST_BUILD_NUMBER"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup the old jar, if present and not a placeholder build 0
if [ "$BUILD" != "0" ]; then
    OLD_JAR="paper-${VERSION}-${BUILD}.jar"
    if [ -f "$OLD_JAR" ]; then
        BACKUP_PATH="${BACKUP_DIR}/${OLD_JAR}-backup-$(date +%Y%m%d_%H%M%S)"
        printf "[INFO] Backing up old jar: %s -> %s\n" "$OLD_JAR" "$BACKUP_PATH"
        mv "$OLD_JAR" "$BACKUP_PATH"
    else
        printf "[WARN] Old jar %s not found, skipping backup.\n" "$OLD_JAR"
    fi
fi

# Download new jar
printf "[INFO] Downloading new jar to: %s\n" "$JAR_PATH"
curl -fSL -o "$JAR_PATH" -H "User-Agent: $USER_AGENT" "$LATEST_DOWNLOAD_URL"
if [ $? -eq 0 ]; then
    printf "[INFO] Download successful: %s\n" "$JAR_PATH"
else
    printf "[ERROR] Failed to download the new jar!\n"
    exit 1
fi

# Update cache with the new build number
BUILD="$LATEST_BUILD_NUMBER"
save_cache
printf "[INFO] Cache updated with new build number (%s).\n" "$BUILD"

# All done!
