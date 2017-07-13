#
# Postgres 9.5
#

FROM postgres:9.5

MAINTAINER Billy Zheng(zw963) <vil963@gmail.com>

ADD https://zw963.github.io/docker/static_wget /usr/local/sbin/wget
RUN chmod +x /usr/local/sbin/wget

# RUN groupadd -r pgbouncer && useradd -r -g pgbouncer pgbouncer

RUN PGBOUNCER_VERSION=1.7.2 && \
    DOWNLOAD_URL=https://pgbouncer.github.io/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz && \
    apt-get update -y && \
    build_packages='build-essential libc-ares-dev' && \
    apt-get install -qq -y --no-install-recommends $build_packages libevent-dev libssl-dev && \
    wget -q --no-check-certificate -O - $DOWNLOAD_URL |tar zxvf - && \
    cd pgbouncer-${PGBOUNCER_VERSION} && \
    ./configure --prefix=/usr/local --with-libevent=libevent-prefix --enable-evdns=no && \
    make && make install && cd .. && \
    rm -rf pgbouncer-${PGBOUNCER_VERSION} && \
    apt-get purge -y --auto-remove $build_packages && \
    rm -rf /var/lib/apt/lists/*

RUN rm -f /usr/local/sbin/wget

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

COPY config/containers/pg/docker-entrypoint1.sh /

RUN chmod +x /docker-entrypoint1.sh

EXPOSE 6432

ENTRYPOINT ["/docker-entrypoint1.sh"]
# 指定 entrypoint 的同时, 必须指定 CMD, 哪怕上游已经指定过.
CMD ["postgres"]
