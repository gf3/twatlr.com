set :application, 'twatlr'
set :repository,  'git://github.com/gf3/twatlr.com.git'
set :deploy_to,   '/usr/local/www/gianni/twatlr.com'
set :scm,         :git
set :user,        :gianni

set :git_enable_submodules, 1

role :web, '208.68.37.29'
role :app, '208.68.37.29'

namespace :deploy do
  task :restart, roles: :app, except: { no_release: true } do
    run 'ps aux | grep app.rkt | awk "{print $2}" | xargs kill; true'
    run 'nohup /usr/local/bin/racket %s/app.rkt > /dev/null 2>&1 &' % release_path
  end
end

