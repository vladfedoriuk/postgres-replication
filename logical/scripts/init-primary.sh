#!/bin/bash

set -euxo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER replicator WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'replicator';
	CREATE TABLE test (id BIGSERIAL PRIMARY KEY NOT NULL, a TEXT NOT NULL, b TEXT NOT NULL);
	GRANT SELECT ON test TO replicator;
	CREATE PUBLICATION test_pub FOR TABLE test(id, b);
EOSQL