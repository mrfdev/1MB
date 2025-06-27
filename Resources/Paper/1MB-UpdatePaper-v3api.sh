#!/usr/bin/env bash

set -e

##############################################################################
# PaperMC Server Updater Script - mrfloris-paper-script/1.0
# Maintainer: mrfloris (https://github.com/mrfdev/1MB)
#
# This script never self-updates or downloads code from anywhere but
# the official PaperMC API. To update this script, visit:
# https://github.com/mrfdev/1MB
##############################################################################

CACHE_FILE=".papercache.json"
DEFAULT_PROJECT="paper"
DEFAULT_VERSION="1.21.6"
DEFAULT_CHANNEL="STABLE"
DEFAULT_AUTO_UPDATE=0
USER_AGENT="mrfloris-paper-script/1.0 (https://github.com/mrfdev/1MB)"
API_BASE="https://fill.papermc.io/v3"
DEBUG=0   # Set to 1 for extra API output, 0 to disable

# ----------------- CLI Argument Parsing ---------------------
SHOW_HELP=0
CLEAR_CACHE=0
FORCE_UPDATE_LATEST=0
AUTO_UPDATE_FLAG=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)        SHOW_HELP=1; shift ;;
    -clearcache)      CLEAR_CACHE=1; shift ;;
    -updatelatest)    FORCE_UPDATE_LATEST=1; shift ;;
    -autoupdate)      AUTO_UPDATE_FLAG=1; shift ;;
    *)                printf "Unknown option: %s\n" "$1"; SHOW_HELP=1; shift ;;
  esac
done

if [ "$SHOW_HELP" = "1" ]; then
    printf "\nUsage: %s [options]\n" "$0"
    printf "Options:\n"
    printf "  -clearcache     Wipe/reset the cache and start fresh\n"
    printf "  -updatelatest   Update cache to the latest available Paper version/build\n"
    printf "  -autoupdate     Always track and update to the latest version/build/channel\n"
    printf "  -h, --help      Show this help message\n"
    exit 0
fi

# ----------------- Safeguards & Dependency Checks -----------
if [ "$EUID" -eq 0 ]; then
    printf "\n[ERROR] This script should NOT be run as root or with sudo.\n"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    printf "\n[ERROR] The 'jq' command is required but was not found.\n"
    printf "Install with:\n"
    printf "  macOS:  brew install jq\n"
    printf "  Ubuntu: sudo apt update && sudo apt install jq\n\n"
    exit 1
fi

if command -v shasum >/dev/null 2>&1; then
    SHA_CMD="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
    SHA_CMD="sha256sum"
else
    printf "\n[ERROR] Neither 'shasum' nor 'sha256sum' found for SHA-256 verification.\n"
    exit 1
fi

# ----------------- Cache Handling -------------------------
load_cache() {
    if [ -f "$CACHE_FILE" ]; then
        PROJECT=$(jq -r '.project' "$CACHE_FILE")
        VERSION=$(jq -r '.version' "$CACHE_FILE")
        BUILD=$(jq -r '.build' "$CACHE_FILE")
        CHANNEL=$(jq -r '.channel' "$CACHE_FILE")
        COMMIT_SHA=$(jq -r '.commit_sha // ""' "$CACHE_FILE")
        JAR_SHA=$(jq -r '.jar_sha // ""' "$CACHE_FILE")
        AUTO_UPDATE=$(jq -r '.auto_update // 0' "$CACHE_FILE")
    else
        PROJECT="$DEFAULT_PROJECT"
        VERSION="$DEFAULT_VERSION"
        BUILD="0"
        CHANNEL="$DEFAULT_CHANNEL"
        COMMIT_SHA=""
        JAR_SHA=""
        AUTO_UPDATE="$DEFAULT_AUTO_UPDATE"
        save_cache
    fi
}

