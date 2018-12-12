#!/usr/bin/env bash

set -e

idmod postgres "$USER_UID" "$USER_GID" || true
chown -R  postgres:postgres /var/lib/postgresql
chown -R  postgres:postgres /var/log/postgresql
chmod -R +r /etc/postgresql
chmod -R +r /etc/postgresql-common

if [ ! -s "$PGDATA/PG_VERSION" ]; then

    gosu postgres initdb --username=postgres

    gosu postgres pg_ctl --options="-c listen_addresses='localhost'" --wait start

    if [ "$PGDATABASE" != "postgres" ]; then
        gosu postgres psql \
            --dbname=postgres \
            --username=postgres \
            --command="CREATE DATABASE $PGDATABASE";
    fi

    op="CREATE"
    if [ "$PGUSER" = "postgres" ]; then
        op="ALTER"
    fi
     gosu postgres psql \
        --dbname=postgres \
        --username=postgres \
        --command="$op USER $PGUSER WITH SUPERUSER PASSWORD '$PGPASSWORD'"

    for file in /docker-entrypoint-initdb.d/*; do
        case "$file" in
            *.sh) . "$file" ;;
			*.sql) gosu postgres psql --file="$file" ;;
            *.sql.gz) gunzip --stdout "$file" | gosu postgres psql ;;
        esac
    done

     gosu postgres pg_ctl --mode=fast --wait stop
fi

if [ $# -ne 0 ]; then
    exec tini -- gosu postgres "$@"
fi
