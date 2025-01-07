#!/bin/bash

# Default values
ENV_FILE=".env"
branch="master"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env=*)
            ENV_FILE="${1#*=}"
            shift
            ;;
        --branch=*)
            branch="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: ./remote-deploy.sh [--env=filename.env] [--branch=branch_name]"
            exit 1
            ;;
    esac
done

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file $ENV_FILE not found!"
    exit 1
fi

# Load environment variables
echo "Loading environment variables..."
set -a # automatically export all variables
source "$ENV_FILE"
set +a

# Set default branch if not specified in env file or command line
if [ -z "$branch" ]; then
    branch="${BRANCH:-master}"
fi

# Check required environment variables
if [ -z "$REMOTE_HOST" ]; then
    echo "Error: REMOTE_HOST not set in $ENV_FILE"
    exit 1
fi

if [ -z "$REMOTE_DIR" ]; then
    echo "Error: REMOTE_DIR not set in $ENV_FILE"
    exit 1
fi

if [ -z "$NAMESPACE" ]; then
    echo "Error: NAMESPACE not set in $ENV_FILE"
    exit 1
fi

# Set deployment directory name
DEPLOY_DIR="standalone-blockscout-$NAMESPACE"

# Check SSH connection
if ! ssh -q "$REMOTE_HOST" exit; then
    echo "Error: Cannot connect to $REMOTE_HOST"
    exit 1
fi

echo "Deploying to $REMOTE_HOST..."

# Create deployment script to be executed on remote server
cat << EOF > deploy_commands.sh
#!/bin/bash

# Switch to root using doas
doas su - << 'EOSUDO'

# Create directory if it doesn't exist
mkdir -p $REMOTE_DIR

# Clone repository
cd $REMOTE_DIR
if [ -d "$DEPLOY_DIR" ]; then
    echo "Directory exists, pulling latest changes..."
    cd $DEPLOY_DIR
    git fetch origin
    git checkout $branch
    git pull origin $branch
else
    echo "Cloning repository..."
    git clone -b $branch https://github.com/aurora-is-near/standalone-blockscout.git $DEPLOY_DIR
    cd $DEPLOY_DIR
fi

# Make scripts executable
chmod +x *.sh

# Move environment file to correct location
mv /tmp/.env $REMOTE_DIR/$DEPLOY_DIR/.env

# Run installation script
echo "Running installation script..."
cd $REMOTE_DIR/$DEPLOY_DIR && ./install.sh

# Start the services
echo "Starting services..."
docker compose -f docker-compose.yaml up -d --force-recreate

# Exit from root shell
exit
EOSUDO
EOF

# Make the deployment script executable
chmod +x deploy_commands.sh

# Copy deployment script to remote server
echo "Copying deployment script..."
scp deploy_commands.sh "$REMOTE_HOST:/tmp/"

# Copy environment file
echo "Copying environment file..."
scp "$ENV_FILE" "$REMOTE_HOST:/tmp/.env"

# Execute deployment script on remote server
echo "Executing deployment commands..."
ssh "$REMOTE_HOST" "bash /tmp/deploy_commands.sh"

# Clean up temporary files
echo "Cleaning up..."
rm deploy_commands.sh
ssh "$REMOTE_HOST" "rm /tmp/deploy_commands.sh"

echo "Deployment completed successfully!"
