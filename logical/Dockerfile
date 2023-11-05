#syntax=docker/dockerfile:1.2-labs
FROM postgres:16.0 as builder

FROM builder as primary

# Copy the configuration files (PostgreSQL Configuration and Host Based Authentication)
COPY --chown=postgres:postgres [ \
        "postgresql.logical.conf", \
        "pg_hba.primary.conf", \
        "/etc/postgresql/" \
    ]

FROM builder as standby

# Copy the configuration files (PostgreSQL Configuration)
COPY --chown=postgres:postgres [ \
        "postgresql.logical.conf", \
        "/etc/postgresql/" \
    ]
