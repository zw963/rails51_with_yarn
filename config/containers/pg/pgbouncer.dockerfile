#
# pg_bouncer 1.7.2 (2017/03/08)
#

FROM debian:jessie

MAINTAINER Billy Zheng(zw963) <vil963@gmail.com>

RUN groupadd -r pgbouncer && useradd -r -g pgbouncer pgbouncer

ADD https://zw963.github.io/docker/static_wget /usr/local/sbin/wget

RUN chmod +x /usr/local/sbin/wget

RUN PGBOUNCER_VERSION=1.7.2 && \
    DOWNLOAD_URL=https://pgbouncer.github.io/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz && \
    chmod +x /usr/local/sbin/wget && \
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

EXPOSE 6432

COPY docker-entrypoint.sh /

VOLUME /pgbouncer

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["pgbouncer"]
