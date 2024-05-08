#!/bin/sh

backend_version=""
frontend_version=""
push_images=false

# Parse command-line arguments
for arg in "$@"
do
    case $arg in
        --backend=*)
        backend_version="${arg#*=}"
        shift
        ;;
        --frontend=*)
        frontend_version="${arg#*=}"
        shift
        ;;
        --push)
        push_images=true
        shift
        ;;
    esac
done

if [ -n "$backend_version" ]; then
(
  if [ ! -d "blockscout" ]; then
    git clone https://github.com/aurora-is-near/blockscout
  fi
  cd blockscout
  git pull origin master
  docker build --file docker/Dockerfile --build-arg=RELEASE_VERSION=$backend_version --tag "aurora-is-near/blockscout:$backend_version" .
  if [ "$push_images" = true ]; then
    docker push aurora-is-near/blockscout:$backend_version 
  fi
)
fi

if [ -n "$frontend_version" ]; then
(
  if [ ! -d "blockscout-frontend" ]; then
    git clone https://github.com/aurora-is-near/blockscout-frontend 
  fi
  cd blockscout-frontend
  git pull origin main
  docker build --file Dockerfile --tag "aurora-is-near/blockscout-frontend:$frontend_version" .
    if [ "$push_images" = true ]; then
      docker push aurora-is-near/blockscout-frontend:$frontend_version
    fi
)
fi