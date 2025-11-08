# bedrock.sh

A Bash utility script to look up **Minecraft: Bedrock Edition** player information using the public APIs from **GeyserMC** and **MCProfile**.

This script was written for and tested on:

- **Minecraft server:** `1MoreBlock.com`
- **OS:** macOS Tahoe 26.1

It should also work on most recent Linux distributions (for example **Ubuntu 20.04+**) as long as the dependencies are installed.

---

## Features

- Accepts either:
  - a **Bedrock gamertag** (e.g. `mrfloris1811`)
  - or a **Bedrock XUID in decimal** (e.g. `2535452632766053`)
- Resolves **gamertag ⇄ XUID** using:
  - `https://api.geysermc.org`
  - `https://mcprofile.io`
- Fetches and displays:
  - Full JSON output from **GeyserMC** (gamertag + skin)
  - Full JSON output from **MCProfile** (Bedrock profile)
- Caches results locally to avoid rate limits
- Multiple output modes:
  - Full verbose view (default)
  - Summary view (`--summary`)
  - Short one-liner (`--short`)
  - Machine-readable JSON (`--json`)
- Optional debug / verbose logging:
  - Shows URLs being called
  - Shows timings per request
  - Shows raw JSON responses (pretty-printed with `jq`) to `stderr`

---

## Credits

