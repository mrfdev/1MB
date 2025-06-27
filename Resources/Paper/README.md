# 1MB PaperMC Updater Script (v3 API)

This is a **simple, robust bash script** for keeping your [PaperMC](https://papermc.io/) server jar up-to-date using the new [Fill v3 API](https://fill.papermc.io/swagger-ui/index.html).  
It tracks your current build/version in a minimal JSON cache and **only downloads and replaces the Paper jar when there’s an update available**.

## Features

- Works on **macOS and Ubuntu** (other Linuxes likely fine)
- **Backs up** any previous jar before downloading a new one
- **Checks the SHA-256 hash** of every download for security
- **Uses either `curl` or `wget`** (whichever is available)
- **Keeps a minimal cache** for project, version, build, and SHA
- **Reset cache** with `-clearcache` param for fresh install or switching versions
- **Verbose debug mode** enabled by default (set `DEBUG=0` in the script for quiet)
- **Clear error messages** and usage instructions

## Usage

Make the script executable:
```bash
chmod +x 1MB-UpdatePaper-v3api.sh
```

Check for updates (normal use):
```bash
./1MB-UpdatePaper-v3api.sh
```

Reset cache and force a fresh start:
```bash
./1MB-UpdatePaper-v3api.sh -clearcache
```

Show help:
```bash
./1MB-UpdatePaper-v3api.sh -h
```

## Requirements

- `bash`
- [`jq`](https://stedolan.github.io/jq/) (JSON parsing, install with `brew install jq` or `sudo apt install jq`)
- Either [`curl`](https://curl.se/) or [`wget`](https://www.gnu.org/software/wget/`)
- Either `shasum` or `sha256sum` (usually available by default)

## Credit

- Script by **mrfloris**  
- Special thanks to [ChatGPT by OpenAI](https://chat.openai.com/) for help designing and refining the v3 API migration logic and best practices

## License

[MIT](LICENSE) (or specify your own)

---

**Feel free to fork, PR, or suggest improvements!**
