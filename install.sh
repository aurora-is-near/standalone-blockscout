#!/bin/sh

# Default values
ENV_FILE=".env"

# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --env=*)
            ENV_FILE="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: ./install.sh [--env=filename.env]"
            exit 1
            ;;
    esac
done

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file $ENV_FILE not found!"
    exit 1
fi

echo "Loading environment variables..."
set -a # automatically export all variables
source "$ENV_FILE"
set +a

# Set CONTAINERS_PREFIX if not explicitly set
if [ -z "$CONTAINERS_PREFIX" ]; then
    CONTAINERS_PREFIX="${NAMESPACE}-"
    export CONTAINERS_PREFIX
fi

# Set deployment directory name
DEPLOY_DIR="standalone-blockscout-$NAMESPACE"

# Set deployment directory for persistent data
data_dir="$REMOTE_DIR/$DEPLOY_DIR"
echo "Data directory: $data_dir"

# Check for required environment variables
required_vars="NAME NAMESPACE RPC_URL CHAIN_ID GENESIS BLOCKSCOUT_PROTOCOL RPC_PROTOCOL CURRENCY_SYMBOL VERIFIER_TYPE CPU_LIMIT POSTGRES_RO_PASSWORD"
for var in $required_vars; do
  # If any required variable is not set, print an error message and exit
  if [ -z "$(eval echo \$$var)" ]; then
    echo "Error: Environment variable $var is not set." >&2
    exit 1
  fi
done

# Check if using external database
if [ -n "$DATABASE_URL" ]; then
    echo "Using external database configuration..."
    postgres_password=""  # Empty since we're using external DB
    database_url=$DATABASE_URL
    depends_on_db=""
    depends_on_db_list="[]"
    # Extract database name from DATABASE_URL
    database_name=$(echo "$DATABASE_URL" | sed -n 's/.*\/\([^?]*\).*/\1/p')
else
    echo "Using local database configuration..."
    postgres_password_file="$data_dir/.postgres_password"
    # Generate or read PostgreSQL password
    if [ -f "$postgres_password_file" ]; then
        echo "Reading existing PostgreSQL password..."
        postgres_password=$(cat "$postgres_password_file")
    else
        echo "Generating new PostgreSQL password..."
        postgres_password=$(openssl rand -hex 16)
        # Ensure data directory exists
        mkdir -p "$data_dir"
        echo "$postgres_password" > "$postgres_password_file"
    fi
    database_url="postgresql://blockscout:$postgres_password@db:5432/blockscout"
    depends_on_db="- db"
    depends_on_db_list="[db]"
    database_name="blockscout"
fi

# Assign environment variables to local variables for easier use
name=$NAME
rpc_url=$RPC_URL
chain_id=$CHAIN_ID
genesis=$GENESIS
network_logo=$NETWORK_LOGO
network_logo_dark=$NETWORK_LOGO_DARK
network_icon=$NETWORK_ICON
supabase_url=$SUPABASE_URL
supabase_realtime_url=$SUPABASE_REALTIME_URL
supabase_anon_key=$SUPABASE_ANON_KEY
postgres_ro_password=$POSTGRES_RO_PASSWORD

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
currency_symbol=$CURRENCY_SYMBOL

# Set network from environment or default to mainnet
network=$NETWORK
if [ -z "$network" ]; then
    network="mainnet"
fi

# Set ports from environment or defaults
blockscout_port=$BLOCKSCOUT_PORT
if [ -z "$blockscout_port" ]; then
    blockscout_port="80"
fi

postgres_port=$POSTGRES_PORT
if [ -z "$postgres_port" ]; then
    postgres_port="7432"
fi

stats_service_port=$STATS_SERVICE_PORT
if [ -z "$stats_service_port" ]; then
    stats_service_port="8080"
fi

stats_api_host=$STATS_API_HOST
if [ -z "$stats_api_host" ]; then
    stats_api_host="stats.$explorer_url"
fi

visualizer_service_port=$VISUALIZER_SERVICE_PORT
if [ -z "$visualizer_service_port" ]; then
    visualizer_service_port="8081"
fi

visualizer_api_host=$VISUALIZER_API_HOST
if [ -z "$visualizer_api_host" ]; then
    visualizer_api_host="visualize.$explorer_url"
