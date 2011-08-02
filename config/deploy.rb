require 'bundler/capistrano'
require 'ruby-growl'


server "192.0.2.176", :app, :web, :db, :primary => true

set :application, "deployinator"
set :repository,  "git@github.com:winelibrary/deployinator.git"
set :scm, "git"
set :deploy_via, :remote_cache
set :git_enable_submodules, 1
set :deploy_to, "/var/www/deployinator/"
set :branch, "master"
set :user,  "deploy"
set :group, "deploy"
set :runner, "deploy"
set :use_sudo, false
set :deployed_by, %x{whoami}.chop!
set :keep_releases, 5
set :growl_hosts, ["192.0.2.239","192.0.2.153", "192.0.2.171", "192.0.2.159", "192.0.2.180"]

# Odd... shouldn't need to have this in here.  Not sure why it's not getting picked up
ssh_options[:keys] = [File.join(ENV['HOME'], ".ssh", "winelibrary_id_dsa")]
ssh_options[:forward_agent] = true

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  task :symlink_in_shared_directories, :roles => :app, :except => {:no_symlink => true} do
    commands = []
    commands << "echo `cat #{release_path}/REVISION | cut -c1-7`-#{Time.now.strftime("%Y-%m-%d-%H-%M")} > #{release_path}/public/REVISION"
    run commands.join("&& \n")
  end

  task :ensure_shared_directories_created, :roles => :app do
    %w{config system sphinx}.each do |dir|
      run <<-CMD
      mkdir -p #{shared_path}/#{dir}
      CMD
    end
  end
end

namespace :alert do
  desc "Alert all the team members of a deploy via growl"
  task :growl_deploy, :roles => :app do
    growl_hosts.each do |host|
      begin
        growl = Growl.new(host, "Capistrano", ["Capistrano Deploy"])
        growl.notify("Capistrano Deploy", "Message from Capistrano", "#{application} deployed to #{stage} by #{deployed_by}")
      rescue
        nil
      end
    end
  end

  desc "Alert of a rollback"
  task :growl_rollback, :roles => :app do
    growl_hosts.each do |host|
      begin
        growl = Growl.new(host, "Capistrano", ["Capistrano Rollback"])
        growl.notify("Capistrano Rollback", "Message from Capistrano", "#{application} rollbacked to #{stage}")
      rescue
        nil
      end
    end
  end
end

after "deploy", "deploy:migrate"
after "deploy", "deploy:cleanup"
# Afer successful deploy notify via growl and email
after "deploy", "alert:growl_deploy"
# After a failure notify the growl users
after "deploy:rollback", "alert:growl_rollback"
