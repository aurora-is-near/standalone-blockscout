#!/bin/sh

docker_pull_policy=""
build_flag=false

for arg in "$@"
do
    case $arg in
        --pull)
        docker_pull_policy="--pull always"
        ;;
        --build)
        build_flag=true
        ;;
    esac
done

./install.sh

# Check if --build flag was passed and run build.sh if true
if [ "$build_flag" = true ]; then
    ./build.sh
fi

# Start Docker Compose with conditional pull policy
docker-compose -f docker-compose.yaml up -d $docker_pull_policy
