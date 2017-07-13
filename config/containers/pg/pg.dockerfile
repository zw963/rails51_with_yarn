#
# Postgres 9.5
#

FROM postgres:9.5

# zhparser + scws
COPY config/containers/pg/ext/zhparser/zhparser.so /usr/lib/postgresql/9.5/lib/
COPY config/containers/pg/ext/zhparser/scws /scws/
COPY config/containers/pg/ext/zhparser/data/ /usr/share/postgresql/9.5/

# redis_fdw
COPY config/containers/pg/ext/redis_fdw/redis_fdw.so /usr/lib/postgresql/9.5/lib/
COPY config/containers/pg/ext/redis_fdw/lib/libhiredis.so.0.10 /usr/lib/x86_64-linux-gnu/
COPY config/containers/pg/ext/redis_fdw/data/ /usr/share/postgresql/9.5/

# update pg config only once
COPY config/containers/pg/process/update_pgconfig.sh /docker-entrypoint-initdb.d
