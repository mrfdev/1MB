#!/bin/bash
# version 0.0.2, build 002

# generate some valid mc usernames with prefix user_
generate_username() {
    local username="User_$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 6)"
    echo "$username"
}

# and make 500 of them
usernames=()
for i in {1..500}; do
    usernames+=("$(generate_username)")
done

# keep track of where we are
count=0

# lets go through that list, and send a command to the server (and pause in between, and after every 25)
for username in "${usernames[@]}"; do
    # spawn a fake player, send it to the minecraft screen session
    screen -S minecraft -p 0 -X stuff "fp spawn $username$(printf '\r')"
    
    # and take a breather
    sleep 3
    ((count++))
    
    # Every 25 commands, send 'cmi tps' and 'cmi status' and take another breather
    if (( count % 25 == 0 )); then
        screen -S minecraft -p 0 -X stuff "cmi tps$(printf '\r')"
        sleep 1
        screen -S minecraft -p 0 -X stuff "cmi status$(printf '\r')"
        sleep 1
    fi
done

# we are done
echo "All commands sent to the Minecraft server."

#EOF Copyright (c) 1977-2025 - Floris Fiedeldij Dop - https://scripts.1moreblock.com