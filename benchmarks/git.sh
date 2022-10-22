#!/bin/bash
set -e

start_time=$(date +%s.%3N)

cat /proc/net/dev

git clone https://github.com/flutter/flutter.git

clone_time=$(date +%s.%3N)

flutter/bin/flutter --version

end_time=$(date +%s.%3N)

clone_duration=$(echo "scale=3; $clone_time - $start_time" | bc)
run_duration=$(echo "scale=3; $end_time - $clone_time" | bc)
total_duration=$(echo "scale=3; $end_time - $start_time" | bc)
echo "Clone: ${clone_duration}s"
echo "Run: ${run_duration}s"
echo "Total: ${total_duration}s"

total_network=$(cat /proc/net/dev | perl -nle 'm/eth0: *([^ ]*)/; print $1' | tr -d '[:space:]')
echo "Network: ${total_network} bytes"