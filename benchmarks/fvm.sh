#!/bin/bash
set -e

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

start_time=$(date +%s.%3N)

brew tap leoafarias/fvm
brew install fvm

install_time=$(date +%s.%3N)
install_network=$(cat /proc/net/dev | perl -nle 'm/eth0: *([^ ]*)/; print $1' | tr -d '[:space:]')

fvm install 3.3.5

install_flutter_time=$(date +%s.%3N)

fvm spawn 3.3.5 --version

end_time=$(date +%s.%3N)

install_duration=$(echo "scale=3; $install_time - $start_time" | bc)
install_flutter_duration=$(echo "scale=3; $install_flutter_time - $install_time" | bc)
run_duration=$(echo "scale=3; $end_time - $install_flutter_time" | bc)
total_duration=$(echo "scale=3; $end_time - $start_time" | bc)
echo "Install: ${install_duration}s"
echo "Install Flutter: ${install_flutter_duration}s"
echo "Run: ${run_duration}s"
echo "Total: ${total_duration}s"

total_network=$(cat /proc/net/dev | perl -nle 'm/eth0: *([^ ]*)/; print $1' | tr -d '[:space:]')
echo "Install Network: ${install_network} bytes"
echo "Total Network: ${total_network} bytes"