```sql
SHOW hba_file;
SHOW config_file;
```
```shell
docker container top streaming-primary 
docker container top streaming-standby
```

create a standby volume
```shell
docker volume create --name streaming-standby-pgdata
```
build the `streaming-standby` image
```shell
docker build -t streaming-standby . --target standby
```
do the pd_basebackup from primary to standby volume
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
  --health-cmd "pg_isready -U postgres || exit 1" \
    --health-interval 10s \
    --health-retries 5 \
    --health-timeout 5s \
    --health-start-period 10s \
    streaming-standby \
      -c "config_file=/etc/postgresql/postgresql.standby.conf"
```
