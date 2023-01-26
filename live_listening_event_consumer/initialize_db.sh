#!/bin/bash

set -e

echo "DB_DATABASE=*${DB_DATABASE}*"
echo "DB_HOST=*${DB_HOST}*"
echo "DB_PORT=*${DB_PORT}*"
echo "DB_USERNAME=*${DB_USERNAME}*"

if [ -z "${DB_DATABASE}" ]
then
  DB_DATABASE=analytics_development
fi

if [ -z "${DB_HOST}" ]
then
  DB_HOST=localhost
fi

if [ -z "${DB_PORT}" ]
then
  DB_PORT=5432
fi

if [ -z "${DB_USERNAME}" ]
then
  DB_USERNAME=postgres
fi

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
