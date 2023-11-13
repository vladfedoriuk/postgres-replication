# Log-shipping / Streaming replication
In this example, we will set up a primary and a standby using log shipping / streaming replication.

The `primary` and the `standby` will share the same `archiver` volume, which is used
to store the archived WAL files.

What is more, the `stanby` will be connected to the `primary` over TCP
to facilitate the streaming replication.

## Cleanup
```shell
docker compose --profile standby --profile primary down --volumes
docker volume rm postgres-replication-streaming-standby-pgdata
```
## Setup

First, we need to create a volume for the standby `pgdata`:
```shell
docker volume create --name postgres-replication-streaming-standby-pgdata
```
Then, we need to  build the `postgres-replication-streaming-standby` image:
```shell
docker build -t postgres-replication-streaming-standby . --target standby
```
Let's boot up the `primary`.
```shell
docker compose --profile primary up
```
Verify that the primary uses the correct configuration and 
the `hba.conf` file is configured correctly:
```shell
docker exec -it postgres-replication-streaming-primary \
  psql -U postgres -c "SHOW config_file;"
```
Show the pass to the `pg_hba.conf` file:
```shell
docker exec -it postgres-replication-streaming-primary \
  psql -U postgres -c "SHOW hba_file;"
```
```shell
docker exec -it postgres-replication-streaming-primary \
 psql -U postgres -c "SELECT * FROM pg_hba_file_rules;"
```
In order to be able to set up a hot standby, we need create a base backup of the primary.
To do that, we need to run the `pg_basebackup` command from the standby container.
The base backup will be stored in the `/backup` directory of the standby container.
This directory is mapped to the `postgres-replication-streaming-standby-pgdata` volume, which
in turn is mounted to the `pgdata` directory of the standby container (later in the `docker-compose` file).
```shell
docker run \
  --rm \
  -it \
  -v postgres-replication-streaming-standby-pgdata:/backup \
  --network postgres-replication-network \
    postgres-replication-streaming-standby \
        pg_basebackup \
          --pgdata=/backup \
          --write-recovery-conf \
          --wal-method=stream \
          --checkpoint=fast \
          --slot=replicator_slot \
          --verbose \
          --host=streaming-primary \
          --port=5432 \
          --username=replicator \
          --password
```
Let's boot up the hot standby configured to support streaming replication.
```shell
docker compose --profile standby up
```
Let's verify that the `walsender` process is running on the primary
and the `walreceiver` process is running on the standby.
```shell
docker container top postgres-replication-streaming-primary
```
```shell
docker container top postgres-replication-streaming-standby
```
Check that the `standby` is in recovery mode:
```shell
docker exec -it postgres-replication-streaming-standby \
  psql -U postgres -c "SELECT pg_is_in_recovery();"
```
And that the `primary` is not:
```shell
docker exec -it postgres-replication-streaming-primary \
  psql -U postgres -c "SELECT pg_is_in_recovery();"
```
Check that the `standby` is connected to the `primary`:
```shell
docker exec -it postgres-replication-streaming-standby \
  psql -U postgres -c "SELECT * FROM pg_stat_wal_receiver;"
```
Check that the `primary` is connected to the `standby`:
```shell
docker exec -it postgres-replication-streaming-primary \
  psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```

## Testing
Let's create a test table on the primary:
```shell
docker exec -it postgres-replication-streaming-primary \
  psql -U postgres -c "CREATE TABLE test_table (id INT, name TEXT);"
```
See that the table is there in the standby:
```shell
docker exec -it postgres-replication-streaming-standby \
  psql -U postgres -c "SELECT * FROM test_table;"
```
Let's insert some data into the table on the `primary`:
```shell
docker exec -it postgres-replication-streaming-primary \
  psql -U postgres -c "INSERT INTO test_table VALUES (1, 'test');"
```
See that the data is there in the `standby`:
```shell
docker exec -it postgres-replication-streaming-standby \
  psql -U postgres -c "SELECT * FROM test_table;"
```
Let's ensure that the `standby` is not accepting writes:
```shell
docker exec -it postgres-replication-streaming-standby \
  psql -U postgres -c "INSERT INTO test_table VALUES (2, 'test');"
```
See that the data is not there in the `standby`:
```shell
docker exec -it postgres-replication-streaming-standby \
  psql -U postgres -c "SELECT * FROM test_table;"
```

## Fail-over
Let's simulate a fail-over by shutting down the primary.
```shell
docker compose --profile primary down
```
Promote the standby (exec as `postgres` user)
```shell
docker exec -it postgres-replication-streaming-standby \
  psql -U postgres -c "SELECT pg_promote();"
```
Check that the standby is now the primary
```shell
docker exec -it postgres-replication-streaming-standby \
  psql -U postgres -c "SELECT pg_is_in_recovery();"
```
Issue a `write` command to the new primary to verify that it is working.
```shell
docker exec -it postgres-replication-streaming-standby \
  psql -U postgres -c "INSERT INTO test_table VALUES (2, 'test fail-over');"
```
Check that the data is there:
```shell
docker exec -it postgres-replication-streaming-standby \
  psql -U postgres -c "SELECT * FROM test_table;"
```
#3 Cleanup
```shell
docker compose --profile standby --profile primary down --volumes
docker volume rm postgres-replication-streaming-standby-pgdata
```