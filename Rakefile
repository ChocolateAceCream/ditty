require 'pp'
require 'mongo'
require 'fileutils'

begin
  require 'vlad'
  Vlad.load :scm => :git, :app => :unicorn
  desc "deploy"
  task "vlad:deploy" => %w[ vlad:update vlad:bundle:install vlad:link_config ]

  namespace :vlad do
    remote_task :link_config, :roles => :app do
      break unless target_host == Rake::RemoteTask.hosts_for(:app).first
      run "mv #{deploy_to}/current/config #{deploy_to}/current/old_config"
      run "ln -s #{deploy_to}/shared/config #{deploy_to}/current/config"
    end
  end
rescue LoadError
  # do nothing
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
rescue LoadError
  # do nothing
end

desc "start console with env"
task :console do
  ENV['RACK_ENV'] ||= "test"
  exec "irb -r 'pp' -r './dittyapp.rb'"
end

desc "start mongo console"
task :dbconsole do
  ENV['RACK_ENV'] ||= 'test'
  begin
    dbc = YAML.load_file("./config/ditty.yml")[ENV['RACK_ENV']]['database']
    exec "mongo -u #{dbc['username']} -p #{dbc['password']} #{dbc['name']}"
  rescue 
    abort "config/ditty.yml must be present"
  end
end

desc "start server"
task :server do
  ENV['RACK_ENV'] ||= 'development'
  puts "starting with #{ENV['RACK_ENV']} at http://localhost:9001/"
  exec 'unicorn --port 9001 ./config.ru'
end

namespace :unicorn do
  desc "Start unicorn"
  task :start do
    %x{ unicorn -c ./config/unicorn.rb }
  end

  desc "Start unicorn deamonized"
  task :start_d do
    %x{ unicorn -c ./config/unicorn.rb -D }
  end

  desc "Stop unicorn"
  task :stop do
    %x{ kill -QUIT $( cat log/unicorn.pid ) }
  end

  task :stop_f do
    %x{ ps aux | grep unicorn | grep -v grep | awk '{print $1}' | xargs kill -9 }
    %x{ [[ -e log/unicorn.pid ]] && rm log/unicorn.pid }
  end

  desc "Restart unicorn deamonized" 
  task :hup do
    Rake::Task['unicorn:stop'].invoke
    sleep 5
    Rake::Task['unicorn:start_d'].invoke
  end

end

desc "generate and update gh-pages"
task :pages do
  system(" set -x; bundle exec rspec ") or abort
  system(" set -x; bundle exec yardoc --protected ./lib/**/*.rb ") or abort
  system(" set -x; rm -rf /tmp/doc /tmp/coverage ") or abort
  system(" set -x; mv -v ./doc /tmp ") or abort
  system(" set -x; mv -v ./coverage /tmp ") or abort
  system(" set -x; git checkout gh-pages ") or abort
  system(" set -x; rm -rf ./doc ./coverage ") or abort
  system(" set -x; mv -v /tmp/doc . ") or abort
  system(" set -x; mv -v /tmp/coverage . ") or abort
  system(" set -x; git add . ") or abort 
  system(" set -x; git commit --all -m 'updating doc and coverage' ") or abort
  system(" set -x; git checkout master ") or abort
  puts "don't forget to run: git push origin gh-pages"
end
