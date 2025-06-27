#!/usr/bin/env bash

set -e

##############################################################################
# Simple PaperMC Updater with Smart Backups and Cache Reset Option
##############################################################################

CACHE_FILE=".papercache.json"
DEFAULT_PROJECT="paper"
DEFAULT_VERSION="1.21.6"
USER_AGENT="mrfloris-paper-script/1.0 (https://github.com/mrfdev/1MB)"
API_BASE="https://fill.papermc.io/v3"
DEBUG=0  # Set to 1 for verbose, 0 for quiet

# SHA checker for macOS/Linux
if command -v shasum >/dev/null 2>&1; then
    SHA_CMD="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
    SHA_CMD="sha256sum"
else
    printf "\n[ERROR] Need shasum or sha256sum for verification.\n"
    exit 1
fi

# ------------------- CLI ARGUMENTS ---------------------
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

# --------------- CACHE HANDLING ------------------------

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

save_cache() {
    printf '{\n' > "$CACHE_FILE"
    printf '  "project": "%s",\n' "$PROJECT" >> "$CACHE_FILE"
    printf '  "version": "%s",\n' "$VERSION" >> "$CACHE_FILE"
    printf '  "build": "%s",\n' "$BUILD" >> "$CACHE_FILE"
    printf '  "commit_sha": "%s",\n' "$COMMIT_SHA" >> "$CACHE_FILE"
    printf '  "jar_sha": "%s"\n' "$JAR_SHA" >> "$CACHE_FILE"
    printf '}\n' >> "$CACHE_FILE"
}

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

# --------- GET LATEST BUILD INFO ---------
get_latest_build() {
    LATEST_URL="$API_BASE/projects/$PROJECT/versions/$VERSION/builds/latest"
    RESPONSE=$(curl -sSL -H "User-Agent: $USER_AGENT" "$LATEST_URL")
    LATEST_BUILD=$(echo "$RESPONSE" | jq -r '.id')
    DOWNLOAD_URL=$(echo "$RESPONSE" | jq -r '.downloads."server:default".url')
    EXPECTED_SHA=$(echo "$RESPONSE" | jq -r '.downloads."server:default".checksums.sha256')
    COMMIT_SHA=$(echo "$RESPONSE" | jq -r '.commits[0].sha // ""')
}

# --------- MAIN ---------
if ! command -v jq >/dev/null 2>&1; then
    printf "\n[ERROR] The 'jq' command is required (brew install jq or apt install jq)\n"
    exit 1
fi

printf "[INFO] For script updates, visit: https://github.com/mrfdev/1MB\n"

if [ "$CLEAR_CACHE" = "1" ]; then
    clear_cache
fi

load_cache

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

if [ "$BUILD" = "$LATEST_BUILD" ]; then
    printf "[INFO] You already have the latest build (%s). No update needed.\n" "$BUILD"
    exit 0
fi

JAR_BASENAME="paper-${VERSION}-${LATEST_BUILD}.jar"
JAR_PATH="./$JAR_BASENAME"
BACKUP_DIR="./backups"

# --- NEW: Backup any existing jar (even same build) before downloading ---
if [ -f "$JAR_PATH" ]; then
    mkdir -p "$BACKUP_DIR"
    BACKUP_PATH="${BACKUP_DIR}/${JAR_BASENAME}-backup-$(date +%Y%m%d_%H%M%S)"
    printf "[INFO] Existing jar %s found. Moving to backup: %s\n" "$JAR_PATH" "$BACKUP_PATH"
    mv "$JAR_PATH" "$BACKUP_PATH"
fi

# Download and verify
printf "[INFO] Downloading build %s to %s\n" "$LATEST_BUILD" "$JAR_PATH"
curl -fSL -o "$JAR_PATH" -H "User-Agent: $USER_AGENT" "$DOWNLOAD_URL"

LOCAL_SHA=$($SHA_CMD "$JAR_PATH" | awk '{print $1}')
if [ "$EXPECTED_SHA" != "$LOCAL_SHA" ]; then
    printf "[ERROR] SHA-256 mismatch!\n"
    printf "        Expected: %s\n" "$EXPECTED_SHA"
    printf "        Actual:   %s\n" "$LOCAL_SHA"
    rm -f "$JAR_PATH"
    exit 1
fi
printf "[INFO] SHA-256 checksum verified: %s\n" "$LOCAL_SHA"

# Update cache
BUILD="$LATEST_BUILD"
JAR_SHA="$LOCAL_SHA"
save_cache

printf "[INFO] Update complete! Now running build %s.\n" "$BUILD"
