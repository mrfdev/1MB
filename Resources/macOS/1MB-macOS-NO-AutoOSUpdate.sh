#!/usr/bin/env bash

# @Filename: 1MB-macOS-NO-AutoOSUpdate.sh
# @Version: 0.0.3, build 004
# @Release: April 3rd, 2025
# @Description: Helps us make sure Apple doesn't automatically force update macOS after 15.4 anymore.
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-macOS-NO-AutoOSUpdate.sh and add to LaunchD or crontab
# @Syntax: ./1MB-macOS-NO-AutoOSUpdate.sh
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
  echo "Please run as root (su)"
  echo "sudo $0"
  exit 1
fi

echo "Disabling things.."

# Disable the @information stuff:

# Prevent macOS from automatically checking for updates in the background.
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false

# Prevent automatic downloading of macOS updates once available.
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false

# Prevent automatic installation of critical system/data/security updates (XProtect, MRT, whatever it does).
defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false

# Prevent automatic updates of Mac App Store applications.
defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false

# Prevent macOS from automatically restarting to apply updates that require a reboot.
# This is the big one, we really don't want this. 
defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool false

# Disable the background scheduled check for software updates entirely.
# This stops the system from periodically checking for updates on its own.
softwareupdate --schedule off

# Prevent the system from offering pre-release (beta) macOS updates, even if enrolled in a beta seed program.
# This ensures only final, stable versions are available — useful for production machines.
defaults write /Library/Preferences/com.apple.SoftwareUpdate AllowPreReleaseInstallation -bool false

echo "A bunch of auto update things should be disabled again."

#EOF Copyright (c) 1977-2025 - Floris Fiedeldij Dop - https://scripts.1moreblock.com