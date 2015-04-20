define :magento_database do

include_recipe "mysql::server"
include_recipe "mysql::ruby"

# necessary for mysql gem installation
package "make" do
  action :upgrade
end
  
case node['platform']
when 'ubuntu'
  unless platform?('ubuntu') && node[:platform_version] == '14.04'
    package "libmysql-ruby" do
      action :install
    end
  else
    execute 'libmysqlclient-dev' do
      command 'apt-get install libmysqld-dev'
      action :run
    end
    bash "For libmysql-ruby" do
      user "root"
      code <<-EOH
      sudo gem update --system
      gem install mysql2
      EOH
    end
  end
when 'fedora'
  case node['platform_version'].to_f
  when 20.0
    package 'mariadb-devel' do
      action :install
    end
  else
    package 'mysql-devel' do
      action :install
    end
  end   
end

if('platform_family' == 'debian')
  package "libmysqlclient-dev" do
    action :install
  end
end


gem_package "mysql" do
  action :install
end

execute "mysql-install-mage-privileges" do
  command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} < /etc/mysql/mage-grants.sql"
  action :nothing
end

template "/etc/mysql/mage-grants.sql" do
  path "/etc/mysql/mage-grants.sql"
  source "grants.sql.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(:database => node[:magento][:db])
  notifies :run, resources(:execute => "mysql-install-mage-privileges"), :immediately
end
 
if platform?('ubuntu') && node[:platform_version] == '14.04'
  execute "Enable module php5-mcrypt" do
    command "php5enmod mcrypt"
  end
end

if platform?('ubuntu') && node[:platform_version] == '14.04'
  execute "Enable module php5-mcrypt" do
    command "php5enmod mcrypt"
  end
  
  service "php5-fpm" do
    provider Chef::Provider::Service::Upstart if platform?("ubuntu") && node["platform_version"].to_f >= 13.10    
    supports :start => true, :stop => true, :restart => true, :reload => true
    action [ :enable, :start ]
  end
end

execute "create #{node[:magento][:db][:database]} database" do
  command "/usr/bin/mysqladmin -u root -p#{node[:mysql][:server_root_password]} create #{node[:magento][:db][:database]}"
  not_if do
  require 'rubygems'
  Gem.clear_paths
  require 'mysql'
  m = Mysql.new("localhost", "root", node[:mysql][:server_root_password])
  m.list_dbs.include?(node[:magento][:db][:database])
  end
end

# save node data after writing the MYSQL root password, so that a failed chef-client run that gets this far doesn't cause an unknown password to get applied to the box without being saved in the node data.
unless Chef::Config[:solo]
  ruby_block "save node data" do
    block do
      node.save
    end
     action :create
  end
end
end
