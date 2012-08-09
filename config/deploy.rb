require "bundler/capistrano"

set :application, "Busme"
set :repository,  "https://github.com/polar/buspass-admin.git"

set :use_sudo, false

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

host = "bitnami@192.168.1.111"

role :web, host                          # Your HTTP server, Apache/etc
role :app, host                          # This may be the same as your `Web` server
role :db,  host, :primary => true # This is where Rails migrations will run

set :deploy_to, "~/Busme"

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "touch #{File.join(current_path,'tmp','restart.txt')}"
   end
end

set :rvm_ruby_string, 'ruby-1.9.3-p125@rails3.2'

namespace :deploy do
  namespace :assets do
    task :precompile, :roles => :web, :except => { :no_release => true } do
      from = source.next_revision(current_revision)
      if capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ app/assets/ | wc -l").to_i > 0
        run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile}
      else
        logger.info "Skipping asset pre-compilation because there were no asset changes"
      end
    end
  end
end