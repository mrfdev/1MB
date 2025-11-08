#!/bin/bash
#
# Usage: mcprofile.sh <username|uuid|gamertag|xuid> [-bedrock]
# Requires: curl, jq
#
# version 2.0.2 build 008
#
# install: chmod +x mcprofile.sh
# use: ./mcprofile.sh username

set -e

# export CRAFTY_TOKEN="your_crafty_token_here"
# echo 'export CRAFTY_TOKEN="crafty_NEW_TOKEN_FROM_SETTINGS"' >> ~/.zshrc
# source ~/.zshrc

API_BASE="https://mcprofile.io/api/v1"
CRAFTY_API="https://api.crafty.gg/api/v2/players"
CRAFTY_TOKEN="${CRAFTY_TOKEN:-}"
LOOKUP="$1"
MODE="java"

if [[ -z "$LOOKUP" ]]; then
  echo "Usage: $0 <username|uuid|gamertag|xuid> [-bedrock]"
  exit 1
fi

shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    -bedrock) MODE="bedrock"; shift;;
    *)         shift;;
  esac
done

is_uuid() { [[ "$1" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; }
is_xuid() { [[ "$1" =~ ^[0-9]{16,20}$ ]]; }

pretty_print() {
  local label="$1" value="$2"
  [[ -n "$value" && "$value" != "null" ]] && printf "  %-18s %s\n" "$label:" "$value"
}

printf "\n\033[1;36m--> 1MoreBlock.com Player Lookup\033[0m\n\n"

# ---------- Crafty.gg helper -------------------------------------------------
# Prints a tidy username history for a *Java* IGN, if Crafty knows it.
fetch_name_history() {
  local ign="$1"
  local crafty_json
  local success
  local names

  echo
  echo "Name history:"

  # Build curl command with proper headers + optional token + browsery UA
  local curl_cmd=(curl -sS
    -H "Accept: application/json"
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
  )
  if [[ -n "$CRAFTY_TOKEN" ]]; then
    curl_cmd+=(-H "Authorization: Bearer $CRAFTY_TOKEN")
  fi
  curl_cmd+=("$CRAFTY_API/$ign")

  crafty_json="$("${curl_cmd[@]}")"

  # Empty response?
  if [[ -z "$crafty_json" ]]; then
    echo "  No data from crafty.gg (empty response)."
    return
  fi

  # If it doesn't look like JSON (starts with <html> etc) – bail
  if [[ ! "$crafty_json" =~ ^[[:space:]]*\{ ]]; then
    echo "  No data from crafty.gg (non-JSON response)."
    return
  fi

  # Check success flag safely
  if ! success=$(printf '%s' "$crafty_json" | jq -er '.success' 2>/dev/null); then
    echo "  No data from crafty.gg (could not parse JSON)."
    return
  fi

  if [[ "$success" != "true" ]]; then
    echo "  No data from crafty.gg."
    return
  fi

  # Extract usernames array:
  #   .data.usernames[] { username, changed_at }
  names=$(printf '%s' "$crafty_json" | jq -r '
    .data.usernames[]?
    | "- " + .username
      + (
          if .changed_at == null then
            " (original)"
          else
            " (" + (.changed_at | sub("T.*$"; "")) + ")"
          end
        )
  ' 2>/dev/null)

  if [[ -n "$names" ]]; then
    echo "$names"
  else
    echo "  No previous names recorded."
  fi
}
# ----------------------------------------------------------------------------


if [[ "$MODE" == "java" ]]; then
  if is_uuid "$LOOKUP"; then
    RESP=$(curl -s "$API_BASE/java/uuid/$LOOKUP")
  else
    RESP=$(curl -s "$API_BASE/java/username/$LOOKUP")
  fi

  JAVA_NAME=$(echo "$RESP" | jq -r .username)
  JAVA_UUID=$(echo "$RESP" | jq -r .uuid)
  LINKED=$(echo "$RESP" | jq -r .linked)
  BEDROCK_GAMERTAG=$(echo "$RESP" | jq -r .bedrock_gamertag)
  BEDROCK_XUID=$(echo "$RESP" | jq -r .bedrock_xuid)
  BEDROCK_FUID=$(echo "$RESP" | jq -r .bedrock_fuid)

  echo "Java Edition"
  pretty_print "MSA (ign)"           "$JAVA_NAME"
  pretty_print "UUID"              "$JAVA_UUID"
  pretty_print "Geyser linked"            "$LINKED"

  # ---- Crafty history right at the end of Java block -----------------------
  [[ -n "$JAVA_NAME" && "$JAVA_NAME" != "null" ]] && fetch_name_history "$JAVA_NAME"
  # --------------------------------------------------------------------------

  if [[ "$LINKED" == "true" ]]; then
    echo
    echo "Bedrock Edition"
    pretty_print "Floodgate UUID"   "$BEDROCK_FUID"
    pretty_print "Bedrock XUID"      "$BEDROCK_XUID"
    pretty_print "Bedrock Gamertag" "$BEDROCK_GAMERTAG"
  fi

else # MODE = bedrock
  if is_xuid "$LOOKUP";       then RESP=$(curl -s "$API_BASE/bedrock/xuid/$LOOKUP")
  elif is_uuid "$LOOKUP";     then RESP=$(curl -s "$API_BASE/bedrock/fuid/$LOOKUP")
  else                             RESP=$(curl -s "$API_BASE/bedrock/gamertag/$LOOKUP"); fi

  BEDROCK_GAMERTAG=$(echo "$RESP" | jq -r .gamertag)
  BEDROCK_XUID=$(echo "$RESP"     | jq -r .xuid)
  BEDROCK_FUID=$(echo "$RESP"     | jq -r .floodgateuid)
  LINKED=$(echo "$RESP"           | jq -r .linked)
  JAVA_UUID=$(echo "$RESP"        | jq -r .java_uuid)
  JAVA_NAME=$(echo "$RESP"        | jq -r .java_name)

  echo "Bedrock Edition"
  pretty_print "Bedrock Gamertag" "$BEDROCK_GAMERTAG"
  pretty_print "Bedrock XUID"      "$BEDROCK_XUID"
  pretty_print "Floodgate UUID"   "$BEDROCK_FUID"
  pretty_print "Geyser linked"           "$LINKED"

  if [[ "$LINKED" == "true" && -n "$JAVA_NAME" && "$JAVA_NAME" != "null" ]]; then
    echo
    echo "Java Edition"
    pretty_print "MSA (ign)" "$JAVA_NAME"
    pretty_print "UUID"    "$JAVA_UUID"
    fetch_name_history "$JAVA_NAME"
  fi
fi

echo -e "\n Quick Links:"
echo "  https://laby.net/@${JAVA_NAME}"
echo "  https://crafty.gg/@${JAVA_NAME}"
echo "  https://namemc.com/search?q=${JAVA_NAME}"
