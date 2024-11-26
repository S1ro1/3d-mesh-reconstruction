#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <input_base_dir> <output_base_dir> [max_parallel_jobs]"
    echo "Example: $0 ./input_folders ./output_folders 4"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
# Default to number of CPU cores if max_parallel_jobs not specified
MAX_JOBS=${3:-$(nproc)}

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory $INPUT_DIR does not exist"
    exit 1
fi

# Create output base directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to process a single folder
process_folder() {
    local folder_name="$1"
    local input_path="$INPUT_DIR/$folder_name"
    local output_path="$OUTPUT_DIR/outputs/$folder_name"
    
    echo "Processing folder: $folder_name"
    echo "Output will be saved to: $output_path"
    
    # Create temporary config file with modified output path
    local temp_config=$(mktemp)
    cat > "$temp_config" << EOF
image_dir: $input_path
base_output_dir: $output_path
use_exhaustive: True
visualize: False
force_overwrite: True
retrieval_conf: netvlad
feature_conf: superpoint_inloc
matcher_conf: superglue
EOF
    
    # Run the Python script with the temporary config
    python3 main.py --config "$temp_config"
    
    # Clean up temporary config
    rm "$temp_config"
}

export -f process_folder
export INPUT_DIR OUTPUT_DIR

# Find all directories in the input folder and process them in parallel
find "$INPUT_DIR" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | \
    parallel -j "$MAX_JOBS" process_folder {}

echo "All folders processed successfully!"
