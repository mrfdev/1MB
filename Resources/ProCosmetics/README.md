# proc_purchasable.sh — ProCosmetics Purchasable Toggle Tool (v3.0)

This repository contains **proc_purchasable.sh**, a small but handy Bash utility for automating bulk updates to the `purchasable:` → `enabled:` values inside the YAML configuration files of the **ProCosmetics Premium** plugin for Minecraft.

The script ensures that all cosmetics are consistently set to `enabled: false` (or `true`, if intentionally toggled).  
It is used by me **@mrfloris** on **macOS** for the **1MoreBlock.com** Paper 1.21.10+ server, but should also fully work on Linux systems such as **Ubuntu 20.04+**.

The ProCosmetics plugin (Premium):  (the plugin i am using)
👉 https://www.spigotmc.org/resources/49106/

---

## ✨ Features

- ✔️ Toggles the value of  
  ```yaml
  purchasable:
    enabled: true/false
  ```  
  for all configured cosmetic `.yml` files.

- ✔️ Safe and targeted — only updates the **line directly below `purchasable:`**.

- ✔️ Supports both **macOS BSD sed** and **GNU/Linux sed**.

- ✔️ Verbose mode to show all file actions.

- ✔️ Toggle direction:
  - Default: `enabled: true` → `enabled: false`
  - Optional reversed action: `enabled: false` → `enabled: true`

- ✔️ Central list of target config files to scan / modify.

- ✔️ Automatically counts and reports all changed instances.

---

## 📦 Files This Script Checks

These are the ProCosmetics configuration files currently included:

```
arrow_effects.yml
banners.yml
emotes.yml
miniatures.yml
mounts.yml
particle_effects.yml
statuses.yml
balloons.yml
death_effects.yml
gadgets.yml
morphs.yml
music.yml
pets.yml
treasure_chests.yml
```

These match the plugin’s **2.0.x** release.

### ➕ Adding a new file
1. Open the script.
2. Find the `TARGET_FILES=( ... )` section.
3. Add the filename, for example:
   ```bash
   "new_cosmetic_type.yml"
   ```

### ➖ Removing a file
Delete its name from the same array.

### ✏️ Renaming a file
Change the entry in the array to match the updated filename.

---

## 📌 Why This Script Exists

While ProCosmetics allows controlling purchases via **permissions** (e.g., blocking `proc.purchase.*` using **LuckPerms**), server owners may want **extra certainty** that the YAML configs themselves explicitly declare:

```yaml
purchasable:
  enabled: false
```

This script guarantees that all cosmetic categories are aligned.

---

## 🔧 Installation

### Requirements
- macOS (tested on macOS 14+), or  
- Linux (tested on Ubuntu 20.04+, Debian, Arch, etc.)
- Bash
- sed (installed by default)

### Install Steps

1. Download the .sh from this repository:


2. Make the script executable:
   ```bash
   chmod +x proc_purchasable.sh
   ```

3. Place the script **in the same folder** as your ProCosmetics `.yml` files, or pass absolute paths (see advanced section).

---

## ▶️ Usage

Run the script with default behavior (recommended):

```bash
./proc_purchasable.sh
```

This sets:

```
enabled: true  →  enabled: false
```

### Enable full verbose output

```bash
./proc_purchasable.sh --verbose
```

### Reverse the toggle direction (enable purchases)

```bash
./proc_purchasable.sh --toggle:true
```

### Explicitly enforce disabling purchases

```bash
./proc_purchasable.sh --toggle:false
```

### Help message

```bash
./proc_purchasable.sh --help
```

---

## 🧪 Compatibility

- ✔️ macOS (BSD sed)  
- ✔️ Linux (GNU sed)  
- ✔️ Paper 1.21.10+  
- ✔️ ProCosmetics 2.0.x  
- ✔️ YAML config structure unchanged since 1.x → 2.x  

---

## 👍 Credits

- **ProCosmetics Premium Plugin**  
  https://www.spigotmc.org/resources/49106/

- **Author of this .sh script:**  
  GitHub: **@mrfloris**  
  Minecraft Server: **1MoreBlock.com**

If you improve this script or adapt it for other plugins, please consider opening a pull request!

---

## 📜 License

This script is released under the MIT License.  
You may freely use, modify, and distribute it.

