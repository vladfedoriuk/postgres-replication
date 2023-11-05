```postgresql
SHOW hba_file;
SHOW config_file;
```
```shell
docker container top streaming-primary 
docker container top streaming-standby
```
create a standby volume

```shell
docker volume create --name postgres-replication-streaming-standby-pgdata
```
build the `postgres-replication-streaming-standby` image
```shell
docker build -t postgres-replication-streaming-standby . --target standby
```
create a primary
```shell
docker compose --profile primary up
```
do the pg_basebackup from primary to standby volume
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
run the streaming standby
```shell
docker compose --profile standby up
```
## Fail-over
Stop the primary
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
# Cleanup
```shell
docker compose --profile standby --profile primary down --volumes
docker volume rm postgres-replication-streaming-standby-pgdata
```