fi

smart_contract_verifier_service_port=$SMART_CONTRACT_VERIFIER_SERVICE_PORT
if [ -z "$smart_contract_verifier_service_port" ]; then
    smart_contract_verifier_service_port="8050"
fi

# Set verifier configuration
verifier_type=$VERIFIER_TYPE
if [ "$verifier_type" = "eth_bytecode_db" ]; then
    verifier_url="https:\/\/eth-bytecode-db.services.blockscout.com\/"
    smart_contract_verifier_port_mapping=""
else
    verifier_url="http:\/\/smart-contract-verifier:8050\/"
    smart_contract_verifier_port_mapping="- \"$smart_contract_verifier_service_port:8050\""
fi

# Set containers prefix
containers_prefix=$CONTAINERS_PREFIX
if [ -n "$containers_prefix" ] && [[ "$containers_prefix" != *- ]]; then
    containers_prefix="${containers_prefix}-"
fi

# Set protocol configurations
blockscout_protocol=$BLOCKSCOUT_PROTOCOL
if [ "$blockscout_protocol" = "secured" ]; then
    blockscout_http_protocol="https"
    blockscout_ws_protocol="wss"
else
    blockscout_http_protocol="http"
    blockscout_ws_protocol="ws"
fi

rpc_protocol=$RPC_PROTOCOL
if [ "$rpc_protocol" = "secured" ]; then
    rpc_http_protocol="https"
    rpc_ws_protocol="wss"
else
    rpc_http_protocol="http"
    rpc_ws_protocol="ws"
fi

# Set testnet flag based on network
if [ "$network" = "mainnet" ]; then
    is_testnet="false"
else
    is_testnet="true"
fi

# Set CPU limit
cpu_limit=$CPU_LIMIT
if [ -z "$cpu_limit" ]; then
    cpu_limit="1"
fi

# Generate configurations
echo "Generating configurations..."

# Define the paths for the Docker Compose template and the actual file
dockercompose_template_file="./config/docker-compose-template.yaml"
dockercompose_file="docker-compose.yaml"

# Replace placeholders in the Docker Compose file with actual values
sed \
    -e "s/{name}/$name/g" \
    -e "s/{rpc_url}/$rpc_url/g" \
    -e "s/{chain_id}/$chain_id/g" \
    -e "s/{genesis}/$genesis/g" \
    -e "s/{secret_key_base}/$secret_key_base/g" \
    -e "s/{postgres_password}/$postgres_password/g" \
    -e "s/{favicon_generator_api_key}/$favicon_generator_api_key/g" \
    -e "s/{wallet_connect_project_id}/$wallet_connect_project_id/g" \
    -e "s/{explorer_url}/$explorer_url/g" \
    -e "s/{blockscout_port}/$blockscout_port/g" \
    -e "s/{postgres_port}/$postgres_port/g" \
    -e "s/{stats_service_port}/$stats_service_port/g" \
    -e "s/{stats_api_host}/$stats_api_host/g" \
    -e "s/{visualizer_service_port}/$visualizer_service_port/g" \
    -e "s/{visualizer_api_host}/$visualizer_api_host/g" \
    -e "s/{smart_contract_verifier_service_port}/$smart_contract_verifier_service_port/g" \
    -e "s/{containers_prefix}/$containers_prefix/g" \
    -e "s/{blockscout_http_protocol}/$blockscout_http_protocol/g" \
    -e "s/{blockscout_ws_protocol}/$blockscout_ws_protocol/g" \
    -e "s/{rpc_http_protocol}/$rpc_http_protocol/g" \
    -e "s/{rpc_ws_protocol}/$rpc_ws_protocol/g" \
    -e "s/{currency_symbol}/$currency_symbol/g" \
    -e "s/{verifier_type}/$verifier_type/g" \
    -e "s/{smart_contract_verifier_restart_policy}/$smart_contract_verifier_restart_policy/g" \
    -e "s/{smart_contract_verifier_disabled}/$smart_contract_verifier_disabled/g" \
    -e "s/{verifier_url}/$verifier_url/g" \
    -e "s/{is_testnet}/$is_testnet/g" \
    -e "s/{cpu_limit}/$cpu_limit/g" \
    -e "s/{network}/$network/g" \
    -e "s|{network_logo}|$network_logo|g" \
    -e "s|{network_logo_dark}|$network_logo_dark|g" \
    -e "s|{network_icon}|$network_icon|g" \
    -e "s/{smart_contract_verifier_port_mapping}/$smart_contract_verifier_port_mapping/g" \
    -e "s|{database_url}|$database_url|g" \
    -e "s|{database_name}|$database_name|g" \
    -e "s|{depends_on_db}|$depends_on_db|g" \
    -e "s|{depends_on_db_list}|$depends_on_db_list|g" \
    -e "s|{postgres_ro_password}|$postgres_ro_password|g" \
    $dockercompose_template_file > $dockercompose_file

