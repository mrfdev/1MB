#!/usr/bin/env bash

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
done
