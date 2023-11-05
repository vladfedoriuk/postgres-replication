#!/bin/bash

set -euxo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE TABLE test (id BIGSERIAL PRIMARY KEY NOT NULL, b TEXT NOT NULL);
  CREATE SUBSCRIPTION test_sub
  CONNECTION 'host=logical-primary port=5432 user=replicator password=replicator dbname=postgres'
  PUBLICATION test_pub
  WITH (slot_name='replicator_slot');
EOSQL