#!/bin/bash

# Check if correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <sparse_models_base_dir> <images_base_dir>"
    echo "Example: $0 /path/to/models /path/to/images"
    exit 1
fi

MODELS_BASE_DIR="$1"
IMAGES_BASE_DIR="$2"

# Check if directories exist
if [ ! -d "$MODELS_BASE_DIR" ]; then
    echo "Error: Models directory does not exist: $MODELS_BASE_DIR"
    exit 1
fi

if [ ! -d "$IMAGES_BASE_DIR" ]; then
    echo "Error: Images directory does not exist: $IMAGES_BASE_DIR"
    exit 1
fi

# Function to process a single model
process_model() {
    local model_dir="$1"
    local image_dir="$2"
    local model_name="$(basename "$model_dir")"
    local sparse_model_dir="${model_dir}/model"
    local workspace_dir="${model_dir}/dense"
    
    echo "Processing model: $model_name"
    echo "Using images from: $image_dir"
    echo "Using sparse model from: $sparse_model_dir"
    echo "Output will be saved to: $workspace_dir"
    
    # Create dense workspace directory
    mkdir -p "$workspace_dir"

    
    # Step 1: Image undistortion
    echo "Running image undistortion..."
    colmap image_undistorter \
        --image_path "$image_dir" \
        --input_path "$sparse_model_dir" \
        --output_path "$workspace_dir" \
        --output_type COLMAP \
        --max_image_size 2000
    
    # Check if previous step was successful
    if [ $? -ne 0 ]; then
        echo "Error during image undistortion for $model_name"
        return 1
    fi
    
    # Step 2: Patch match stereo
    echo "Running patch match stereo..."
    colmap patch_match_stereo \
        --workspace_path "$workspace_dir" \
        --workspace_format COLMAP \
        --PatchMatchStereo.geom_consistency true
    
    if [ $? -ne 0 ]; then
        echo "Error during patch match stereo for $model_name"
        return 1
    fi
    
    # Step 3: Stereo fusion
    echo "Running stereo fusion..."
    colmap stereo_fusion \
        --workspace_path "$workspace_dir" \
        --workspace_format COLMAP \
        --input_type geometric \
        --output_path "$workspace_dir/fused.ply"
    
    if [ $? -ne 0 ]; then
        echo "Error during stereo fusion for $model_name"
        return 1
    fi
    
    # Step 4: Poisson mesh reconstruction
    echo "Running Poisson surface reconstruction..."
    colmap poisson_mesher \
        --input_path "$workspace_dir/fused.ply" \
        --output_path "$workspace_dir/meshed-poisson.ply"
    
    if [ $? -ne 0 ]; then
        echo "Error during poisson meshing for $model_name"
        return 1
    fi
    
    echo "Completed processing model: $model_name"
    return 0
}

# Process all subdirectories
for model_dir in "$MODELS_BASE_DIR"/*/; do
    if [ -d "$model_dir" ]; then
        model_name="$(basename "$model_dir")"
        
        # Skip if the directory name is not "outputs"
        if [ "$model_name" == "outputs" ]; then
            continue
        fi
        
        corresponding_image_dir="$IMAGES_BASE_DIR/$model_name"
        
        if [ ! -d "$corresponding_image_dir" ]; then
            echo "Warning: No corresponding image directory found for model $model_name"
            echo "Expected: $corresponding_image_dir"
            continue
        fi
        
        echo "==============================================="
        echo "Starting processing of model: $model_name"
        echo "==============================================="
        
        process_model "$model_dir" "$corresponding_image_dir"
        
        if [ $? -eq 0 ]; then
            echo "Successfully processed $model_name"
        else
            echo "Failed to process $model_name"
        fi
    fi
done

echo "All models processed"
