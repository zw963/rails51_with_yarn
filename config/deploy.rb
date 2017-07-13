set :application, 'rails51_with_yarn'
# 本地 git 示例: ssh://git@example.com:30000/~/me/my_repo.git
# svn 示例: svn://myhost/myrepo/#{fetch(:branch)}
set :repo_url, ''
set :rails_env, -> { fetch(:stage) }
set :rvm_ruby_version, "ruby-2.3.4@#{fetch(:application)}"
set :keep_releases, 5
set :local_user, -> { Etc.getlogin }
set :conditionally_migrate, true

set :pid_dir, -> { "#{fetch(:deploy_to)}/shared/tmp/pids" }
set :config_dir, -> { "#{fetch(:deploy_to)}/current/config" }
set :containers_dir, -> { "#{fetch(:config_dir)}/containers" }
set :puma_pid, -> { "#{fetch(:pid_dir)}/puma.app.rails51_with_yarn.pid" }
set :puma_config, -> { "#{fetch(:containers_dir)}/app/config/puma_production.rb" }
set :cable_pid, -> { "#{fetch(:pid_dir)}/cable.pid" }
set :cable_config, -> { "#{fetch(:config_dir)}/cable.rb" }
set :sidekiq_pid, -> { "#{fetch(:pid_dir)}/sidekiq.pid" }

set :linked_files, %w{
  config/bashrc
}
set :linked_dirs, %w{
  log
  tmp
  public/assets
  public/uploads
}

# vendor/bundle
# public/system
# public/uploads

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :rvm_custom_path, '~/.myveryownrvm'
# lock '3.7.0'
