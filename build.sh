# !/bin/sh

build_backend=false
build_frontend=false
push_images=false
no_args=true

# Parse command-line arguments
for arg in "$@"
do
    case $arg in
        --backend)
        build_backend=true
        no_args=false
        shift
        ;;
        --frontend)
        build_frontend=true
        no_args=false
        shift
        ;;
        --push)
        push_images=true
        no_args=false
        shift
        ;;
    esac
done

./install.sh
if [ ! -f "docker-compose.yaml" ]; then
  echo "Error: docker-compose.yaml not found. Please check if all ENV variables are correclty set" >&2
  exit 1
fi
if [ "$build_frontend" = true ] || [ "$no_args" = true ]; then
  (
    if [ ! -d "blockscout-frontend" ]; then
      git clone https://github.com/aurora-is-near/blockscout-frontend 
    fi
    cd blockscout-frontend
    git pull origin main
  )
  docker-compose -f docker-compose.yaml build frontend
  if [ "$push_images" = true ]; then
    docker-compose -f docker-compose.yaml push frontend
  fi
fi

if [ "$build_backend" = true ] || [ "$no_args" = true ]; then
  (
    if [ ! -d "blockscout" ]; then
      git clone https://github.com/aurora-is-near/blockscout
    fi
    cd blockscout
    git pull origin master
  )
  docker-compose -f docker-compose.yaml build backend
  if [ "$push_images" = true ]; then
    docker-compose -f docker-compose.yaml push backend
  fi
fi