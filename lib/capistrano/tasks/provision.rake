require 'yaml'

namespace :provision do
  task :test do
    puts fetch(:ip)
  end

  desc 'full provision setup'
  task :setup do
    invoke "provision:low_level_it_stuff"
    invoke "provision:chef_server"
    invoke "provision:chef_client"
    invoke "provision:knife:config"
    invoke "deploy"
    invoke "provision:knife:upload:cookbooks"
    invoke "provision:knife:upload:roles"
    invoke "provision:knife:create:nodes"
  end


  desc 'Create initial setup (creates deployer user + sudoer)'
  task :low_level_it_stuff do
    on roles(:all) do
      execute :useradd, 'deployer', interaction_handler: {
        'New password:' => 'deployer'
      }

      # Add user to wheel group
      execute :usermod, '-g wheel deployer'
      #Enable wheel group
      execute :echo, "'%wheel        ALL=(ALL)       NOPASSWD: ALL\n' >> /etc/sudoers"
      execute :sudo, :yum, 'install -y git'
    end
  end

  desc 'installs chef server'
  task :chef_server do
    on roles(:all) do
      chef_server = "chef-server-11.1.7-1.el6.x86_64.rpm"
      within '/tmp/' do
        execute :wget, "https://packagecloud.io/chef/stable/packages/el/6/#{chef_server}/download", "-qO #{chef_server}"
        execute :rpm, '-Uvh', chef_server
      end
      execute 'chef-server-ctl'.to_sym, :reconfigure
    end
  end

  desc 'installs chef-client & knife'
  task :chef_client do
    on roles(:all) do
      chef_client = 'chef-11.18.12-1.el6.x86_64.rpm'
      within '/tmp/' do
        execute :wget, "https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/#{chef_client}", "-qO #{chef_client}"
        execute :sudo, :rpm, '-Uhv', chef_client
      end
    end
  end

  desc 'basic knife configuration'
  namespace :knife do
    task :config do
      on roles(:all) do
        within '/root/' do
          execute :mkdir, '.chef'
        end
        within '/root/.chef' do
          execute :cp, '/etc/chef-server/admin.pem', 'admin.pem'
          knife = "
            log_level                :info
            log_location             STDOUT
            node_name                'admin'
            client_key               '/root/.chef/admin.pem'
            validation_client_name   'chef-validator'
            validation_key           '/etc/chef-server/chef-validator.pem'
            chef_server_url          'https://#{fetch(:ip)}:443'
            syntax_check_cache_path  '/root/.chef/syntax_check_cache'
            cookbook_path 		 [ '/etc/chef-workstation/current/cookbooks' ]
            knife[:editor] = '/usr/bin/vim'
          \n"

          execute :touch, 'knife.rb'
          execute :printf, " \"#{knife}\" >> knife.rb"
        end
        execute :knife, :environment, :create, :production, '-d'
        execute :knife, :environment, :create, :staging, '-d'
        execute :knife, :environment, :create, :development, '-d'
      end
    end

    namespace :upload do
      desc 'upload cookbooks to chef server'
      task :cookbooks do
        on roles(:all) do
          execute :knife, :cookbook, :upload, '-all'
        end
      end

      desc 'upload roles to chef server'
      task :roles do
        on roles(:all) do
          execute :knife, :role, "from file #{current_path}/roles/*.rb"
          execute :knife, :role, "from file #{current_path}/roles/*.json"
        end
      end
    end
    namespace :create do
      desc 'Create chef-client nodes'
      task :nodes do
        config = YAML.load_file("files/#{fetch(:stage)}/nodes.yml")
        on roles(:all) do
          config.each do |node|
            execute :knife, :node, :create, node['name'], '-d'
            execute :knife, :node, :run_list, :add, node['name'], node['role'].to_s, '-d'
          end
        end
      end
    end
  end
end
