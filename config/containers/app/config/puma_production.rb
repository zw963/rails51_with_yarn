# -*- coding: utf-8; mode:ruby; -*-

file = 'puma.app.rails51_with_yarn'
# port = ENV.fetch('DEFAULT_PORT', 3000)

environment ENV.fetch('RAILS_ENV', 'production')

FileUtils.mkdir_p('tmp/pids')
pidfile "tmp/pids/#{file}.pid"
state_path "tmp/pids/#{file}.state"

unless ENV['RAILS_LOG_TO_STDOUT'] == 'true'
  stdout_redirect "log/#{file}.access.log", "log/#{file}.err.log"
  daemonize
end
# bind "tcp://0.0.0.0:#{port}"

# socket 文件放到 tmp 目录下, 避免 socket 在系统 /tmp 目录下某些 linux 系统下可能存在的问题.
dir = File.realpath(File.expand_path('../../../../../tmp', __FILE__))
bind "unix://#{dir}/#{file}.sock"

require 'etc'; workers ENV.fetch('WEB_CONCURRENCY', Etc.nprocessors).to_i

threads 0, ENV.fetch('RAILS_MAX_THREADS', 16).to_i

plugin :tmp_restart

# Following is need for preload_app config. (not worked with phased start)
# preload_app!
# on_worker_boot do
#   puts 'On worker boot...'
#   ActiveRecord::Base.establish_connection
# end
# before_fork do
#   puts 'before fork...'
#   ActiveRecord::Base.connection_pool.disconnect!
# end

# Following is need for phased restart.
prune_bundler
if ENV['APP_FULL_PATH'].nil?
  fail 'Need specify APP_FULL_PATH'
else
  directory ENV['APP_FULL_PATH']
end
