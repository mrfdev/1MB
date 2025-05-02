# Minecraft Server Log Parser

A bash script to scan your Minecraft server logs to extract:

- Playernames and their IP addresses
- UUIDs of players
- Which usernames share the same IP (alt accounts)

Supports `.log` and `.log.gz` files in the `/logs/` folder.

---

## Features

✅ Extracts usernames, IPs, and UUIDs  
✅ Identifies shared IPs across usernames  
✅ Supports blacklists for usernames, IPs, and UUIDs  
✅ Search mode for `username`, `ip`, or `uuid`  
✅ Interactive or silent setup (`--yes`)  
✅ macOS and Ubuntu compatible

---

## Usage

### Run normally to generate logs:

```bash
./1MB-parse-logins.sh
```

### Optional flags:

```bash
--search-user <username>   # Search for a username
--search-ip <ip>           # Search for an IP
--search-uuid <uuid>       # Search for a UUID
--yes                      # Skip prompts, auto-create blacklist files if missing
```

---

## Example

```bash
./1MB-parse-logins.sh --search-ip 127.0.0.1
```

---

## Output

- `YYYY-MM-DD.log` — All logins
- `YYYY-MM-DD-completed.log` — Users sharing the same IP
- `YYYY-MM-DD-uuids.log` — UUIDs by username

---

## Folder Structure

```
/minecraft-server/
  ├─ 1MB-parse-logins.sh
  ├─ blacklist_users.txt
  ├─ blacklist_ips.txt
  ├─ blacklist_uuids.txt
  └─ logs/
      ├─ latest.log
      ├─ old.log.gz
```

---

MIT License  
Made with ❤️ for server admins.
