#!/bin/bash
# SPADE Cloud - Database Initialization Script
# This script initializes database users and grants privileges

# Exit on error
set -e

# Load environment variables from .env file
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please copy .env.example to .env and configure it first."
    exit 1
fi

source .env

# Catalogue Database Setup
echo "Setting up Catalogue database..."
database=$CATALOGUE_DB_NAME
username=$CATALOGUE_DB_USER
password=$CATALOGUE_DB_PASSWORD
admin=$CATALOGUE_DB_USER

docker compose exec catalogue_db psql -U ${admin} -d ${database} -c "GRANT ALL ON SCHEMA public TO ${username};"
echo "✓ Catalogue database setup complete"

# Keycloak Database Setup
echo "Setting up Keycloak database..."
database=$KEYCLOAK_DB_NAME
username=$KEYCLOAK_DB_USER
password=$KEYCLOAK_DB_PASSWORD
admin=$KEYCLOAK_DB_USER

docker compose exec keycloak_db psql -U ${admin} -d ${database} -c "GRANT ALL ON SCHEMA public TO ${username};"
echo "✓ Keycloak database setup complete"

echo ""
echo "All databases initialized successfully!"
