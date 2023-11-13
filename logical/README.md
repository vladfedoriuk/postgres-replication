# Logical Replication
## Setup
First, we need spin up the `primary` and `standby` containers:
```shell
docker compose up
```
Verify that the primary uses the correct configuration and
the `postgresql.conf` file is configured correctly:
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "SHOW config_file;"
```
Show the pass to the `pg_hba.conf` file:
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "SHOW hba_file;"
```
```shell
docker exec -it postgres-replication-logical-primary \
 psql -U postgres -c "SELECT * FROM pg_hba_file_rules;"
```
See that the replication slot is created:
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "SELECT * FROM pg_replication_slots;"
```
See that the `walsender` process is running:
```shell
docker container top postgres-replication-logical-primary
```
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```
See that the `apply` process is running on the `standby`:
```shell
docker container top postgres-replication-logical-standby
```
See if the `standby` is in recovery mode:
```shell
docker exec -it postgres-replication-logical-standby \
  psql -U postgres -c "SELECT pg_is_in_recovery();"
```
As expected, the `standby` is not in recovery mode - it can accept writes.
See that the `standby` is connected to the `primary` (ths subscription is active):
```shell
docker exec -it postgres-replication-logical-standby \
  psql -U postgres -c "SELECT * FROM pg_stat_subscription;"
```
See that the publication is created on the `primary` and is working:
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "SELECT * FROM pg_publication;"
```

## Test

Let's insert some data into the `primary`:
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "INSERT INTO test (id, a, b) VALUES (1, 'a', 'b');"
```
See that the data is there in the `primary`:
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "SELECT * FROM test;"
```
See that the data is there in the `standby`:
```shell
docker exec -it postgres-replication-logical-standby \
  psql -U postgres -c "SELECT * FROM test;"
```

Lets `alter` the publication to only publish `b` values which are equal to `b`:
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "ALTER PUBLICATION test_pub SET TABLE test(id, b) WHERE (b = 'b');"
```
See that the data is there in the `primary`:
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "SELECT * FROM test;"
```
Let's insert some data into the `primary`:
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "INSERT INTO test (id, a, b) VALUES (2, 'a', 'c');"
```
See that the data is there in the `primary`:
```shell
docker exec -it postgres-replication-logical-primary \
  psql -U postgres -c "SELECT * FROM test;"
```
See that the data is not there in the `standby`:
```shell
docker exec -it postgres-replication-logical-standby \
  psql -U postgres -c "SELECT * FROM test;"
```

# Cleanup
```shell
docker compose down --volumes
```