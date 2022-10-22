#!/bin/bash
set -e

curl https://puro.s3.amazonaws.com/builds/master/linux-x64/puro -O
chmod +x puro
./puro -v create example 3.3.5
./puro -v rm example

start_time=$(date +%s.%3N)

./puro -v create example2 3.3.5

create_time=$(date +%s.%3N)

./puro -v -e example2 flutter --version

end_time=$(date +%s.%3N)

create_duration=$(echo "scale=3; $create_time - $start_time" | bc)
run_duration=$(echo "scale=3; $end_time - $create_time" | bc)
total_duration=$(echo "scale=3; $end_time - $start_time" | bc)
echo "Create: ${create_duration}s"
echo "Run: ${run_duration}s"
echo "Total: ${total_duration}s"
