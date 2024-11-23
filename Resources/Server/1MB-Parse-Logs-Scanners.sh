#!/usr/bin/env bash

# @Filename: 1MB-Parse-Logs-Scanners.sh
# @Version: 0.1.0, build 006
# @Release: November 23rd, 2024
# @Description: filter logs/ directory for username(s).
# @Contact: I am @floris on Twitter, and mrfloris in MineCraft.
# @Discord: @mrfloris on https://discord.gg/floris
# @Install: chmod +x 1MB-Parse-Logs-Scanners.sh
# @Syntax: ./1MB-Parse-Logs-Scanners.sh -logdir <log_directory> -usernames <username1> [<username2> ... <usernameN>]
# @URL: Latest source, wiki, & support: https://scripts.1moreblock.com/

# Initialize log directory and usernames array
log_dir=""
usernames=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -logdir)
      log_dir="$2"
      shift 2
      ;;
    -usernames)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
        usernames+=("$1")
        shift
      done
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Ensure at least one username is provided
if [ "${#usernames[@]}" -eq 0 ]; then
  echo "Usage: $0 -logdir <log_directory> -usernames <username1> [<username2> ... <usernameN>]"
  exit 1
fi

# If log directory is not provided, check if current directory contains 'logs' directory
if [ -z "$log_dir" ]; then
  if [[ "$(basename $(pwd))" != "logs" ]]; then
    echo "Log directory not specified and current directory is not a 'logs' directory. Exiting."
    exit 1
  else
    log_dir="$(pwd)"
  fi
fi

# Check if the provided log directory exists
if [ ! -d "$log_dir" ]; then
  echo "Log directory '$log_dir' not found!"
  exit 1
fi

# Define the date format and output directory suffix
DATE_FORMAT="%Y-%m-%d"
OUTPUT_DIR_SUFFIX="_logs"
# Get the current date, ensuring compatibility with both GNU and BSD date versions
current_date=$(date +"$DATE_FORMAT" 2>/dev/null || gdate +"$DATE_FORMAT")

# Create an output directory named with the current date
output_dir="${current_date}${OUTPUT_DIR_SUFFIX}"
mkdir -p "$output_dir"

# Loop through each username and perform search
for username in "${usernames[@]}"
do
  # Define the output file name for the current username
  output_file="${output_dir}/${username}.log"
  touch "$output_file"

  # Search through all .log files and .tar.gz archives in the log directory
  for log_file in "$log_dir"/*.log "$log_dir"/*.tar.gz
  do
    if [[ -f "$log_file" ]]; then
      if [[ "$log_file" == *.tar.gz ]]; then
        # Use zgrep for .tar.gz files, including filename and line number
        zgrep -Hin "$username" "$log_file" | sed 's|$log_dir/||' | sed 's|$log_dir/||' >> "$output_file"
      else
        # Use grep for .log files, including filename and line number
        grep -Hin "$username" "$log_file" >> "$output_file"
      fi
    fi
  done

  # Check if the output file has content
  if [ -s "$output_file" ]; then
    echo "Results for '$username' written to '$output_file'"
  else
    echo "No results found for '$username' in any log files"
    rm "$output_file"
  fi
done

#EOF Copyright (c) 1977-2024 - Floris Fiedeldij Dop - https://scripts.1moreblock.com