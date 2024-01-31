#!/bin/sh

# Flag for Docker pull policy
docker_pull_policy=""

# Check for --pull argument
for arg in "$@"
do
    if [ "$arg" = "--pull" ]; then
        docker_pull_policy="--pull always"
    fi
done

./install.sh

# Start Docker Compose with conditional pull policy
docker-compose -f docker-compose.yaml up -d $docker_pull_policy
