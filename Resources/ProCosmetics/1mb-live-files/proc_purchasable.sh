#!/bin/bash

# --- Script Name: proc_purchasable.sh ---
# Purpose: Toggle the 'enabled' state under 'purchasable:' in specific YML files.

# ==============================================================================
# 1. CONFIGURATION VARIABLE
# Set the default target state for 'purchasable: enabled:'.
# Default: "false" (changes 'true' to 'false')
# To reverse the action, change this to "true" (changes 'false' to 'true').
DEFAULT_TARGET_STATE="false"
# ==============================================================================

# 2. GLOBAL VARIABLES
TARGET_STATE="$DEFAULT_TARGET_STATE"
VERBOSE=false
TOTAL_CHANGES=0

TARGET_FILES=(
    "arrow_effects.yml" "banners.yml" "emotes.yml" "miniatures.yml"
    "mounts.yml" "particle_effects.yml" "statuses.yml" "balloons.yml"
    "death_effects.yml" "gadgets.yml" "morphs.yml" "music.yml"
    "pets.yml" "treasure_chests.yml"
)

# 3. HELP FUNCTION
show_help() {
cat << EOF
Usage: $0 [OPTION]...

This script toggles the 'enabled' state specifically under the 'purchasable:'
section of Minecraft cosmetic plugin .yml configuration files.

The default action is to change 'enabled: true' to 'enabled: false'.

Options:
  -h, --help               Display this help message and exit.
      --verbose            Show output for all files, including those with no changes.
      --toggle:true        Reverse the default action (change 'enabled: false' to 'true').
      --toggle:false       Explicitly set the action to default (change 'enabled: true' to 'false').

Example Usage:
  # Default action (Recommended: Disables purchasing)
  $0

  # Enable verbose output to see all files processed
  $0 --verbose

  # Reverse the action (Enables purchasing)
  $0 --toggle:true
EOF
}

# 4. ARGUMENT PARSING
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            show_help
            exit 0
            ;;
        --verbose)
            VERBOSE=true
            ;;
        --toggle:true)
            TARGET_STATE="true"
            ;;
        --toggle:false)
            TARGET_STATE="false"
            ;;
        *)
            echo "Error: Unknown argument '$arg'. Use --help for usage." >&2
            exit 1
            ;;
    esac
done

# 5. DETERMINE REPLACE_FROM and REPLACE_TO
if [ "$TARGET_STATE" == "false" ]; then
    REPLACE_FROM="true"
    REPLACE_TO="false"
else
    REPLACE_FROM="false"
    REPLACE_TO="true"
fi

# The sed command using shell variables for dynamic substitution.
# /purchasable:/ { n; s/enabled: <REPLACE_FROM>/enabled: <REPLACE_TO>/; }
SED_COMMAND="/purchasable:/ { n; s/enabled: $REPLACE_FROM/enabled: $REPLACE_TO/; }"

echo "Starting configuration update (Verbose: $VERBOSE, Action: Change '$REPLACE_FROM' to '$REPLACE_TO')..."
echo "------------------------------------------------"

# 6. MAIN PROCESSING LOOP
for FILE in "${TARGET_FILES[@]}"; do
    if [ -f "$FILE" ]; then

        # COUNT STEP: Use awk and grep to count the exact pattern being modified (REPLACE_FROM).
        COUNT=$(awk '/purchasable:/ {getline; print}' "$FILE" | grep -c "enabled: $REPLACE_FROM")

        if [ "$COUNT" -gt 0 ]; then
            # --- ALWAYS SHOW OUTPUT IF CHANGES ARE MADE ---
            echo "-> Processing $FILE..."
            echo "   Found $COUNT instance(s) of 'purchasable: enabled: $REPLACE_FROM'."

            # MODIFY STEP: Perform the in-place replacement (macOS/BSD sed).
            sed -i '' "$SED_COMMAND" "$FILE"

            if [ $? -eq 0 ]; then
                echo "   ✅ Updated $COUNT instance(s) to 'enabled: $REPLACE_TO'."
                TOTAL_CHANGES=$((TOTAL_CHANGES + COUNT))
            else
                echo "   ❌ Error: Failed to modify $FILE using sed."
            fi

        elif $VERBOSE ; then
            # --- ONLY SHOW OUTPUT IF NO CHANGES AND VERBOSE IS ENABLED ---
            echo "-> Processing $FILE..."
            echo "   No instances of 'purchasable: enabled: $REPLACE_FROM' found."
        fi

    elif $VERBOSE ; then
        # --- ONLY SHOW 'FILE NOT FOUND' IF VERBOSE IS ENABLED ---
        echo "-> Skipping $FILE: File not found."
    fi

    # Add a newline for separation, but only if something was printed for this file
    if [ "$COUNT" -gt 0 ] || $VERBOSE; then
        echo
    fi
done

echo "------------------------------------------------"
echo "Script complete."
echo "TOTAL INSTANCES UPDATED ACROSS ALL FILES: $TOTAL_CHANGES"
echo "Please restart your Minecraft server to load the new config."