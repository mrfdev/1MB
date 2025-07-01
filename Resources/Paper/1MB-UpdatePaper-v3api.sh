#!/usr/bin/env bash

set -e  # Exit immediately on error

##############################################################################
# 1MB-UpdatePaper-v3api.sh
#
# Simple PaperMC Updater with:
#   - Smart backups of previous jars (with timestamps)
#   - Fallback to curl or wget for downloads
#   - Minimal cache (JSON) of last used project/version/build/sha
#   - Cache reset with -clearcache CLI argument
#   - Debug output toggle
#
# Author: mrfloris (https://github.com/mrfdev/1MB)
# ChatGPT (OpenAI) provided co-development and migration advice for PaperMC v3 API
##############################################################################

# ---------------------- CONFIGURATION ----------------------------------------

CACHE_FILE=".papercache.json"            # File to store the cache
DEFAULT_PROJECT="paper"                  # Project (usually 'paper')
DEFAULT_VERSION="1.21.7"                 # Desired Minecraft version
USER_AGENT="mrfloris-paper-script/1.0 (https://github.com/mrfdev/1MB)"
API_BASE="https://fill.papermc.io/v3"    # PaperMC v3 API endpoint
DEBUG=1                                  # Set to 1 for verbose debug output

# ---------------------- DOWNLOAD COMMAND SELECTION ---------------------------

# Prefer curl, fallback to wget. Abort if neither is found.
if command -v curl >/dev/null 2>&1; then
    DL_CMD="curl"
elif command -v wget >/dev/null 2>&1; then
    DL_CMD="wget"
else
    printf "\n[ERROR] Neither 'curl' nor 'wget' is installed. At least one is required.\n"
    printf "Install with:\n"
    printf "  macOS:  brew install curl\n"
    printf "  Ubuntu: sudo apt update && sudo apt install curl\n"
    exit 1
fi

# SHA-256 checker: Prefer shasum, fallback to sha256sum. Abort if neither found.
if command -v shasum >/dev/null 2>&1; then
    SHA_CMD="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
    SHA_CMD="sha256sum"
else
    printf "\n[ERROR] Need shasum or sha256sum for verification.\n"
    exit 1
fi

# ---------------------- CLI ARGUMENTS ----------------------------------------

CLEAR_CACHE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -clearcache) CLEAR_CACHE=1; shift ;;
        -h|--help)
            printf "Usage: %s [-clearcache]\n" "$0"
            printf "  -clearcache   Reset and start with a fresh cache\n"
            exit 0
            ;;
        *) printf "[WARN] Unknown option: %s\n" "$1"; shift ;;
    esac
done

# ---------------------- CACHE HANDLING ---------------------------------------

# Load cache from file, or initialize with defaults if not present
load_cache() {
    if [ -f "$CACHE_FILE" ]; then
        PROJECT=$(jq -r '.project' "$CACHE_FILE")
        VERSION=$(jq -r '.version' "$CACHE_FILE")
        BUILD=$(jq -r '.build' "$CACHE_FILE")
        JAR_SHA=$(jq -r '.jar_sha // ""' "$CACHE_FILE")
        COMMIT_SHA=$(jq -r '.commit_sha // ""' "$CACHE_FILE")
    else
        PROJECT="$DEFAULT_PROJECT"
        VERSION="$DEFAULT_VERSION"
        BUILD="0"
        JAR_SHA=""
        COMMIT_SHA=""
        save_cache
    fi
}

# Write cache to disk (JSON format)
save_cache() {
    printf '{\n' > "$CACHE_FILE"
    printf '  "project": "%s",\n' "$PROJECT" >> "$CACHE_FILE"
    printf '  "version": "%s",\n' "$VERSION" >> "$CACHE_FILE"
    printf '  "build": "%s",\n' "$BUILD" >> "$CACHE_FILE"
    printf '  "commit_sha": "%s",\n' "$COMMIT_SHA" >> "$CACHE_FILE"
    printf '  "jar_sha": "%s"\n' "$JAR_SHA" >> "$CACHE_FILE"
    printf '}\n' >> "$CACHE_FILE"
}

# Remove cache and reset to defaults
clear_cache() {
    printf "[INFO] Clearing cache...\n"
    rm -f "$CACHE_FILE"
    PROJECT="$DEFAULT_PROJECT"
    VERSION="$DEFAULT_VERSION"
    BUILD="0"
    JAR_SHA=""
    COMMIT_SHA=""
    save_cache
}

