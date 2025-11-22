# BookExport

A tiny Paper (and Spigot) 1.21.10 plugin by **mrfloris** that exports the book in your main hand to a plaintext `.txt` file.

This is version **1.0.7**, building on earlier versions by adding:

- Configurable pagination and metadata output via `config.yml`
- `/bookexport` with no arguments uses the signed book title (for written books)
- `/bookexport reload` to reload config
- `/bookexport help` for quick usage info
- Configurable export directory via `exported-books-directory`
- Simplified filenames (no plugin version embedded in the filename anymore)
- `/bookexport list` to list exported `.txt` files in the configured folder
- `color-code-handling` to control how Minecraft color codes are exported
- Hex-colored help and messages, and clickable source URL in `/bookexport help`
- Separate permission nodes for export, list, help, and reload
- Tab-completion for subcommands (`help`, `list`, `reload`)
- Slightly colored console messages so BookExport output stands out without being flashy

## What it does

- Adds a command: `/bookexport [<title>|help|list|reload]`
- Requires permission: `exportbook.export` (and/or `exportbook.command`) to export
- Requires `exportbook.list`, `exportbook.help`, and `exportbook.reload` for those subcommands
- Exports the written book or writable book (book & quill) in your **main hand** to a text file.
- Can list all exported `.txt` files in the configured export directory.
- Can optionally transform Minecraft color codes into different formats.

### Export behaviour

- If you run `/bookexport <title>`  
  → The exported filename is based on `<title>` (sanitized) and saved as:

  ```text
  <Title>.txt
  ```

- If you run `/bookexport` with **no arguments**:
  - If you hold a **written book** with a signed title, that title is used as the filename.
  - If you hold a **writable book** (book & quill) without a title, the plugin shows the help page instead of exporting.

- If the base filename already exists, BookExport appends `_1`, `_2`, etc. to avoid overwriting:

  ```text
  Title.txt
  Title_1.txt
  Title_2.txt
  ```

## Command & Permissions

- **Command:** `/bookexport [<title>|help|list|reload]`

  - `/bookexport <title>` – export using a custom file title  (needs `exportbook.export` or `exportbook.command`)
  - `/bookexport` – export using the book's signed title (for written books)  (same permission as above)
  - `/bookexport list` – list exported `.txt` files in the configured folder  (needs `exportbook.list` or `exportbook.command`)
  - `/bookexport help` – show help  (needs `exportbook.help` or `exportbook.command`)
  - `/bookexport reload` – reload the config  (needs `exportbook.reload` or `exportbook.command`)

- **Permissions:**
  - `exportbook.command` – legacy master permission; grants all other BookExport permissions (default: OP)
  - `exportbook.export` – export books with `/bookexport` (default: OP)
  - `exportbook.list` – use `/bookexport list` (default: OP)
  - `exportbook.help` – use `/bookexport help` (default: OP)
  - `exportbook.reload` – use `/bookexport reload` (default: OP)

## Configuration (`config.yml`)

```yaml
# BookExport configuration

# Where to store the exported books .txt files?
# Default is plugins/BookExport/books/
#
# Types supported:
# - Relative folder name (recommended):
#     "books"
#     -> plugins/BookExport/books/
#
# - Another relative name:
#     "some-books"
#     -> plugins/BookExport/some-books/
#
# - Full absolute path:
#     "/path/to/some/folder/exported_books/"
#
# - From the server root using "~/":
#     "~/plugins/CMI/CustomText/"
#     -> <server root>/plugins/CMI/CustomText/
#
# If empty, BookExport will use the plugin data folder: plugins/BookExport/
exported-books-directory: "books"

# Include pagination at all?
# true  - include a pagination marker before each page
# false - no pagination marker, just plain text pages separated by blank lines
pagination: true

# In the .txt file, how should pagination show when enabled?
# Default is: === Page 1 ===
# For CMI ctext compatibility you might want: "<NextPage>"
#
# Use %pageNumber% as an internal placeholder to show the correct page number in that location.
# Examples:
#   "=== Page %pageNumber% ==="
#   "<NextPage>"
pagination-markup: "=== Page %pageNumber% ==="

# Include book meta data such as author, date, etc?
# Example:
# Title: §71MBNews-April
# Author: Server
# Exported by: mrfloris
# Exported at: 2025-11-22T08:46:20.028303
#
# true  - include this metadata header at the top of the file
# false - skip it, only export the raw text
book-meta: true

# How to handle Minecraft color codes in exported text.
#
# Options:
#   vanilla - keep everything as-is, including §x§A§A§0§0§0§0 style hex and legacy §6 codes
#   legacy  - keep codes but convert from § to & (so §6 becomes &6, §l becomes &l, etc.)
#   strip   - remove all § color and formatting codes entirely
#   cmi     - convert colors to CMI-style {#hex} tags
#   mini    - convert colors to MiniMessage-style <#hex> tags
#
# Notes:
# - Hex sequences like §x§A§A§0§0§0§0 will be converted to {#AA0000} or <#AA0000>.
# - Legacy colors (e.g. §6) use their standard hex equivalents (e.g. #FFAA00).
# - Formatting codes (k, l, m, n, o, r) are ignored in cmi/mini modes and not exported.
color-code-handling: cmi
```

