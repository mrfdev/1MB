#!/usr/bin/env bash
# version 0.0.2, build 003

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <log_file> <username1> [<username2> ... <usernameN>]"
  exit 1
fi

log_file=$1
if [ ! -f "$log_file" ]; then
  echo "Log file '$log_file' not found!"
  exit 1
fi

current_date=$(date +"%Y-%m-%d")

shift
for username in "$@"
do
  output_file="${current_date}-${username}.log"
  grep "$username" "$log_file" > "$output_file"
  if [ $? -eq 0 ]; then
    echo "Results for '$username' written to '$output_file'"
  else
    echo "No results found for '$username' in '$log_file'"
    rm "$output_file"
  fi
done

#EOF Copyright (c) 1977-2024 - Floris Fiedeldij Dop - https://scripts.1moreblock.com