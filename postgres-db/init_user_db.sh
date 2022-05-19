#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER"<<-EOSQL
	CREATE ROLE covid19_user WITH LOGIN PASSWORD 'covid19_pass';
	CREATE DATABASE covid19;
	GRANT ALL PRIVILEGES ON DATABASE covid19 TO covid19_user;
EOSQL