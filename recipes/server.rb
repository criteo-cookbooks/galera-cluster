supported_engines = ['mariadb', 'mysql']
unless supported_engines.include?(node['galera-cluster']['mysql_engine'])
  ::Chef::Log.error("Galera: `#{node['galera-cluster']['mysql_engine']}` is not in the supported engines #{supported_engines.join(', ')}")
  return
end

# include_recipe 'yum-criteo'
include_recipe "galera-cluster::repo"

# Centos7 comes with mariadb-libs, which conflicts with mysql
if node['galera-cluster']['mysql_engine'] != 'mariadb'
  package "mariadb-libs" do
    action :remove
  end
end

platform_version = node['platform_version'].to_i

package "nc"
package "rsync"
yum_package node['galera-cluster']['galera'][node['galera-cluster']['mysql_engine']]['packages']

directory node['galera-cluster']["conf"]["mysqld"]["datadir"] do
  owner "mysql"
  group "mysql"
  mode "0755"
  action :create
  recursive true
end

my_ip = node['galera-cluster']['ipaddress'] || node['ipaddress']
init_host = (node['galera-cluster']["init_fqdn"] && Resolv.getaddresses(node['galera-cluster']["init_fqdn"]).last) || Resolv.getaddresses(node['galera-cluster']["fqdns"].first).last
wsrep_cluster_address = "gcomm://"
wsrep_cluster_address += node['galera-cluster']["fqdns"].map {|fqdn| Resolv.getaddresses(fqdn).last}.join(",")

node.default['galera-cluster']["conf"]["mysqld"]["wsrep_cluster_address"] = wsrep_cluster_address

template "my.cnf" do
  path "/etc/my.cnf"
  source "my.cnf.erb"
  variables :conf => node['galera-cluster']["conf"]
  owner "mysql"
  group "mysql"
  mode "0644"
end

cluster_name = node['galera-cluster']["conf"]["mysqld"]["wsrep_cluster_name"]

# Join cluster if it's running
service node['galera-cluster']["servicename"] do
  action :start
  only_if { Galera.cluster_status(node) == 'running' }
end

# Wrapper for galera that adds the wsrep-new-cluster option
execute "recover_cluster" do
  command "mysqld_bootstrap"
  action :run
  only_if { Galera.cluster_status(node) == 'down' }
end

if node['galera-cluster']['mysql_engine'] == 'mariadb'
  execute 'change first install root password' do
    command '/usr/bin/mysqladmin -u root password \'' + \
      node['galera-cluster']["server_root_password"] + '\''
    action :nothing
    sensitive true
    subscribes :run, "execute[init_#{cluster_name}]", :immediately
  end
else
  execute "mysql_init_root_user" do
    command lazy { "mysql -u #{node['galera-cluster']["root_user"]} -p'#{Galera.get_tmp_password(node)}' "\
                  "--connect-expired-password -e \"SET GLOBAL validate_password_policy=LOW;"\
                  "SET PASSWORD FOR '#{node['galera-cluster']["root_user"]}'@'localhost' = 'temporarypassword';"\
                  "uninstall plugin validate_password;"\
                  "SET PASSWORD FOR '#{node['galera-cluster']["root_user"]}'@'localhost' = PASSWORD('#{node['galera-cluster']["server_root_password"]}');"\
                  "FLUSH PRIVILEGES;\""}
    action :nothing
    subscribes :run, "execute[init_#{cluster_name}]", :immediately
  end
end

# Create cluster if it never existed and we're the init host
# We need to clean the datadir because wsrep-recover can spawn a cluster now
# We check we are the init_host to avoid race condition on init
if node['galera-cluster']['mysql_engine'] == 'mariadb'
  execute "init_#{cluster_name}_rm_datadir" do
    command "rm -r #{node['galera-cluster']["conf"]["mysqld"]["datadir"]}/*"
    action :run
    only_if { my_ip == init_host && Galera.cluster_status(node) == 'non-existent' }
  end

  execute "init_#{cluster_name}_system_tables" do
    command "mysql_install_db --user=mysql --ldata=#{node['galera-cluster']["conf"]["mysqld"]["datadir"]}"
    action :run
    only_if { my_ip == init_host && Galera.cluster_status(node) == 'non-existent' }
  end

  execute "init_#{cluster_name}" do
    command "galera_new_cluster"
    action :run
    only_if { my_ip == init_host && Galera.cluster_status(node) == 'non-existent' }
  end
else
  execute "init_#{cluster_name}" do
    command "rm -r #{node['galera-cluster']["conf"]["mysqld"]["datadir"]}/* ; mysqld_bootstrap"
    action :run
    only_if { my_ip == init_host && Galera.cluster_status(node) == 'non-existent' }
  end
end

# In any case, we try to create the users from every nodes
node['galera-cluster']["fqdns"].each do |host|
  all_users = node['galera-cluster']["users"].merge(node['galera-cluster']["root_user"] => node['galera-cluster']["server_root_password"])
  all_users.each do |user, password|
    galera_cluster_user "create user for #{host}" do
      action :create
      login node['galera-cluster']["root_user"]
      login_pw node['galera-cluster']["server_root_password"]
      user user
      host host
      password password
      only_if { Galera.cluster_status(node) == 'running' &&
                !Galera.user_exists?(node['galera-cluster']["root_user"], node['galera-cluster']["server_root_password"], user, host) }
    end
  end
end
