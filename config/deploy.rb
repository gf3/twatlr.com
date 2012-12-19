set :application, "twatlr"
set :repository,  "git://github.com/gf3/twatlr.com.git"
set :deploy_to,   "/usr/local/www/gianni/twatlr.com"
set :scm,         :git
set :user,        :gianni

set :git_enable_submodules, 1

role :web, "46.38.167.162"
role :app, "46.38.167.162"

# default_run_options[:pty] = true

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    # run "cd #{release_path}; git submodule init; git submodule update"
    run "ps aux | grep app.rkt | awk '{print $2}' | xargs kill; true" # Ignore failed kills
    run "nohup /usr/local/bin/racket #{release_path}/app.rkt > /dev/null 2>&1 &" # Start server
  end
end

