require 'mina/rails'
require 'mina/git'
require 'mina/unicorn'
# require 'mina/rbenv'  # for rbenv support. (https://rbenv.org)
# require 'mina/rvm'    # for rvm support. (https://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

# set :domain, '52.74.154.122'
#     # 188.166.211.65
# set :branch, 'staging'
    
    
set :application_name, 'p2p_app'
set :domain, '159.65.136.83'
set :deploy_to, '/var/www/p2p_app'
set :repository, 'https://github.com/weyewe/rails-app-deploy.git'
set :branch, 'staging'




set :user , 'corgi_deployer'
set :unicorn_pid, "#{fetch(:deploy_to)}/shared/pids/unicorn.pid"
set :rvm_path, '/home/corgi_deployer/.rvm/bin/rvm'

# Optional settings:
#   set :user, 'foobar'          # Username in the server to SSH to.
#   set :port, '30000'           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
# set :shared_dirs, fetch(:shared_dirs, []).push('public/assets')
# set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')


# set :shared_paths, ['config/database.yml',
#   'config/scout_apm.yml',
# 'config/application.yml','log',
#   'config/secrets.yml',
#   'config/initializers/app_secrets.rb',
#   'config/uploadcare.yml']
  
set :shared_dirs, fetch(:shared_dirs, []).push('log')
  
set :shared_files, fetch(:shared_files, []).push(
  'config/database.yml',
  'config/scout_apm.yml',
  'config/application.yml', 
  'config/secrets.yml',
  'config/initializers/app_secrets.rb',
  'config/uploadcare.yml' 
  )
  
  

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use', 'ruby-1.9.3-p125@default'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  # command %{rbenv install 2.3.0 --skip-existing}

  command %[mkdir -p "#{fetch(:deploy_to)}/shared/sockets"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/sockets"]

  command %[mkdir -p "#{fetch(:deploy_to)}/shared/log"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/log"]

  command %[mkdir -p "#{fetch(:deploy_to)}/shared/config"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/config"]

  command %[mkdir -p "#{fetch(:deploy_to)}/shared/config/initializers"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/config/initializers"]

  command %[touch "#{fetch(:deploy_to)}/shared/config/database.yml"]
  command  %[echo "-----> Be sure to edit 'shared/config/database.yml'."]

  command %[touch "#{fetch(:deploy_to)}/shared/config/uploadcare.yml"]
  command  %[echo "-----> Be sure to edit 'shared/config/uploadcare.yml'."]

  command %[touch "#{fetch(:deploy_to)}/shared/config/secrets.yml"]
  command %[echo "-----> Be sure to edit 'shared/config/secrets.yml'."]
  command %[touch "#{fetch(:deploy_to)}/shared/config/application.yml"]
  command %[echo "-----> Be sure to edit for FIGARO 'shared/config/application.yml'."]

  command %[touch "#{fetch(:deploy_to)}/shared/config/scout_apm.yml"]
  command %[echo "-----> Be sure to edit FOR FIGARO 'shared/config/scout_apm.yml'."]

  command %[touch "#{fetch(:deploy_to)}/shared/config/initializers/app_secrets.rb"]
  command %[echo "-----> Be sure to edit 'shared/config/initializers/app_secrets.rb'."]

  # sidekiq needs a place to store its pid file and log file
  command %[mkdir -p "#{fetch(:deploy_to)}/shared/pids/"]
  command %[chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/pids"]
end

desc "Deploys the current version to the server."
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  # invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      in_path(fetch(:current_path)) do
        invoke :'unicorn:restart'
        # invoke :unicorn:restart 
        # command %{mkdir -p tmp/}
        # command %{touch tmp/restart.txt}
      end
    end
  end

  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run(:local){ say 'done' }
end

# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/tree/master/docs
