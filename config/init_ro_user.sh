#!/bin/sh
set -e

until psql "$DATABASE_URL" -c "SELECT 1;"; do
  echo "Waiting for database to be ready..."
  sleep 5
done

echo "Creating readonly user..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 << EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'blockscout_ro') THEN
    CREATE USER blockscout_ro WITH PASSWORD '${POSTGRES_RO_PASSWORD}';
    GRANT CONNECT ON DATABASE ${DATABASE_NAME} TO blockscout_ro;
    GRANT USAGE ON SCHEMA public TO blockscout_ro;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO blockscout_ro;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO blockscout_ro;
  END IF;
END;
\$\$;
EOF

exit 0