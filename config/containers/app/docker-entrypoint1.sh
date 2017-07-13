#!/bin/bash

set -e

# 启动 nginx
ln -sf /config/nginx.conf /etc/nginx/conf.d
service nginx start

container_user=container_user

# 添加一个叫做 container_user 的用户, 这个用户的 uid 和运行 docker 的用户的 uid 一致.
getent passwd $container_user || useradd -s /bin/bash -u $LOCAL_USER_ID -o -m $container_user
chown -R $container_user $INSTALL_PATH

# 如果指定了 APP_ROUTE 参数, 则部署时, 重新生成路由.
[ "$APP_ROUTE_FILE" ] &&
    cat <<HEREDOC > $INSTALL_PATH/config/routes.rb
Rails.application.routes.draw do
$(cat $APP_ROUTE_FILE)
end
HEREDOC

if [ "$1" = puma ]; then
    # 下面的代码, 不该在这里执行.
    # 取而代之, 应该在每次部署时, 生成一个新的 container.
    # bundle install 应该在启动 container 之前就完成, 并完成 Dockerfile 层级的更新.
    # bundle install

    # Hack, 先加上 db:create, 稍后做个检测, 避免重复运行.
    bundle exec rake db:create db:migrate # migrate 应该在此时执行.

    if [ "$RAILS_ENV" == production ]; then
        bundle exec rake assets:precompile
        exec gosu $container_user bundle exec puma -C /config/puma_production.rb
    fi
fi

# TODO: 下面这行没用, 应该改为对应的 nginx 检测?
exec "$@"
