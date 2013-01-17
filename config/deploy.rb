set :application, 'twatlr'
set :repository,  'git://github.com/gf3/twatlr.com.git'
set :deploy_to,   '/usr/local/www/gianni/twatlr.com'
set :scm,         :git
set :user,        :gianni

set :git_enable_submodules, 1

role :web, '208.68.37.29'
role :app, '208.68.37.29'

after 'deploy', 'deploy:restart'

namespace :deploy do
  task :restart, roles: :app, except: { no_release: true } do
    pid_file = '%s/app.pid' % previous_release
    run '[ -f %1$s ] && kill $(cat %1$s); true' % pid_file
    run 'nohup /usr/bin/env racket %s/app.rkt > /dev/null 2>&1 &' % release_path
  end
end

