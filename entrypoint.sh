#!/bin/bash

# Check if the IPFS configuration file exists and modify it
if [ -f ~/.ipfs/config ]; then
    # Set the API and Gateway addresses to listen on all interfaces
    ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
    ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
else
    # Initialize IPFS (if not already initialized)
    ipfs init
    ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
    ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
fi

# Start ipfs and ipdr in the background
ipfs daemon &> ipfs.log &
ipdr server &> ipdr.log &

touch ipfs.log ipdr.log

# Display the logs
tail -f ipfs.log ipdr.log