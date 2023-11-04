#syntax=docker/dockerfile:1.2-labs
FROM postgres:16.0 as builder

# A directory to store the archived WAL files
RUN set -eux && \
    mkdir -p /archiver  && \
    chown -R postgres:postgres /archiver


FROM builder as primary

# Copy the configuration files (PostgreSQL Configuration and Host Based Authentication)
COPY --chown=postgres:postgres [ \
        "postgresql.primary.conf", \
        "pg_hba.primary.conf", \
        "/etc/postgresql/" \
    ]

FROM builder as standby

# A directory for backup from the primary
RUN set -eux && \
    mkdir -p /backup  && \
    chown -R postgres:postgres /backup

# Copy the configuration files
COPY --chown=postgres:postgres [ \
        "postgresql.standby.conf", \
        "/etc/postgresql/" \
    ]
