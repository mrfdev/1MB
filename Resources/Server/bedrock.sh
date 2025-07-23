#!/bin/bash
# version 0.0.2, build 4
# put this in /logs/ and let it run, checks latest.log and all .gz files (not other .log btw)
# results are on screen and in a .txt file
# grabs all geyser joins, and sorts them on uniqueness, and lists on frequency, includes filename found and join time/date

TMP_ALL=$(mktemp)
TMP_FIRST=$(mktemp)
TMP_COUNT=$(mktemp)

PATTERN='\[Geyser-Spigot\] Player connected with username [a-zA-Z0-9_]{3,16}'

echo "Processing logs in $(pwd)..."

process_file() {
    local file="$1"

    if [[ "$file" == *.gz ]]; then
        gzcat "$file"
    else
        cat "$file"
    fi | grep -E "$PATTERN" | while read -r line; do
        username=$(echo "$line" | awk '{print $NF}')
        echo "$username" >> "$TMP_ALL"

        # Only write first-seen if not yet recorded
        if ! grep -q "^$username|" "$TMP_FIRST"; then
            echo "$username|$file" >> "$TMP_FIRST"
        fi
    done
}

# Process latest.log
[[ -f "latest.log" ]] && process_file "latest.log"

# Process all .gz files
find . -type f -name "*.gz" | while read -r gzfile; do
    process_file "$gzfile"
done

# Count occurrences
sort "$TMP_ALL" | uniq -c | awk '{printf "%s|%s\n", $2, $1}' > "$TMP_COUNT"

# Join data
echo
echo "===== Geyser Bedrock Connection Report ====="
echo "Total unique usernames: $(cut -d'|' -f1 "$TMP_COUNT" | wc -l)"
echo
printf "%-25s | %-6s | %s\n" "Username" "Count" "First Seen In"
printf "%-25s-+-%-6s-+-%s\n" "$(printf '─%.0s' {1..25})" "$(printf '─%.0s' {1..6})" "$(printf '─%.0s' {1..40})"

join -t '|' -j1 <(sort -t'|' -k1,1 "$TMP_COUNT") <(sort -t'|' -k1,1 "$TMP_FIRST") | \
awk -F'|' '{printf "%-25s | %-6s | %s\n", $1, $2, $3}' | sort -t'|' -k2 -nr

# Cleanup
rm "$TMP_ALL" "$TMP_FIRST" "$TMP_COUNT"