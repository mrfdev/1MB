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

DEBUG=1  # Set to 1 to print raw API response, 0 to disable

# ----------------- Configurable Variables ---------------------
CACHE_FILE=".papercache.json"
DEFAULT_PROJECT="paper"
DEFAULT_VERSION="1.21.6"         # Change as needed
DEFAULT_CHANNEL="STABLE"         # Options: STABLE, BETA, ALPHA, RECOMMENDED

USER_AGENT="mrfloris-paper-script/1.0 (https://github.com/mrfdev/1MB)"
#API_BASE="https://fill.papermc.io/api/v3"
API_BASE="https://fill.papermc.io/v3"


# ----------------- Script Safeguards --------------------------

# Prevent running as root
if [ "$EUID" -eq 0 ]; then
    printf "\n[ERROR] *!* This script should NOT be run as root or with sudo.\n"
    printf "        Please run as your normal user.\n\n"
    exit 1
fi

# Dependency check for jq (JSON parser)
if ! command -v jq >/dev/null 2>&1; then
    printf "\n[ERROR] The 'jq' command is required but was not found.\n"
    printf "Install it with:\n"
    printf "  macOS:  brew install jq\n"
    printf "  Ubuntu: sudo apt update && sudo apt install jq\n\n"
    exit 1
fi

# ----------------- Cache Logic --------------------------------

# Load cache from file, or create a new one with defaults
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

# Save current cache variables to the cache file as JSON
save_cache() {
    printf '{\n'        > "$CACHE_FILE"
    printf '  "project": "%s",\n' "$PROJECT" >> "$CACHE_FILE"
    printf '  "version": "%s",\n' "$VERSION" >> "$CACHE_FILE"
    printf '  "build": "%s",\n' "$BUILD" >> "$CACHE_FILE"
    printf '  "channel": "%s"\n' "$CHANNEL" >> "$CACHE_FILE"
    printf '}\n'        >> "$CACHE_FILE"
}

# ----------------- Paper API Query Logic ----------------------

# Query PaperMC API for the latest build info for the specified version
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




# ----------------- Main Script Logic --------------------------

load_cache

printf "\n[INFO] Loaded cache state:\n"
cat "$CACHE_FILE"
printf "\n"

fetch_latest_build_info

# Next: add logic to compare build numbers, download/update jar, etc.
# For now, this script prints the cache and latest build info, and is ready to extend!

##############################################################################
# Next Steps (Not Yet Implemented - Add your own code here!)
# - Compare cached BUILD to LATEST_BUILD_NUMBER
# - If new, backup existing paper jar, download new one, update cache
# - If MC version changes, prompt to reset cache, confirm with user
# - Optionally allow switching channel/project/version interactively
##############################################################################

# End of script

