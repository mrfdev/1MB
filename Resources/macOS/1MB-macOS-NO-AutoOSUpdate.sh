#!/usr/bin/env bash

# @Filename: 1MB-macOS-NO-AutoOSUpdate.sh
# @Version: 0.1.0, build 011
# @Release: April 3rd, 2025
# @Description: Helps us make sure Apple doesn't automatically force update macOS after 15.4 anymore.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-macOS-NO-AutoOSUpdate.sh and add to LaunchD or crontab
# @Syntax: sudo ./1MB-macOS-NO-AutoOSUpdate.sh
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

# @Information
# Prevent macOS 15.4+ to set OS updates to true and do as they please,
# we run services and servers, and need to be in control - and schedule - our updates
# disable - Automatic checking for updates (AutomaticCheckEnabled)
# disable - Automatic downloading of macOS and security updates (AutomaticDownload)
# disable - Automatic installation of critical updates (CriticalUpdateInstall)
# disable - App Store app auto-updates (AutoUpdate)
# disable - Background scheduled updates (AutoUpdateRestartRequired)
# disable - softwareupdate <- no apple, NO!!
# disable - pre-release exclusion (AllowPreReleaseInstallation) <- NO

### CONFIGURATION
#
# Declarations here you can customize to your preferred setup.
# Generally only if you actually have to. Check Wiki for details.
#
###

# Our preferences for our set-up, adjust to your liking, I don't mind certain app store things to update in the background, or update checks to run; I just don't want automatic installations and restarts (especially when they are unscheduled)

### FUNCTIONS AND CODE
#
# ! WE ARE DONE, STOP EDITING BEYOND THIS POINT !
#
###

# We require this to run automatically on the daily at least once, as a root or super-user, via launchd or crontab, so let's check for that (or exist)
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

echo "[INFO] Disabling auto update-related settings..."

# Prevent macOS from automatically checking for updates in the background.
# tested: works
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false

# Prevent automatic downloading of macOS updates once available.
# tested: works
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false

# Prevent automatic installation of critical system/data/security updates (XProtect, MRT, whatever it does).
# tested: can not tell if it works (overridden by Apple in GUI)
# defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false

# Prevent automatic updates of Mac App Store applications.
# tested: works
defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false

# Prevent macOS from automatically restarting to apply updates that require a reboot.
# This is the big one, we really don't want this. 
# tested: can not tell if it works
# defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool false

# Disable the background scheduled check for software updates entirely.
# This stops the system from periodically checking for updates on its own.
# tested: works
softwareupdate --schedule off

# Prevent the system from offering pre-release (beta) macOS updates, even if enrolled in a beta seed program.
# This ensures only final, stable versions are available — useful for production machines.
# tested: works
defaults write /Library/Preferences/com.apple.SoftwareUpdate AllowPreReleaseInstallation -bool false

echo "[INFO] Some update features disabled via defaults and softwareupdate."

### CONFIGURATION PROFILE FOR CRITICAL UPDATE BEHAVIOR

# Purpose: Create and install a configuration profile that disables:
#  - Automatic macOS updates (AutomaticallyInstallMacOSUpdates)
#  - Critical security updates (CriticalUpdateInstall)
#  - Security configuration data updates (ConfigDataInstall)
#
# The profile is configured with a removal option (removable) and uses the organization
# name "1MoreBlock.com". This script requires sudo privileges.

# Define final location for the profile
PROFILE_DIR="/usr/local/1moreblock"
PROFILE_PATH="$PROFILE_DIR/DisableCriticalUpdates.mobileconfig"

# Create directory if needed
mkdir -p "$PROFILE_DIR"

# Write the configuration profile
cat <<EOF > "$PROFILE_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>PayloadType</key>
      <string>com.apple.SoftwareUpdate</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
      <key>PayloadIdentifier</key>
      <string>com.1MoreBlock.disablecriticalupdates.softwareupdate</string>
      <key>PayloadUUID</key>
      <string>ABCDEFAB-CDEF-1234-ABCD-ABCDEF123456</string>
      <key>AutomaticallyInstallMacOSUpdates</key>
      <false/>
      <key>CriticalUpdateInstall</key>
      <false/>
      <key>ConfigDataInstall</key>
      <false/>
      <key>ConfigDataInstallDelay</key>
      <integer>0</integer>
    </dict>
  </array>
  <key>PayloadDisplayName</key>
  <string>Disable Critical &amp; macOS Auto Updates</string>
  <key>PayloadIdentifier</key>
  <string>com.1MoreBlock.disablecriticalupdates</string>
  <key>PayloadOrganization</key>
  <string>1MoreBlock.com</string>
  <key>PayloadRemovalDisallowed</key>
  <false/>
  <key>PayloadType</key>
  <string>Configuration</string>
  <key>PayloadUUID</key>
  <string>5F3B5AE1-4C1B-4B93-A6A3-123456789ABC</string>
  <key>PayloadVersion</key>
  <integer>1</integer>
</dict>
</plist>
EOF

echo "[INFO] Configuration profile saved to: $PROFILE_PATH"

# macOS Ventura+ no longer supports 'profiles install' via CLI
# Use `open` to let user install it manually in System Settings
echo "[ACTION] Opening profile for manual install (Ventura+ compatible)..."
open "$PROFILE_PATH"

echo "[DONE] Please click 'Install' in System Settings → Profiles to complete setup."

#EOF Copyright (c) 1977-2025 - Floris Fiedeldij Dop - https://scripts.1moreblock.com