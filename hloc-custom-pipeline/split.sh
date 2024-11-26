#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <start_number> <end_number> <target_directory>"
    echo "Example: $0 1234 5678 ./selected_images"
    exit 1
fi

start_num=$1
end_num=$2
target_dir=$3

# Validate input numbers are 4 digits
if ! [[ $start_num =~ ^[0-9]{4}$ ]] || ! [[ $end_num =~ ^[0-9]{4}$ ]]; then
    echo "Error: Start and end numbers must be 4 digits"
    exit 1
fi

# Check if start is less than or equal to end
if [ "$start_num" -gt "$end_num" ]; then
    echo "Error: Start number must be less than or equal to end number"
    exit 1
fi

# Create target directory if it doesn't exist
mkdir -p "$target_dir"

# Find and move files
found_files=0
for ((i=start_num; i<=end_num; i++)); do
    # Format number with leading zeros if necessary
    padded_num=$(printf "%04d" $i)
    filename="_MG_${padded_num}.JPG"
    
    if [ -f "$filename" ]; then
        echo "Moving: $filename to $target_dir"
        mv "$filename" "$target_dir/"
        ((found_files++))
    fi
done

echo "Move complete! Moved $found_files files."