### Export directory resolver

BookExport resolves `exported-books-directory` like this:

- `"books"`  
  → `plugins/BookExport/books/`

- `"some-books"`  
  → `plugins/BookExport/some-books/`

- `"/absolute/path/..."`  
  → uses that absolute path directly.

- `"~/plugins/CMI/CustomText/"`  
  → resolves `~` to the **server root** (the folder that contains `plugins`), then appends and normalizes that path:

  ```text
  <server root>/plugins/CMI/CustomText/
  ```

If the directory does not exist, BookExport will attempt to create it.

## Project structure

```text
bookexport/
├─ pom.xml
├─ build.gradle
├─ settings.gradle
├─ README.md
└─ src/
   └─ main/
      ├─ java/
      │  └─ com/
      │     └─ mrfloris/
      │        └─ exportbook/
      │           └─ ExportBookPlugin.java
      └─ resources/
         ├─ plugin.yml
         └─ config.yml
```

## Building with Gradle (recommended)

From the project root (where `build.gradle` lives):

```bash
cd bookexport
gradle clean build
```

The plugin JAR will be created at:

```text
build/libs/BookExport-1.0.7.jar
```

You can also reference it directly in this repo as:

- `build/libs/[BookExport-1.0.7.jar](build/libs/BookExport-1.0.7.jar)`

Copy that JAR into your server's `plugins/` folder and restart the server.

### Using a specific JDK (optional)

Paper/Spigot 1.21.x target Java 21, but you can build with any JDK >= 21 and `options.release = 21`.

For example, to build with a local JDK 21 on macOS:

```bash
brew install openjdk@21
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
cd bookexport
gradle clean build
```

## Building with Maven

If you prefer Maven:

```bash
cd bookexport
mvn clean package
```

The plugin JAR will be created at:

```text
target/bookexport-1.0.7.jar
```

Copy that JAR to your server's `plugins/` folder and restart.

## Installation on your Paper/Spigot server

1. Build the plugin with **Gradle** or **Maven**.
2. Copy the compiled JAR to your Paper or Spigot 1.21.10 server's `plugins` folder.
3. Start (or restart) the server.
4. Give yourself permission (example with LuckPerms):

     ```text
     /lp user <yourname> permission set exportbook.export true
     /lp user <yourname> permission set exportbook.list true
     /lp user <yourname> permission set exportbook.help true
     /lp user <yourname> permission set exportbook.reload true
     ```

   Or simply:

     ```text
     /lp user <yourname> permission set exportbook.command true
     ```

   to grant all BookExport permissions.

5. Hold a written book or writable book in your **main hand**.
6. Run:

   ```text
   /bookexport My Story
   ```

   or just:

   ```text
   /bookexport
   ```

   or:

   ```text
   /bookexport list
   ```

   to see the exported `.txt` files.

## Source

GitHub (monorepo path):

https://github.com/mrfdev/1MB/tree/master/Resources/BookExport

## License

Do whatever you want with this; no warranty. A credit to **mrfloris** is appreciated but not required.


## Known issues

- Better converting of hex colors is needed.
