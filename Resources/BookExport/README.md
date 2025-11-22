# BookExport

A tiny Paper 1.21.10 plugin by **mrfloris** that exports the book in your main hand to a plaintext `.txt` file.

This is version **1.0.3**, building on earlier versions by adding:

- Configurable pagination and metadata output via `config.yml`
- `/bookexport` with no arguments uses the signed book title (for written books)
- `/bookexport reload` to reload config
- `/bookexport help` for quick usage info
- Configurable export directory via `exported-books-directory`
- Simplified filenames (no plugin version embedded in the filename anymore)
- `/bookexport list` to list exported `.txt` files in the configured folder

## What it does

- Adds a command: `/bookexport [<title>|help|list|reload]`
- Requires permission: `exportbook.command` (and `exportbook.reload` for reload)
- Exports the written book or writable book (book & quill) in your **main hand** to a text file.
- Can list all exported `.txt` files in the configured export directory.

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

  - `/bookexport <title>` – export using a custom file title
  - `/bookexport` – export using the book's signed title (for written books)
  - `/bookexport list` – list exported `.txt` files in the configured folder
  - `/bookexport help` – show help
  - `/bookexport reload` – reload the config

- **Permissions:**
  - `exportbook.command` – use `/bookexport`, list exports, and view help (default: OP)
  - `exportbook.reload` – reload the config (default: OP)

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
  → resolves `~` to the **server root** (the folder that contains `plugins`), then appends that path:

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
build/libs/BookExport-1.0.3.jar
```

Copy that JAR into your server's `plugins/` folder and restart the server.

### Using a specific JDK (optional)

Paper 1.21.x targets Java 21, but you can build with any JDK >= 21 and `options.release = 21`.

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
target/bookexport-1.0.3.jar
```

Copy that JAR to your server's `plugins/` folder and restart.

## Installation on your Paper server

1. Build the plugin with **Gradle** or **Maven**.
2. Copy the compiled JAR to your Paper 1.21.10 server's `plugins/` folder.
3. Start (or restart) the server.
4. Give yourself permission:

   - With LuckPerms, for example:

     ```text
     /lp user <yourname> permission set exportbook.command true
     /lp user <yourname> permission set exportbook.reload true
     ```

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

## License

Do whatever you want with this; no warranty. A credit to **mrfloris** is appreciated but not required.
