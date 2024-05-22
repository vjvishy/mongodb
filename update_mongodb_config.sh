#!/bin/bash

# Check if all parameters are provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <PUBLIC_DNS>"
  exit 1
fi

# Set parameters
PUBLIC_DNS=$1

# Update the MongoDB configuration file to bind to the public DNS
sudo sed -i "s/bindIp: 127.0.0.1/bindIp: $PUBLIC_DNS/g" /etc/mongod.conf
echo "Updated bindIp in /etc/mongod.conf to make it publicly available"

# Update the MongoDB configuration file to enable authorization
sudo sed -i "s/#security:/security:\n  authorization: enabled/g" /etc/mongod.conf
echo "Updated security parameter in /etc/mongod.conf to enable authorization"

# Restart the MongoDB service to apply the new configuration
sudo systemctl restart mongod
echo "Restarted mongod system service"