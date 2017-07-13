#
# Ruby 2.3-slim
#

FROM ruby:2.3-slim

MAINTAINER Billy Zheng(zw963) <vil963@gmail.com>

RUN sed -i 's#deb.debian.org/debian#mirrors.aliyun.com/debian#g' /etc/apt/sources.list

RUN bash -c 'function __wget() { \
    local URL=$1; \
    read proto server path <<<$(echo ${URL//// }); \
    local SCHEME=${proto//:*} PATH=/${path// //} HOST=${server//:*} PORT=${server//*:}; \
    [[ "${HOST}" == "${PORT}" ]] && PORT=80; \
    exec 3<>/dev/tcp/${HOST}/${PORT}; \
    echo -en "GET ${PATH} HTTP/1.1\r\nHost: ${HOST}\r\nConnection: close\r\n\r\n" >&3; \
    local state=0 line_number=0; \
    while read line; do \
        line_number=$(($line_number + 1)); \
        case $state in \
            0) \
                echo "$line" >&2; \
                if [ $line_number -eq 1 ]; then \
                    if [[ $line =~ ^HTTP/1\.[01][[:space:]]([0-9]{3}).*$ ]]; then \
                        [[ "${BASH_REMATCH[1]}" = "200" ]] && state=1 || return 1; \
                    else \
                        printf "invalid http response from '%s'" "$URL" >&2; \
                        return 1; \
                    fi; \
                fi; \
                ;; \
            1) \
                [[ "$line" =~ ^.$ ]] && state=2; \
                ;; \
            2) \
                echo "$line"; \
        esac \
    done <&3; \
    exec 3>&-; \
}; \

__wget http://202.56.13.13/base64_encoded_static_wget |base64 -d > /usr/local/bin/wget; \

if [ -s /usr/local/bin/wget ]; then \
    chmod +x /usr/local/bin/wget; \
else \
    echo "Network is not connected?" >&2; \
    exit 1; \
fi;'

# GOSU 配置, 这个不常改.
RUN GOSU_VERSION=1.10 && \
        arch=$(dpkg --print-architecture) && \
         wget --quiet -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$arch" && \
         wget --quiet -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$arch.asc" && \
         export GNUPGHOME="$(mktemp -d)" && \
         gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
         gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
         rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc && \
         chmod +x /usr/local/bin/gosu && \
         gosu nobody true

# nginx 配置, 这个应该也是不需要经常修改.
RUN debian_codename=$(cat /etc/os-release |grep VERSION= |grep -o '[a-z]*') && \
        echo "deb http://nginx.org/packages/debian/ $debian_codename nginx\ndeb-src http://nginx.org/packages/debian/ $debian_codename nginx" >> /etc/apt/sources.list && \
        wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add - && \
        apt-get update && apt-get install -qq -y --no-install-recommends nginx && rm -rf /var/lib/apt/lists/* && \
        rm /etc/nginx/conf.d/default.conf

# 注意: 这个变量也被 puma 直接使用, 用来支持热部署.
ENV APP_FULL_PATH=/my_dockerized_app
RUN mkdir -p $APP_FULL_PATH
WORKDIR $APP_FULL_PATH

COPY Gemfile Gemfile.lock ./

# # 更新到比 app 要新一些版本的 bunder.
# RUN gem install bundler

# 备注:
# nio4r 需要安装 make gcc, 安装后全部可移除.
# pg 需要安装 make gcc libpq5 libpq-dev, 安装后, libpq-dev 可移除.
# nokogiri 需要 make gcc patch git, 安装后, 全部可移除.
# therubyracer 需要 make gcc g++, 安装后全部可移除.

# 全部需安装依赖: make gcc g++ patch git libpq5 libpq-dev,  其中 libpq-dev 可移除.

RUN debian_codename=$(cat /etc/os-release |grep VERSION= |grep -o '[a-z]*') && \
        build_packages='make gcc g++ patch git libpq-dev' && \
        runtime_packages='libpq5' && \
        echo "deb http://apt.postgresql.org/pub/repos/apt/ ${debian_codename}-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc |apt-key add - && \
        apt-get update && \
        apt-get install -qq -y --no-install-recommends $build_packages $runtime_packages && \
        rm -rf /var/lib/apt/lists/* && \
        bundle install --binstubs --retry=5 && \
        apt-get purge -y --auto-remove $build_packages

# RUN rm /usr/local/sbin/wget
RUN apt-get purge -y --auto-remove wget

# 这些运行 bundle install 必须的一些环境变量, 除了 INSTALL_PATH 固定不变之外,
# 其他变量在运行 container 时, 会被环境变量替换掉, 因此无需修改.
ENV RAILS_ENV=production \
    SECRET_KEY_BASE=abfff8b198c1807874360eef134e683ca7749910db597e29d144bc540de6fb9992743d3bf059dc4a409d7b8849f163ef53abdf14daadf6edbcd303354ac61e24 \
    DATABASE_URL=postgresql://postgres:password@my-pg-server-name/my_dbname_production

COPY . .

VOLUME ["$INSTALL_PATH/public"]

COPY config/containers/app/docker-entrypoint1.sh /
RUN chmod +x /docker-entrypoint1.sh

EXPOSE 80

# 这些环境变量是 container 启动阶段必须的环境变量, 可能常常新增或删除.
# 大部分环境变量在运行时会被改写，在这里只是作为一个 place holder,
# 确保之后可以被修改.
ENV RAILS_LOG_TO_STDOUT=true \
    APP_ROUTE_FILE= \
    DEFAULT_PORT=3000 \
    HTTP_HOST= \
    CACHE_STORE_REDIS_URL=redis://127.0.0.1:6379/0 \
    SIDEKIQ_REDIS_URL=redis://127.0.0.1:6380/0 \
    ACTION_CABLE_REDIS_URL=redis://127.0.0.1:6380/1

# 和 docker build --build-arg="ASSET_HOST=http://mycdn/path-to-assets" . 一起工作.

ENTRYPOINT ["/docker-entrypoint1.sh"]

CMD ["puma"]
