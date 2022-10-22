#!/bin/bash
set -e

start_time=$(date +%s.%3N)

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
