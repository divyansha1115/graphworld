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
        DATASET_NAME="heatmap_p_${p_key}_fcd_${fcd_key}_mvertix_${nvertex_value}"
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

echo "All experiments completed successfully."
