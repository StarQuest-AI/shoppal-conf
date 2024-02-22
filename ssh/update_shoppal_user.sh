#!/bin/bash

# Get the current system username
SYSTEM_USER=$(id -un)

# Prompt the user for their shoppal username
read -p "Is your shoppal username the same as your system username ($SYSTEM_USER)? (Y/N): " user_response

# Check the user's response
if [[ $user_response == "Y" ]]; then
    echo "No changes made."
    exit 0
elif [[ $user_response == "N" ]]; then
    # Ask for the shoppal username
    read -p "Enter your shoppal username: " shoppal_user

    # Insert lines into ~/.ssh/config
    ssh_config="$HOME/.ssh/config"
    # Create the file if it does not exist
    touch "$ssh_config"
    # Insert the necessary lines at the beginning of the file
    sed -i '' '1i\
#### Generated for Shoppal ####\
Include ~/.shoppal/ssh/config\
Host *\
  User '"$shoppal_user"'\
  ConnectTimeout 60\
  ServerAliveInterval 15\
  ServerAliveCountMax 4\
  TCPKeepAlive yes\
  StrictHostKeyChecking=no\
#### Generated for Shoppal ####\

' "$ssh_config"

    # Append line to ~/.shoppal/env.sh
    env_sh="$HOME/.shoppal/env.sh"
    # Create the file and the directory if they do not exist
    mkdir -p "$(dirname "$env_sh")"
    touch "$env_sh"
    # Append the necessary line at the end of the file
    echo "export SHOPPAL_USER=$shoppal_user" >> "$env_sh"

    echo "Updated configuration with your shoppal username."
else
    echo "Invalid response. Exiting."
    exit 1
fi