- **Script author:** Floris (`mrfloris`)
- **Assistant / co-pilot:** ChatGPT (OpenAI)
- **APIs used (3rd party credits):**
  - [GeyserMC API](https://api.geysermc.org) – XUID & gamertag + skin data
  - [MCProfile API](https://mcprofile.io) – Bedrock profile information

---

## Requirements

- `bash` (the script is written for POSIX-ish shells, tested with `bash`)
- `curl` (for HTTP requests)
- **Optional but recommended:** `jq`
  - Required for `--json` mode
  - Required for caching (without `jq`, caching is disabled)

On macOS with Homebrew:

```bash
brew install jq
```

On Ubuntu / Debian:

```bash
sudo apt-get update
sudo apt-get install -y jq curl
```

---

## Installation

Clone the repository and mark the script as executable:

```bash
- Get the .sh file from https://github.com/mrfdev/1MB/tree/master/Resources/Scripts/Bedrock
- Put it in any directory
- chmod +x bedrock.sh
```

You can then either run it from that directory, or copy it somewhere in your `PATH`, for example:

```bash
cp bedrock.sh /usr/local/bin/bedrock
```

After that you can invoke it as:

```bash
bedrock <gamertag|xuid-decimal>
```

---

## Usage

```text
./bedrock.sh [--short|--summary|--json] \
             [--no-cache|--refresh|--clear-cache] \
             [--geyser-only|--mcprofile-only] \
             [-v|--verbose] \
             <gamertag|xuid-decimal>
```

### Positional argument

- `<gamertag|xuid-decimal>`
  - Either a Bedrock **gamertag** (e.g. `mrfloris1811`)
  - Or a Bedrock **XUID in decimal** (e.g. `2535452632766053`)
  - The script auto-detects whether it's a number or a string.

### Output mode flags

- `--short`  
  Output a compact one-liner, e.g.:

  ```text
  mrfloris1811 | XUID: 2535452632766053
  ```

- `--summary`  
  Output a human-readable summary with key fields (gamertag, XUID, XUID HEX, skin URL, Xbox.com URL).

- `--json`  
  Output a machine-readable JSON document which contains:
  - `gamertag`
  - `xuid_decimal`
  - `xuid_hex`
  - `skin_texture_id`
  - `skin_url`
  - `xbox_profile_url`
  - `raw` – an object containing:
    - `geyser_gamertag` – raw JSON from GeyserMC gamertag endpoint
    - `geyser_skin` – raw JSON from GeyserMC skin endpoint
    - `mcprofile_xuid` – raw JSON from MCProfile XUID endpoint

### Cache flags

- `--no-cache`  
  Do **not** read from or write to cache. Every run will hit the APIs.

- `--refresh`  
  Ignore any existing cache entries, but write new cache data after fetching.

- `--clear-cache`  
  Delete the cache directory and exit.  
  By default, cache lives at:

  ```text
  ~/.cache/bedrock_lookup
  ```

  You can override this via:

  ```bash
  export BEDROCK_CACHE_DIR="/path/to/somewhere"
  ```

### API selection flags

- `--geyser-only`  
  Only call the **GeyserMC** API. Useful if:
  - You mainly need gamertag + skin information
  - You want to reduce calls to MCProfile

- `--mcprofile-only`  
  Only call the **MCProfile** API. Useful if:
  - You mainly want MCProfile's Bedrock profile fields
  - You want to avoid GeyserMC calls for some reason

### Debugging

- `-v`, `--verbose`  
  Enable verbose logging to `stderr`:
  - Shows each URL that `curl` calls
  - Shows request durations
  - Shows raw JSON (pretty via `jq`) for each response

This is especially useful if an API changes its format, or if you suspect rate limiting / errors.

---

## Cache behaviour

By default, the script will:

1. Try to load from cache (if `jq` is available).
2. If a cache hit:
   - **Full mode:** replays the full JSON blocks that were previously retrieved from GeyserMC and MCProfile, so the output matches a live request.
   - `--summary` / `--short` / `--json`: use the structured data from the cache.
3. If cache miss:
   - Resolve gamertag ⇄ XUID as needed using GeyserMC / MCProfile.
   - Fetch:
     - GeyserMC gamertag
     - GeyserMC skin
     - MCProfile XUID profile
   - Save everything (including raw JSON) to cache files.

Cache files are stored under:

```text
~/.cache/bedrock_lookup/
  ├─ xuid_2535452632766053.json
  └─ gamertag_mrfloris1811.json
```

---

## Examples

Below are a bunch of example commands using:

- Gamertag: **`mrfloris1811`**
- XUID (decimal): **`2535452632766053`**

> Note: these values are just examples; swap in your own gamertag/XUID as needed.

### Basic lookups

**Lookup by gamertag (full output):**

```bash
./bedrock.sh mrfloris1811
```

**Lookup by XUID (full output):**

```bash
./bedrock.sh 2535452632766053
```

### Summary and short modes

**Summary by gamertag:**

```bash
./bedrock.sh --summary mrfloris1811
```

**Summary by XUID:**

```bash
./bedrock.sh --summary 2535452632766053
```

**Short one-liner (gamertag):**

```bash
./bedrock.sh --short mrfloris1811
```

**Short one-liner (XUID):**

```bash
./bedrock.sh --short 2535452632766053
```

### JSON output

**JSON for gamertag:**

```bash
./bedrock.sh --json mrfloris1811 | jq .
```

**JSON for XUID:**

```bash
./bedrock.sh --json 2535452632766053 | jq .
```

### Cache control

**Force a fresh lookup and refresh cache (gamertag):**

```bash
./bedrock.sh --refresh mrfloris1811
```

**Force a fresh lookup and refresh cache (XUID):**

```bash
./bedrock.sh --refresh 2535452632766053
```

**Disable cache entirely (always hit APIs):**

```bash
./bedrock.sh --no-cache mrfloris1811
```

**Clear the cache and exit:**

```bash
./bedrock.sh --clear-cache
```

### API selection

**Use only GeyserMC (no MCProfile) for a gamertag:**

```bash
./bedrock.sh --geyser-only mrfloris1811
```

**Use only MCProfile (no GeyserMC) for a XUID:**

```bash
./bedrock.sh --mcprofile-only 2535452632766053
```

**Summary using only MCProfile:**

```bash
./bedrock.sh --summary --mcprofile-only mrfloris1811
```

### Debug / verbose mode

**Verbose full lookup (show URLs + timings) by XUID:**

```bash
./bedrock.sh -v 2535452632766053
```

**Verbose summary (debug on stderr, clean summary on stdout):**

```bash
./bedrock.sh -v --summary mrfloris1811
```

**Verbose JSON (debug on stderr, raw JSON on stdout):**

```bash
./bedrock.sh -v --json 2535452632766053 | jq .
```

### Combining flags

You can combine flags in many ways; a few more examples:

```bash
# Fresh MCProfile-only summary, verbose
./bedrock.sh --mcprofile-only --refresh -v --summary mrfloris1811

# Geyser-only, short output, no cache
./bedrock.sh --geyser-only --no-cache --short 2535452632766053

# Full mode, verbose, with cache refresh
./bedrock.sh --refresh -v mrfloris1811
```

---

## Notes

- This script is intended as a helper for server owners / admins / power users.
- It is not an official tool from Mojang, Microsoft, GeyserMC, or MCProfile.
- Be mindful of API rate limits. The caching layer is specifically designed to help with that.

If you have ideas for improvements (different output formats, additional data, etc.), feel free to open an issue or pull request on the GitHub repository.
