#!/bin/bash

# Check if all required parameters are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <source_blockscout_directory> <source_db_url> <target_db_url>"
    echo "Example: $0 ../source-blockscout postgres://user:pass@host:port/db postgres://user:pass@host:port/db"
    exit 1
fi

SOURCE_DIR="$1"
SOURCE_DB_URL="$2"
TARGET_DB_URL="$3"

# Step 1: Copy postgres password
echo "Step 1: Copying postgres password..."
cp "$SOURCE_DIR/.postgres_password" .

# Step 2: Run docker compose services
echo "Step 2: Running docker compose services..."
docker compose up -d db
docker compose run --rm db_ro_user_setup
docker compose run --rm db_sidecar_user_setup

# Wait for database to be ready
echo "Waiting for database to be ready..."
sleep 5

# Step 3: Run pgcopydb
echo "Step 3: Running database migration..."
docker run --rm -it ghcr.io/dimitri/pgcopydb:latest pgcopydb clone --source "$SOURCE_DB_URL" --target "$TARGET_DB_URL"

echo "Migration completed!"