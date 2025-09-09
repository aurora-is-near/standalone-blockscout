#!/bin/sh
set -e

until psql "$DATABASE_URL" -c "SELECT 1;"; do
  echo "Waiting for database to be ready..."
  sleep 5
done

echo "Creating sidecar user and database..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 << EOF
DO \$\$
BEGIN
  -- Create sidecar database if it doesn't exist
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'blockscout-sidecar') THEN
    CREATE DATABASE "blockscout-sidecar";
  END IF;
  -- Create sidecar user if it doesn't exist
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'blockscout-sidecar') THEN
    CREATE USER "blockscout-sidecar" WITH PASSWORD '${SIDECAR_AUTH_PASSWORD}';
  END IF;
  -- Grant privileges to sidecar user
  GRANT CONNECT ON DATABASE "blockscout-sidecar" TO "blockscout-sidecar";
  GRANT CREATE ON DATABASE "blockscout-sidecar" TO "blockscout-sidecar";
  GRANT USAGE ON SCHEMA public TO "blockscout-sidecar";
  GRANT CREATE ON SCHEMA public TO "blockscout-sidecar";
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "blockscout-sidecar";
  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "blockscout-sidecar";
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "blockscout-sidecar";
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "blockscout-sidecar";
END;
\$\$;
EOF

exit 0
