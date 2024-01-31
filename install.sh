# !/bin/sh

required_vars="NAME RPC_URL CHAIN_ID SILO_GENESIS"
for var in $required_vars; do
  if [ -z "${!var}" ]; then
    echo "Error: Environment variable $var is not set." >&2
    exit 1
  fi
done

# Initial flag state
build_images=false

# Loop through arguments and process them
for arg in "$@"
do
    case $arg in
        --build)
        build_images=true
        shift # Remove --build from processing
        ;;
        *)
        # Unknown option
        shift # Remove generic argument from processing
        ;;
    esac
done

dockercompose_template_file="./config/docker-compose-template.yaml"
dockercompose_file="docker-compose.yaml"

name=$NAME
rpc_url=$RPC_URL
chain_id=$CHAIN_ID
genesis=$SILO_GENESIS
secret_key_base=$(openssl rand -hex 32)
favicon_generator_api_key=$FAVICON_GENERATOR_API_KEY
wallet_connect_project_id=$NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID

(
  git clone https://github.com/aurora-is-near/blockscout-frontend 
  cd blockscout-frontend
  git pull origin main
)
(
  git clone https://github.com/aurora-is-near/blockscout
  cd blockscout
  git pull origin master
)


cp "${dockercompose_template_file}" "${dockercompose_file}"
sed -i '' "s/{name}/$name/g" $dockercompose_file
sed -i '' "s/{rpc_url}/$rpc_url/g" $dockercompose_file
sed -i '' "s/{chain_id}/$chain_id/g" $dockercompose_file
sed -i '' "s/{genesis}/$genesis/g" $dockercompose_file
sed -i '' "s/{secret_key_base}/$secret_key_base/g" $dockercompose_file
sed -i '' "s/{favicon_generator_api_key}/$favicon_generator_api_key/g" $dockercompose_file
sed -i '' "s/{wallet_connect_project_id}/$wallet_connect_project_id/g" $dockercompose_file


# Check if --build flag was set
if [ "$build_images" = true ]; then
    echo "Building Docker images..."
    docker-compose -f "$dockercompose_file" build
else
    echo "Skipping Docker image build."
fi

docker-compose -f docker-compose.yaml up -d