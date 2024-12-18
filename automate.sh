#!/bin/bash

# Variables
gin_file_path="/nethome/d39/GraphRPE/graphworld/src/configs/nodeclassification_generators/sbm/default_param_ranges.gin"
main_script="./main_local_mwe.sh"
build_script="./build_local.sh"
BUILD_NAME="graphworld"
OUTPUT_BASE_PATH="/tmp/GraphRPE/graph_world"

# Dictionaries
# declare -A p_dict=( [0]=0 [0125]=0.125 [025]=0.25 [05]=0.5 [1]=1 [2]=2 [4]=4 [8]=8 )
# declare -A fcd_dict=( [0]=0.0 [01]=0.1 [02]=0.2 [03]=0.3 [04]=0.4 [05]=0.5 )
declare -A p_dict=( [0]=0 [0125]=0.125 [025]=0.25 [05]=0.5 [1]=1 [2]=2)
declare -A fcd_dict=( [0]=0.0 [005]=0.05 [01]=0.1 [02]=0.2 [03]=0.3 )


# declare -A p_dict=( [0]=0 [0125]=0.125 )
# declare -A fcd_dict=( [0]=0.0 [01]=0.1 )
# Dictionaries
# declare -A p_dict
# p_dict[0]=0
# p_dict[0125]=0.125

# declare -A fcd_dict
# fcd_dict[0]=0.0
# fcd_dict[01]=0.1

# Default nvertex value
nvertex_value=1024

# Function to update .gin file
update_gin_file() {
    local p_value=$1
    local fcd_value=$2
    sed -i "s/.*p_to_q_ratio\/ParamSamplerSpec\.min_val.*/p_to_q_ratio\/ParamSamplerSpec.min_val = $p_value/" "$gin_file_path"
    sed -i "s/.*p_to_q_ratio\/ParamSamplerSpec\.max_val.*/p_to_q_ratio\/ParamSamplerSpec.max_val = $p_value/" "$gin_file_path"
    sed -i "s/.*feature_center_distance\/ParamSamplerSpec\.min_val.*/feature_center_distance\/ParamSamplerSpec.min_val = $fcd_value/" "$gin_file_path"
    sed -i "s/.*feature_center_distance\/ParamSamplerSpec\.max_val.*/feature_center_distance\/ParamSamplerSpec.max_val = $fcd_value/" "$gin_file_path"
    sed -i "s/.*nvertex\/ParamSamplerSpec\.min_val.*/nvertex\/ParamSamplerSpec.min_val = $nvertex_value/" "$gin_file_path"
    sed -i "s/.*nvertex\/ParamSamplerSpec\.max_val.*/nvertex\/ParamSamplerSpec.max_val = $nvertex_value/" "$gin_file_path"
}


for graph_num in {0..10}; do
    # Iterate over p and fcd values
    for p_key in "${!p_dict[@]}"; do
        for fcd_key in "${!fcd_dict[@]}"; do
            p_value=${p_dict[$p_key]}
            fcd_value=${fcd_dict[$fcd_key]}

            # Update gin file
            echo "Updating .gin file for p = $p_value, fcd = $fcd_value, and nvertex = $nvertex_value"
            update_gin_file "$p_value" "$fcd_value"

            # Build the project first
            echo "Building the project..."
            $build_script
            # Set dataset name
            DATASET_NAME="heatmap_graph_${graph_num}_p_${p_key}_fcd_${fcd_key}_nvertix_${nvertex_value}_single_hyp_exp"
            OUTPUT_PATH="${OUTPUT_BASE_PATH}/${DATASET_NAME}"

            # Clear and recreate output directory
            rm -rf "$OUTPUT_PATH"
            mkdir -p "$OUTPUT_PATH"

            # Run main script with updated parameters
            echo "Running docker-compose for dataset: $DATASET_NAME"
            docker-compose run \
            --entrypoint "python3 /app/beam_benchmark_main.py \
            --output ${OUTPUT_PATH} \
            --gin_files /app/configs/nodeclassification_mwe_custom.gin \
            --write_intermediate True \
            --runner DirectRunner" \
            ${BUILD_NAME}
        done
    done
done 
echo "All experiments completed successfully."

# !/bin/bash

# # Error handling
# set -euo pipefail
# IFS=$'\n\t'

# # Variables
# readonly GIN_FILE_PATH="/nethome/d39/GraphRPE/graphworld/src/configs/nodeclassification_generators/sbm/default_param_ranges.gin"
# readonly BUILD_SCRIPT="./build_local.sh"
# readonly BUILD_NAME="graphworld"
# readonly OUTPUT_BASE_PATH="/tmp/GraphRPE/graph_world"
# readonly MAX_PARALLEL_JOBS=4
# readonly DOCKER_TIMEOUT=300  # 5 minutes timeout
# readonly CPU_LIMIT="1"
# readonly MEMORY_LIMIT="4g"
# readonly LOG_DIR="${OUTPUT_BASE_PATH}/logs"

# # Arrays for p and fcd values
# declare -A p_map=(
#     ["0"]="0.0"
#     ["0125"]="0.125"
# )
# declare -A fcd_map=(
#     ["0"]="0.0"
#     ["005"]="0.05"
# )

# # Default nvertex value
# readonly NVERTEX_VALUE=1024

# # Create necessary directories
# mkdir -p "${OUTPUT_BASE_PATH}" "${LOG_DIR}"
# TEMP_DIR=$(mktemp -d)

# # Enhanced cleanup function with logging
# cleanup() {
#     local exit_code=$?
#     echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleaning up..." | tee -a "${LOG_DIR}/cleanup.log"
    
#     # Stop all related containers
#     docker ps -q --filter "name=${BUILD_NAME}" | while read -r container; do
#         echo "Stopping container: $container" | tee -a "${LOG_DIR}/cleanup.log"
#         docker stop "$container" || true
#     done
    
#     docker-compose down --remove-orphans
#     rm -rf "$TEMP_DIR"
    
#     # Log final status
#     if [ $exit_code -eq 0 ]; then
#         echo "$(date '+%Y-%m-%d %H:%M:%S') - Script completed successfully" | tee -a "${LOG_DIR}/cleanup.log"
#     else
#         echo "$(date '+%Y-%m-%d %H:%M:%S') - Script failed with exit code: $exit_code" | tee -a "${LOG_DIR}/cleanup.log"
#     fi
# }
# trap cleanup EXIT SIGINT SIGTERM

# # Function to validate input parameters
# validate_params() {
#     local p_value=$1
#     local fcd_value=$2
    
#     if ! [[ $p_value =~ ^[0-9]+\.?[0-9]*$ ]]; then
#         echo "Error: Invalid p_value: $p_value" >&2
#         return 1
#     fi
    
#     if ! [[ $fcd_value =~ ^[0-9]+\.?[0-9]*$ ]]; then
#         echo "Error: Invalid fcd_value: $fcd_value" >&2
#         return 1
#     fi
    
#     return 0
# }