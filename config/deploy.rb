set :application, "twatlr"
set :repository,  "git://github.com/gf3/twatlr.com.git"
set :deploy_to,   "/data/www/twatlr.com"
set :scm,         :git
set :user,        :apprunner

role :web, "173.255.226.205"   # Your HTTP server, Apache/etc
role :app, "173.255.226.205"   # This may be the same as your `Web` server

default_run_options[:pty] = true

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{release_path}; git submodule init; git submodule update"
    sudo "god restart twatlr"
  end
end

