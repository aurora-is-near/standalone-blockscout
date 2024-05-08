#!/bin/bash

declare -a files=(
"common-blockscout.env"
"common-frontend.env"
"common-smart-contract-verifier.env"
"common-stats.env"
"common-visualizer.env"
)

# Loop over the array of URLs
for file_name in "${files[@]}"
do
    # Define the path where the file will be stored
    file_path="$config_dir/$file_name"

    # Download the file using curl
    curl -L -o "config/$file_path" "https://raw.githubusercontent.com/aurora-is-near/blockscout/master/docker-compose/envs/$file_path"

    # Check if the download was successful
    if [ -f "config/$file_path" ]; then
        echo "File downloaded successfully: $file_path"
    else
        echo "Failed to download the file: $file_path"
        exit 1
    fi
done