# ---------------------- GET LATEST BUILD INFO --------------------------------

# Query the PaperMC API for the latest build info for the selected version
get_latest_build() {
    LATEST_URL="$API_BASE/projects/$PROJECT/versions/$VERSION/builds/latest"
    RESPONSE=""
    if [ "$DL_CMD" = "curl" ]; then
        RESPONSE=$(curl -sSL -H "User-Agent: $USER_AGENT" "$LATEST_URL")
    else
        RESPONSE=$(wget --header="User-Agent: $USER_AGENT" -qO- "$LATEST_URL")
    fi
    LATEST_BUILD=$(echo "$RESPONSE" | jq -r '.id')
    DOWNLOAD_URL=$(echo "$RESPONSE" | jq -r '.downloads."server:default".url')
    EXPECTED_SHA=$(echo "$RESPONSE" | jq -r '.downloads."server:default".checksums.sha256')
    COMMIT_SHA=$(echo "$RESPONSE" | jq -r '.commits[0].sha // ""')
}

# ---------------------- MAIN LOGIC -------------------------------------------

# Abort if jq is missing (required for parsing JSON)
if ! command -v jq >/dev/null 2>&1; then
    printf "\n[ERROR] The 'jq' command is required (brew install jq or apt install jq)\n"
    exit 1
fi

printf "[INFO] For script updates, visit: https://github.com/mrfdev/1MB\n"

if [ "$CLEAR_CACHE" = "1" ]; then
    clear_cache
fi

load_cache

# Print cache state for debugging if enabled
if [ "$DEBUG" = "1" ]; then
    printf "\n[INFO] Loaded cache state:\n"
    cat "$CACHE_FILE"
    printf "\n"
fi

get_latest_build

if [ "$DEBUG" = "1" ]; then
    printf "[INFO] Latest available build for %s %s: %s\n" "$PROJECT" "$VERSION" "$LATEST_BUILD"
    printf "[INFO] Cached build: %s\n" "$BUILD"
    printf "[INFO] Latest build: %s\n" "$LATEST_BUILD"
fi

# If we are already up-to-date, exit early
if [ "$BUILD" = "$LATEST_BUILD" ]; then
    printf "[INFO] You already have the latest build (%s). No update needed.\n" "$BUILD"
    exit 0
fi

JAR_BASENAME="paper-${VERSION}-${LATEST_BUILD}.jar"
JAR_PATH="./$JAR_BASENAME"
BACKUP_DIR="./backups"

# Move any existing jar with the same name to backups/ (with timestamp)
if [ -f "$JAR_PATH" ]; then
    mkdir -p "$BACKUP_DIR"
    BACKUP_PATH="${BACKUP_DIR}/${JAR_BASENAME}-backup-$(date +%Y%m%d_%H%M%S)"
    printf "[INFO] Existing jar %s found. Moving to backup: %s\n" "$JAR_PATH" "$BACKUP_PATH"
    mv "$JAR_PATH" "$BACKUP_PATH"
fi

# Download the latest jar
printf "[INFO] Downloading build %s to %s\n" "$LATEST_BUILD" "$JAR_PATH"
if [ "$DL_CMD" = "curl" ]; then
    curl -fSL -o "$JAR_PATH" -H "User-Agent: $USER_AGENT" "$DOWNLOAD_URL"
else
    wget --header="User-Agent: $USER_AGENT" -O "$JAR_PATH" "$DOWNLOAD_URL"
fi

# Verify SHA-256 checksum matches expected value from the API
LOCAL_SHA=$($SHA_CMD "$JAR_PATH" | awk '{print $1}')
if [ "$EXPECTED_SHA" != "$LOCAL_SHA" ]; then
    printf "[ERROR] SHA-256 mismatch!\n"
    printf "        Expected: %s\n" "$EXPECTED_SHA"
    printf "        Actual:   %s\n" "$LOCAL_SHA"
    rm -f "$JAR_PATH"
    exit 1
fi
printf "[INFO] SHA-256 checksum verified: %s\n" "$LOCAL_SHA"

# Update cache with the new build and SHA
BUILD="$LATEST_BUILD"
JAR_SHA="$LOCAL_SHA"
save_cache

printf "[INFO] Update complete! Now running build %s.\n" "$BUILD"
