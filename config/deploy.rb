set :application, "twatlr"
set :repository,  "git://github.com/gf3/twatlr.com.git"
set :deploy_to,   "/data/www/twatlr.com"
set :scm,         :git
set :user,        :apprunner

set :use_sudo,    false

role :web, "173.255.226.20"   # Your HTTP server, Apache/etc
role :app, "173.255.226.20"   # This may be the same as your `Web` server

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "god restart twatlr"
  end
end

