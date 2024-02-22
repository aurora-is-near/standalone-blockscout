#!/bin/sh

# Check for required environment variables
required_vars="NAME RPC_URL CHAIN_ID GENESIS"
for var in $required_vars; do
  # If any required variable is not set, print an error message and exit
  if [ -z "$(eval echo \$$var)" ]; then
    echo "Error: Environment variable $var is not set." >&2
    exit 1
  fi
done

# Assign environment variables to local variables for easier use
name=$NAME
rpc_url=$RPC_URL
chain_id=$CHAIN_ID
genesis=$GENESIS

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

blockscout_port=$BLOCKSCOUT_PORT
if [ -z "$blockscout_port" ]; then
    # Ensure it is empty
    blockscout_port="80"
fi

stats_service_port=$STATS_SERVICE_PORT
if [ -z "$stats_service_port" ]; then
    # Ensure it is empty
    stats_service_port="8080"
fi

stats_api_host=$STATS_API_HOST
if [ -z "$stats_api_host" ]; then
    stats_api_host="$explorer_url:$stats_service_port"
fi

visualizer_service_port=$VISUALIZER_SERVICE_PORT
if [ -z "$visualizer_service_port" ]; then
    # Ensure it is empty
    visualizer_service_port="8081"
fi

visualizer_api_host=$VISUALIZER_API_HOST
if [ -z "$visualizer_api_host" ]; then
    visualizer_api_host="$explorer_url:$visualizer_service_port"
fi

smart_contract_verifier_service_port=$SMART_CONTRACT_VERIFIER_SERVICE_PORT
if [ -z "$smart_contract_verifier_service_port" ]; then
    smart_contract_verifier_service_port="8050"
fi

verifier_type=$VERIFIER_TYPE
if [ -z "$verifier_type" ]; then
    verifier_type="eth_bytecode_db"
fi


if [ "$verifier_type" = "eth_bytecode_db" ]; then
    verifier_url="https:\/\/eth-bytecode-db.services.blockscout.com\/"
    smart_contract_verifier_restart_policy="no"
    smart_contract_verifier_disabled="command: [\"true\"]"
    smart_contract_verifier_port_mapping=""
else
    verifier_url="http:\/\/smart-contract-verifier:8050\/"
    smart_contract_verifier_restart_policy="always"
    smart_contract_verifier_disabled=""
    smart_contract_verifier_port_mapping="- \"$smart_contract_verifier_service_port:8050\""
fi

containers_prefix=$CONTAINERS_PREFIX
if [ -z "$containers_prefix" ]; then
    # Ensure it is empty
    containers_prefix=""
else 
    [[ "$containers_prefix" != *- ]] && containers_prefix="${containers_prefix}-"
fi

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
    -e "s/{favicon_generator_api_key}/$favicon_generator_api_key/g" \
    -e "s/{wallet_connect_project_id}/$wallet_connect_project_id/g" \
    -e "s/{explorer_url}/$explorer_url/g" \
    -e "s/{blockscout_port}/$blockscout_port/g" \
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
    -e "s/{smart_contract_verifier_port_mapping}/$smart_contract_verifier_port_mapping/g" \
    $dockercompose_template_file > $dockercompose_file

# Define the paths for the proxy configuration template and the actual file
proxy_template_file="./config/proxy/default.conf.template"
proxy_file="./data/proxy/default.conf.template"

# Create the directory for the proxy configuration file if it doesn't exist
mkdir -p "$(dirname "$proxy_file")"

# Replace placeholder in the proxy configuration file with actual value
sed \
    -e "s/{explorer_url}/$explorer_url/g" \
    -e "s/{containers_prefix}/$containers_prefix/g" \
    -e "s/{blockscout_port}/$blockscout_port/g" \
    -e "s/{blockscout_http_protocol}/$blockscout_http_protocol/g" \
    -e "s/{stats_service_port}/$stats_service_port/g" \
    -e "s/{visualizer_service_port}/$visualizer_service_port/g" \
    -e "s/{smart_contract_verifier_service_port}/$smart_contract_verifier_service_port/g" \
    $proxy_template_file > $proxy_file

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