save_cache() {
    printf '{\n'        > "$CACHE_FILE"
    printf '  "project": "%s",\n' "$PROJECT" >> "$CACHE_FILE"
    printf '  "version": "%s",\n' "$VERSION" >> "$CACHE_FILE"
    printf '  "build": "%s",\n' "$BUILD" >> "$CACHE_FILE"
    printf '  "channel": "%s",\n' "$CHANNEL" >> "$CACHE_FILE"
    printf '  "commit_sha": "%s",\n' "$COMMIT_SHA" >> "$CACHE_FILE"
    printf '  "jar_sha": "%s",\n' "$JAR_SHA" >> "$CACHE_FILE"
    printf '  "auto_update": %s\n' "$AUTO_UPDATE" >> "$CACHE_FILE"
    printf '}\n'        >> "$CACHE_FILE"
}

clear_cache() {
    printf "[INFO] Clearing cache and starting fresh...\n"
    rm -f "$CACHE_FILE"
    PROJECT="$DEFAULT_PROJECT"
    VERSION="$DEFAULT_VERSION"
    BUILD="0"
    CHANNEL="$DEFAULT_CHANNEL"
    COMMIT_SHA=""
    JAR_SHA=""
    AUTO_UPDATE="$DEFAULT_AUTO_UPDATE"
    save_cache
}

# ------------- Fetch Latest MC Version ---------------------
get_latest_mc_version() {
    VERSIONS_URL="$API_BASE/projects/$PROJECT/versions"
    VERSIONS_JSON=$(curl -sSL -H "User-Agent: $USER_AGENT" "$VERSIONS_URL")
    if [ "$DEBUG" -eq 1 ]; then
        printf "\n[DEBUG] Raw VERSIONS_JSON:\n%s\n\n" "$VERSIONS_JSON"
    fi
    VERSIONS=$(printf '%s' "$VERSIONS_JSON" | jq -r '.versions[]')
    LATEST_VERSION=$(printf '%s\n' "$VERSIONS" | sort -V | tail -1)
    if [ "$DEBUG" -eq 1 ]; then
        printf "[DEBUG] Sorted versions (version sort):\n%s\n" "$(printf '%s\n' "$VERSIONS" | sort -V)"
        printf "[DEBUG] LATEST_VERSION detected: %s\n" "$LATEST_VERSION"
    fi
}



# ------------- Fetch Latest Build for Version --------------
fetch_latest_build_info() {
    API_URL="$API_BASE/projects/$PROJECT/versions/$VERSION/builds/latest"
    RESPONSE=$(curl -sSL -H "User-Agent: $USER_AGENT" "$API_URL")
    if [ "$DEBUG" -eq 1 ]; then
        printf "\n[DEBUG] Raw API response:\n%s\n\n" "$RESPONSE"
    fi
    LATEST_BUILD_NUMBER=$(printf '%s' "$RESPONSE" | jq -r '.id')
    LATEST_DOWNLOAD_URL=$(printf '%s' "$RESPONSE" | jq -r '.downloads."server:default".url')
    LATEST_COMMIT_SHA=$(printf '%s' "$RESPONSE" | jq -r '.commits[0].sha // ""')
    LATEST_JAR_SHA=$(printf '%s' "$RESPONSE" | jq -r '.downloads."server:default".checksums.sha256 // ""')
    LATEST_CHANNEL=$(printf '%s' "$RESPONSE" | jq -r '.channel // ""')
    # If something goes wrong
    if [ -z "$LATEST_BUILD_NUMBER" ] || [ "$LATEST_BUILD_NUMBER" = "null" ]; then
        printf "\n[ERROR] Could not find a valid build number for version %s\n" "$VERSION"
        exit 1
    fi
    if [ -z "$LATEST_DOWNLOAD_URL" ] || [ "$LATEST_DOWNLOAD_URL" = "null" ]; then
        printf "\n[ERROR] Download URL missing in API response for build %s\n" "$LATEST_BUILD_NUMBER"
        exit 1
    fi
}

# ----------------- Main Script Flow ------------------------

printf "[INFO] For script updates, visit: https://github.com/mrfdev/1MB\n"

# Handle CLI flags
if [ "$CLEAR_CACHE" = "1" ]; then
    clear_cache
fi

load_cache

if [ "$AUTO_UPDATE_FLAG" = "1" ]; then
    AUTO_UPDATE=1
    save_cache
    printf "[INFO] Auto-update mode enabled.\n"
