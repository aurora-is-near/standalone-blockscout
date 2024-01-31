# !/bin/sh

required_vars="NAME RPC_URL CHAIN_ID SILO_GENESIS"
for var in $required_vars; do
  if [ -z "${!var}" ]; then
    echo "Error: Environment variable $var is not set." >&2
    exit 1
  fi
done

dockercompose_template_file="./config/docker-compose-template.yaml"
dockercompose_file="docker-compose.yaml"

name=$NAME
rpc_url=$RPC_URL
chain_id=$CHAIN_ID
genesis=$SILO_GENESIS

if [ -z "$EXPLORER_URL" ]; then
    explorer_url="explorer.$rpc_url"
else
    explorer_url=$EXPLORER_URL
fi

secret_key_base=$(openssl rand -hex 32)
favicon_generator_api_key=$FAVICON_GENERATOR_API_KEY
wallet_connect_project_id=$NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID

cp "${dockercompose_template_file}" "${dockercompose_file}"

# Replace placeholders in docker-compose file
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