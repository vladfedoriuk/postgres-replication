# postgres-replication
A repo showcasing different PostgreSQL replication configurations using Docker

## Presentation

https://docs.google.com/presentation/d/1OFtQ6huAPjrbpEu7oIEx9qnzeF8-pCS9Qmbn6YmNHYQ/edit?usp=sharing

## PgAdmin

To run `pgAdmin`, run the following command:

```shell
docker compose -f docker-compose.pgadmin.yaml up
```

In `pgAdmin`, you can add any servers from `streaming` and `logical` compose files.
That is possible because the `pgadmin` container is in the same network as the other containers.

To set up a connection to a server, you need to set the following parameters:

- Host name/address: the name of the service in the compose file (e.g. `streaming-primary`)
- Port: the port of the service in the compose file (e.g. `5432`)
- Username: the username of the service in the compose file (e.g. `postgres`)
- Password: the password of the service in the compose file (e.g. `primary`)
- Maintenance database: the name of the database to connect to (e.g. `postgres`)

To set up `streaming` or `logical` replication, you need to follow the steps in the corresponding `README.md` files.