fi

# If user wants to force update to latest MC version/build/channel:
if [ "$FORCE_UPDATE_LATEST" = "1" ] || [ "$AUTO_UPDATE" = "1" ]; then
    get_latest_mc_version
    if [ "$VERSION" != "$LATEST_VERSION" ]; then
        printf "[INFO] Updating to latest MC version: %s (was %s)\n" "$LATEST_VERSION" "$VERSION"
        VERSION="$LATEST_VERSION"
        BUILD="0"
        save_cache
    fi
fi

# Always check if there is a newer MC version (unless in full auto-update mode)
if [ "$AUTO_UPDATE" = "0" ]; then
    get_latest_mc_version
    if [ "$VERSION" != "$LATEST_VERSION" ]; then
        printf "[INFO] Newer Minecraft version available: %s (current: %s)\n" "$LATEST_VERSION" "$VERSION"
        printf "       Do you want to upgrade and update your cache? [y/N]: "
        read -r reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            VERSION="$LATEST_VERSION"
            BUILD="0"
            save_cache
            printf "[INFO] Upgraded to new MC version. Continuing with update...\n"
        else
            printf "[INFO] Staying on version %s as per cache.\n" "$VERSION"
        fi
    fi
fi

# Fetch and check the latest build for the current version
fetch_latest_build_info

JAR_BASENAME="paper-${VERSION}-${LATEST_BUILD_NUMBER}.jar"
JAR_PATH="./${JAR_BASENAME}"
BACKUP_DIR="./backups"

printf "\n[INFO] Loaded cache state:\n"
cat "$CACHE_FILE"
printf "\n[INFO] Latest available build for %s %s (%s): %s\n" "$PROJECT" "$VERSION" "$LATEST_CHANNEL" "$LATEST_BUILD_NUMBER"

# Warn if channel is not the preferred one
if [ "$LATEST_CHANNEL" != "$CHANNEL" ] && [ "$AUTO_UPDATE" = "0" ]; then
    printf "[WARN] Build channel is '%s', but you prefer '%s'.\n" "$LATEST_CHANNEL" "$CHANNEL"
    printf "       Proceed with this build? [y/N]: "
    read -r channel_reply
    if [[ ! "$channel_reply" =~ ^[Yy]$ ]]; then
        printf "[INFO] Aborting as per user input.\n"
        exit 0
    fi
fi

printf "[INFO] Cached build: %s\n" "$BUILD"
printf "[INFO] Latest build: %s\n" "$LATEST_BUILD_NUMBER"

if [ "$BUILD" = "$LATEST_BUILD_NUMBER" ]; then
    printf "[INFO] You already have the latest build (%s). No update needed.\n" "$BUILD"
    exit 0
fi

printf "[INFO] Newer build detected! Updating from build %s to %s\n" "$BUILD" "$LATEST_BUILD_NUMBER"

mkdir -p "$BACKUP_DIR"

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

# Verify SHA-256
EXPECTED_SHA="$LATEST_JAR_SHA"
LOCAL_SHA=$($SHA_CMD "$JAR_PATH" | awk '{print $1}')
if [ "$EXPECTED_SHA" != "$LOCAL_SHA" ]; then
    printf "[ERROR] SHA-256 mismatch! Download may be corrupted or tampered with.\n"
    printf "        Expected: %s\n" "$EXPECTED_SHA"
    printf "        Actual:   %s\n" "$LOCAL_SHA"
    printf "        Removing compromised jar and aborting.\n"
    rm -f "$JAR_PATH"
    exit 1
else
    printf "[INFO] SHA-256 checksum verified: %s\n" "$LOCAL_SHA"
fi

# Update cache with the new build info
BUILD="$LATEST_BUILD_NUMBER"
COMMIT_SHA="$LATEST_COMMIT_SHA"
JAR_SHA="$LOCAL_SHA"
CHANNEL="$LATEST_CHANNEL"
save_cache
printf "[INFO] Cache updated with new build, SHA, and commit.\n"

# All done!
