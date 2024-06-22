#!/bin/bash

# Start ipfs and ipdr in the background
ipfs daemon &> ipfs.log &
ipdr server &> ipdr.log &

touch ipfs.log ipdr.log

# Display the logs
tail -f ipfs.log ipdr.log