echo "dockercompose_file: $dockercompose_file"

# Append sidecar configuration if enabled
if [ "$SIDECAR_ENABLED" = "true" ]; then
    echo "Adding sidecar configuration..."
    sed \
        -e "s/{containers_prefix}/$containers_prefix/g" \
        config/sidecar-docker-template.yaml >> $dockercompose_file
fi

# Append verifier configuration if not using eth_bytecode_db
if [ "$verifier_type" != "eth_bytecode_db" ]; then
    echo "Adding verifier configuration..."
    sed \
        -e "s/{containers_prefix}/$containers_prefix/g" \
        config/verifier-docker-template.yaml >> $dockercompose_file
fi

# If using external database, update the database URLs
if [ -z "$DATABASE_URL" ]; then
    echo "Adding database configuration..."
    sed \
        -e "s/{containers_prefix}/$containers_prefix/g" \
        -e "s/{postgres_password}/$postgres_password/g" \
        -e "s/{postgres_port}/$postgres_port/g" \
        config/database-docker-template.yaml >> $dockercompose_file
fi


# Generate proxy configurations
echo "Generating proxy configurations..."

# Define proxy configuration paths
proxy_template_file="./config/proxy/default.conf.template"
proxy_file="./data/proxy/default.conf.template"

# Create proxy directory
mkdir -p "$(dirname "$proxy_file")"

# Generate proxy configuration
sed \
    -e "s/{explorer_url}/$explorer_url/g" \
    -e "s/{containers_prefix}/$containers_prefix/g" \
    -e "s/{blockscout_port}/$blockscout_port/g" \
    -e "s/{blockscout_http_protocol}/$blockscout_http_protocol/g" \
    -e "s/{stats_service_port}/$stats_service_port/g" \
    -e "s/{visualizer_service_port}/$visualizer_service_port/g" \
    -e "s/{smart_contract_verifier_service_port}/$smart_contract_verifier_service_port/g" \
    $proxy_template_file > $proxy_file

# Generate host proxy configuration
proxy_host_template_file="./config/proxy/host.conf.template"
proxy_host_file="./data/host_proxy/host.conf"

mkdir -p "$(dirname "$proxy_host_file")"

sed \
    -e "s/{explorer_url}/$explorer_url/g" \
    -e "s/{containers_prefix}/$containers_prefix/g" \
    -e "s/{blockscout_port}/$blockscout_port/g" \
    -e "s/{stats_service_port}/$stats_service_port/g" \
    -e "s/{visualizer_service_port}/$visualizer_service_port/g" \
    -e "s/{smart_contract_verifier_service_port}/$smart_contract_verifier_service_port/g" \
    -e "s/{ssl_certificate}/$ssl_certificate/g" \
    -e "s/{ssl_certificate_key}/$ssl_certificate_key/g" \
    $proxy_host_template_file > $proxy_host_file

# Generate sidecar configuration
echo "Generating sidecar configuration..."
sidecar_config_file="./config/sidecar.yaml"
sed \
    -e "s|{supabase_url}|$supabase_url|g" \
    -e "s|{supabase_realtime_url}|$supabase_realtime_url|g" \
    -e "s|{supabase_anon_key}|$supabase_anon_key|g" \
    -e "s|{containers_prefix}|$containers_prefix|g" \
    -e "s|{chain_id}|$chain_id|g" \
    config/sidecar-config-template.yaml > $sidecar_config_file

# Download required files
echo "Downloading required files..."
/bin/bash ./download.sh

echo "Installation completed successfully!"