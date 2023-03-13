#!/bin/bash

# Function to count files in directory and subdirectories
count_files () {
    local dir="$1"
    local count=$(find "$dir" -type f | wc -l)
    echo "Number of files in $dir: $count"
}

# Loop through each argument and count files in each directory
for dir in "$@"; do
    count_files "$dir"
done
