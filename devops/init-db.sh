#!/bin/bash
set -e

# Load environment variables from backend/.env
export $(grep -v '^#' /home/ubuntu/app/medium-plan/backend/.env | xargs)

# Wait for PostgreSQL to be ready
until pg_isready -h localhost -U postgres; do
  echo "Waiting for PostgreSQL to start..."
  sleep 2
done

# Create application user and database using environment variables
psql -v ON_ERROR_STOP=1 -U postgres <<-EOSQL
    CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';
    CREATE DATABASE ${DB_NAME} WITH OWNER ${DB_USER};
    GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
    
    \c ${DB_NAME}
    GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};
    ALTER SCHEMA public OWNER TO ${DB_USER};
EOSQL

echo "Database initialization complete using environment variables!"