#!/bin/bash
set -e

start_time=$(date +%s.%3N)

curl -o- https://puro.dev/install.sh | PURO_VERSION="master" bash
export PATH="$PATH:\$HOME/.puro/bin"

install_time=$(date +%s.%3N)

./puro --no-progress -v create example 3.3.5

create_time=$(date +%s.%3N)

./puro --no-progress -v -e example flutter --version

end_time=$(date +%s.%3N)

install_duration=$(echo "scale=3; $install_time - $start_time" | bc)
create_duration=$(echo "scale=3; $create_time - $install_time" | bc)
run_duration=$(echo "scale=3; $end_time - $create_time" | bc)
total_duration=$(echo "scale=3; $end_time - $start_time" | bc)
echo "Install: ${install_duration}s"
echo "Create: ${create_duration}s"
echo "Run: ${run_duration}s"
echo "Total: ${total_duration}s"

total_network=$(cat /proc/net/dev | perl -nle 'm/eth0: *([^ ]*)/; print $1' | tr -d '[:space:]')
echo "Network: ${total_network} bytes"