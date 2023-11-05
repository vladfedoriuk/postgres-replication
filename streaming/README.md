```postgresql
SHOW hba_file;
SHOW config_file;
```
```shell
docker container top streaming-primary 
docker container top streaming-standby
```
create a primary
```shell
docker compose up
```
create a standby volume
```shell
docker volume create --name streaming-standby-pgdata
```
build the `streaming-standby` image
```shell
docker build -t streaming-standby . --target standby
```
do the pg_basebackup from primary to standby volume
```shell
docker run \
  --rm \
  -it \
  -v streaming-standby-pgdata:/backup \
  --network postgres-streaming-network \
    streaming-standby \
        pg_basebackup \
          --pgdata=/backup \
          --write-recovery-conf \
          --wal-method=stream \
          --checkpoint=fast \
          --slot=replicator_slot \
          --verbose \
          --host=primary \
          --port=5432 \
          --username=replicator \
          --password
```
run the streaming standby
```shell
docker run \
  --hostname standby \
  --network postgres-streaming-network \
  --name streaming-standby \
  -v streaming-standby-pgdata:/var/lib/postgresql/data \
  -v streaming-postgres-archiver:/archiver \
  --health-cmd "pg_isready -U postgres || exit 1" \
    --health-interval 10s \
    --health-retries 5 \
    --health-timeout 5s \
    --health-start-period 10s \
    streaming-standby \
      -c "config_file=/etc/postgresql/postgresql.standby.conf"
```
## Fail-over
Stop the primary
```shell
docker container stop streaming-primary
```
Promote the standby (exec as `postgres` user)
```shell
docker exec -it streaming-standby \
  psql -U postgres -c "SELECT pg_promote();"
```
Check that the standby is now the primary
```shell
docker exec -it streaming-standby \
  psql -U postgres -c "SELECT pg_is_in_recovery();"
```
# Cleanup
```shell
docker compose down -v --remove-orphans
docker container stop streaming-primary streaming-standby
docker container rm streaming-primary streaming-standby
docker network rm postgres-streaming-network
docker volume rm streaming-standby-pgdata
```