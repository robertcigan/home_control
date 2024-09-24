# config valid only for current version of Capistrano
lock "3.17.1"

set :application, "home_control"
set :repo_url, "git@github.com:robertcigan/home_control.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
#set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/database.yml", "config/env.yml"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "public/uploads"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :ssh_options, { forward_agent: true, verify_host_key: :always }

append :linked_dirs, '.bundle'

# If the environment differs from the stage name
#set :rails_env, 'staging'

# Defaults to :db role
set :migration_role, :app

# Defaults to the primary :db server
set :migration_servers, -> { primary(fetch(:migration_role)) }

# Defaults to false
# Skip migration if files in db/migrate were not modified
set :conditionally_migrate, true

# Defaults to [:web]
set :assets_roles, [:web, :app]

# Defaults to 'assets'
# This should match config.assets.prefix in your rails config/application.rb
set :assets_prefix, 'assets'

# If you need to touch public/images, public/javascripts, and public/stylesheets on each deploy
set :normalize_asset_timestamps, %w{public/images public/javascripts public/stylesheets}

# Defaults to nil (no asset cleanup is performed)
# If you use Rails 4+ and you'd like to clean up old assets after each deploy,
# set this to the number of versions to keep
set :keep_assets, 2

set :puma_init_active_record, true
set :puma_preload_app, true
set :puma_service_unit_name, "puma_home_control"
set :arduino_service_unit_name, "arduino_home_control"

# Master key

append :linked_files, "config/master.key"
namespace :deploy do
  namespace :check do
    before :linked_files, :set_master_key do
      on roles(:app), in: :sequence, wait: 10 do
        unless test("[ -f #{shared_path}/config/master.key ]")
          upload! 'config/master.key', "#{shared_path}/config/master.key"
        end
      end
    end
  end
end

# Automatically create env.yml file based on example file

append :linked_files, "config/env.yml"
namespace :deploy do
  namespace :check do
    before :linked_files do
      on roles(:app), in: :sequence, wait: 10 do
        unless test("[ -f #{shared_path}/config/env.yml ]")
          upload! 'config/env.example.yml', "#{shared_path}/config/env.yml"
        end
      end
    end
  end
end

namespace :nginx do
  desc "Restart nginx"
  task :restart do
    on roles(:app) do
      sudo "systemctl restart nginx"
    end
  end
end

namespace :deploy do
  before 'check:linked_files', 'puma:config'
  before 'check:linked_files', 'puma:nginx_config'
  after 'puma:restart', 'nginx:restart'
end

before 'deploy:migrate', 'setup:create_database'

namespace :setup do
  desc "Create database.yml file."
  task :database_yml do
    on roles(:app) do
      ask(:database_password, 'default_password', echo: false)
      db_config = <<-EOF
base: &base
  adapter: mysql2
  encoding: utf8
  reconnect: false
  pool: 10
  username: "pi"
  password: #{fetch(:database_password)}
development:
  database: #{fetch(:application)}
  <<: *base
production:
  database: #{fetch(:application)}
  <<: *base
EOF
      data = StringIO.new(db_config)
      execute "mkdir -p #{shared_path}/config"
      upload! data, "#{shared_path}/config/database.yml"
    end
  end

  desc "Create the env.file"
  task :env_yml do
    on roles(:app) do
      with rails_env: :production do
        execute "mkdir -p #{shared_path}/config"
        if File.exists?("config/env.production.yml")
          upload! "config/env.production.yml", "#{shared_path}/config/env.yml"
        else
          upload! "config/env.example.yml", "#{shared_path}/config/env.yml"
        end
      end
    end
  end

  desc 'Runs rake db:create'
  task :create_database do
    on roles(:app) do
      within release_path do
        with rails_env: :production do
          execute :rake, 'db:create'
        end
      end
    end
  end

  desc 'Runs rake db:seed'
  task :seed do
    on roles(:app) do
      within release_path do
        with rails_env: :production do
          execute :rake, 'db:seed'
        end
      end
    end
  end

  desc 'Setup ruby & ruby gemset'
  task :rvm do
    on roles :web do
      execute :rvm, :install, fetch(:ruby_version)
      execute :rvm, :gemset, :create, fetch(:application)
      execute :rvm, fetch(:rvm_ruby_version), :do, "gem install bundler"
    end
  end
end