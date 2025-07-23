#!/bin/bash

# Default values
ENV_FILE=".env"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env=*)
            ENV_FILE="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: ./remote-restart.sh [--env=filename.env]"
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

echo "Restarting services on $REMOTE_HOST..."

# Create restart script to be executed on remote server
cat << EOF > restart_commands.sh
#!/bin/bash

# Navigate to the deployment directory
cd $REMOTE_DIR

# Check if the directory exists
if [ ! -d "$DEPLOY_DIR" ]; then
    echo "Error: Deployment directory $DEPLOY_DIR not found!"
    exit 1
fi

cd $DEPLOY_DIR


# Restart the services
echo "Restarting Docker Compose services..."
docker compose --project-name $NAMESPACE-blockscout -f docker-compose.yaml down

echo "Services restarted successfully!"

EOF

# Make the restart script executable
chmod +x restart_commands.sh

# Copy restart script to remote server
echo "Copying restart script..."
scp restart_commands.sh "$REMOTE_HOST:/tmp/"

# Execute restart script on remote server
echo "Executing restart commands..."
ssh "$REMOTE_HOST" "bash /tmp/restart_commands.sh"

# Clean up temporary files
echo "Cleaning up..."
rm restart_commands.sh
ssh "$REMOTE_HOST" "rm /tmp/restart_commands.sh"

echo "Restart completed successfully!" 