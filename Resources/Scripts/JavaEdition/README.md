# 🎯 Minecraft Profile Lookup Script (`mcprofile.sh`)

Part of the **1MoreBlock.com Server Tooling Suite**  
📁 Location: [`/Resources/Scripts/MCProfile`](https://github.com/mrfdev/1MB/tree/master/Resources/Scripts/MCProfile)

---

## 🧭 Repository

This script is maintained under the **1MoreBlock.com** GitHub organization:  
👉 https://github.com/mrfdev/1MB/tree/master/Resources/Scripts/MCProfile

Clone or download it:

```bash
git clone https://github.com/mrfdev/1MB.git
cd 1MB/Resources/Scripts/MCProfile
chmod +x mcprofile.sh
```

Run it:

```bash
./mcprofile.sh mrfloris
```

---

## 📘 Overview

`mcprofile.sh` is a **Minecraft player lookup utility** that queries both the **MCProfile.io API** and the **Crafty.gg API** to provide detailed player information for **Java** and **Bedrock** editions.

It can:
- Look up player UUIDs, usernames, XUIDs, or gamertags
- Detect if a player is linked between Java and Bedrock (via Geyser/Floodgate)
- Retrieve a player’s name history from Crafty.gg
- Display related quick links (Laby.net, Crafty.gg, NameMC)

---

## 💡 Tested Environment

- **Minecraft Server:** `1MoreBlock.com`
- **macOS:** Tahoe 26.1  
  (also works on **Ubuntu 20.04+** and other Unix-based systems)

---

## ⚙️ Features

- Supports **Java** and **Bedrock** modes  
- Accepts player identifiers:
  - Java username or UUID
  - Bedrock gamertag, XUID, or Floodgate UUID
- Displays both **Java** and **Bedrock** profile data (if linked)
- Pulls player **name history** from Crafty.gg (requires API key)
- Works directly in any terminal supporting `bash`, `curl`, and `jq`
- Provides handy quick links at the end

---

## 🧱 Credits

- **Author:** Floris (`mrfloris`)
- **Assistant / Collaborator:** ChatGPT (OpenAI)
- **APIs used:**
  - [MCProfile.io](https://mcprofile.io/api/v1)
  - [Crafty.gg](https://crafty.gg)

---

## 🧩 Requirements

| Dependency | Purpose | Install (macOS) | Install (Ubuntu/Debian) |
|-------------|----------|----------------|--------------------------|
| `bash` | Script runtime | Built-in | Built-in |
| `curl` | API requests | Built-in | `sudo apt install curl` |
| `jq` | JSON parsing | `brew install jq` | `sudo apt install jq` |

---

## 🔐 Crafty.gg API Key Setup (Important)

To use the **name history** feature, you must log into **Crafty.gg** and generate an API key:

1. Go to [https://crafty.gg](https://crafty.gg) and log in.  
2. Visit your profile settings.  
3. Generate a new **API Token** (or reuse an existing one).  
4. Copy your key, it looks like this:

   ```
   crafty_XXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ```

5. Export it in your terminal (temporary for this session):

   ```bash
   export CRAFTY_TOKEN="crafty_XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
   ```

   Or make it permanent by adding it to your shell profile:

   ```bash
   echo 'export CRAFTY_TOKEN="crafty_XXXXXXXXXXXXXXXXXXXXXXXXXXXX"' >> ~/.zshrc
   source ~/.zshrc
   ```

6. Confirm it’s set:

   ```bash
   echo $CRAFTY_TOKEN
   ```

Without this, the script will still work for **MCProfile lookups**, but will skip name history.

---

## 🧰 Installation

```bash
git clone https://github.com/mrfdev/1MB.git
cd 1MB/Resources/Scripts/MCProfile
chmod +x mcprofile.sh
```

Optional: install globally

```bash
sudo cp mcprofile.sh /usr/local/bin/mcprofile
```

---

## 🧾 Usage

```text
./mcprofile.sh <username|uuid|gamertag|xuid> [-bedrock]
```

### Arguments

| Argument | Description | Example |
|-----------|--------------|----------|
| `<username>` | Minecraft Java username | `mrfloris` |
| `<uuid>` | Minecraft Java UUID | `41068e81-644c-4125-af4d-403ae773299d` |
| `<gamertag>` | Bedrock gamertag | `Ceddeluring1234` |
| `<xuid>` | Bedrock XUID (decimal) | `2535425145266352` |
| `-bedrock` | Forces lookup in Bedrock mode | `./mcprofile.sh Ceddeluring1234 -bedrock` |

---

## 💻 Examples

### 1. Java lookup by username
```bash
./mcprofile.sh mrfloris
```

### 2. Java lookup by UUID
```bash
./mcprofile.sh 41068e81-644c-4125-af4d-403ae773299d
```

### 3. Bedrock lookup by gamertag
```bash
./mcprofile.sh Ceddeluring1234 -bedrock
```

### 4. Bedrock lookup by XUID
```bash
./mcprofile.sh 2535425145266352 -bedrock
```

---

## 🧩 Example Output

```text
--> 1MoreBlock.com Player Lookup

Java Edition
  MSA (ign):          mrfloris
  UUID:               41068e81-644c-4125-af4d-403ae773299d
  Geyser linked:      true

Name history:
- mrfloris (original)
- MrFlorisDev (2023-09-15)

Bedrock Edition
  Floodgate UUID:     00000000-0000-0000-0009-01f4ab2360b0
  Bedrock XUID:       2535425145266352
  Bedrock Gamertag:   Ceddeluring1234

Quick Links:
  https://laby.net/@mrfloris
  https://crafty.gg/@mrfloris
  https://namemc.com/search?q=mrfloris
```

---

## 🧾 Notes

- **Crafty.gg API key is optional**, but recommended for full data.  
- **MCProfile.io** lookups always work (with or without Crafty).  
- Built for moderation, lookup, and debugging on the **1MoreBlock.com** network.
- **No authentication required** for public MCProfile.io endpoints.  
- Respects rate limits and minimal error handling for safe operation.

---

**© 2025 Floris (mrfloris)**  
Co-authored with ChatGPT (OpenAI)  
🎮 Part of [1MoreBlock.com](https://1moreblock.com) server tools.
