#!/bin/bash

set -e

echo "DB_DATABASE=*${DB_DATABASE}*"
echo "DB_HOST=*${DB_HOST}*"
echo "DB_PORT=*${DB_PORT}*"
echo "DB_USERNAME=*${DB_USERNAME}*"

docker-compose -f docker-compose.development.yml up db -d

echo "...waiting for db to be up and running"
sleep 2

psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USERNAME} <<-EOSQL
  SELECT 'CREATE DATABASE ${DB_DATABASE}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_DATABASE}')\gexec
EOSQL

psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USERNAME} -d ${DB_DATABASE} <<-EOSQL
  CREATE TABLE IF NOT EXISTS broadcasts (
    id BIGSERIAL PRIMARY KEY,
    broadcast_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
EOSQL
