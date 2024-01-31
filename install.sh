#!/bin/sh

# Check for required environment variables
required_vars="NAME RPC_URL CHAIN_ID SILO_GENESIS"
for var in $required_vars; do
  # If any required variable is not set, print an error message and exit
  if [ -z "${!var}" ]; then
    echo "Error: Environment variable $var is not set." >&2
    exit 1
  fi
done

# Assign environment variables to local variables for easier use
name=$NAME
rpc_url=$RPC_URL
chain_id=$CHAIN_ID
genesis=$SILO_GENESIS

# Check if EXPLORER_URL is set, if not, create it using rpc_url
if [ -z "$EXPLORER_URL" ]; then
    explorer_url="explorer.$rpc_url"
else
    explorer_url=$EXPLORER_URL
fi

# Generate a random secret key
secret_key_base=$(openssl rand -hex 32)

# Assign optional environment variables to local variables
favicon_generator_api_key=$FAVICON_GENERATOR_API_KEY
wallet_connect_project_id=$NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID

# Define the paths for the Docker Compose template and the actual file
dockercompose_template_file="./config/docker-compose-template.yaml"
dockercompose_file="docker-compose.yaml"

# Copy the Docker Compose template to the working directory
cp "${dockercompose_template_file}" "${dockercompose_file}"

# Replace placeholders in the Docker Compose file with actual values
sed -i '' \
    -e "s/{name}/$name/g" \
    -e "s/{rpc_url}/$rpc_url/g" \
    -e "s/{chain_id}/$chain_id/g" \
    -e "s/{genesis}/$genesis/g" \
    -e "s/{secret_key_base}/$secret_key_base/g" \
    -e "s/{favicon_generator_api_key}/$favicon_generator_api_key/g" \
    -e "s/{wallet_connect_project_id}/$wallet_connect_project_id/g" \
    -e "s/{explorer_url}/$explorer_url/g" \
    $dockercompose_file

# Define the paths for the proxy configuration template and the actual file
proxy_template_file="./config/proxy/default.conf.template"
proxy_file="./data/proxy/default.conf.template"

# Create the directory for the proxy configuration file if it doesn't exist
mkdir -p "$(dirname "$proxy_file")"

# Copy the proxy configuration template to the working directory
cp "$proxy_template_file" "$proxy_file"

# Replace placeholder in the proxy configuration file with actual value
sed -i '' \
    -e "s/{explorer_url}/$explorer_url/g" \
    $proxy_file
