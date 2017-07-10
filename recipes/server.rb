# Centos7 comes with mariadb-libs, which conflicts with mysql
package "mariadb-libs" do
  action :remove
end

platform_version = node['platform_version'].to_i

package "nc"
package "rsync"
package "galera-#{node['mysql']['galera']['version']}"
package "mysql-wsrep-#{node['mysql']['version']}"

directory node["mysql"]["conf"]["mysqld"]["datadir"] do
  owner "mysql"
  group "mysql"
  mode "0755"
  action :create
  recursive true
end

my_ip = node["ipaddress"]
init_host = (node["mysql"]["init_fqdn"] && Resolv.getaddresses(node["mysql"]["init_fqdn"]).last) || Resolv.getaddresses(node["mysql"]["fqdns"].first).last
wsrep_cluster_address = "gcomm://"
wsrep_cluster_address += node["mysql"]["fqdns"].map {|fqdn| Resolv.getaddresses(fqdn).last}.join(",")

node.default["mysql"]["conf"]["mysqld"]["wsrep_cluster_address"] = wsrep_cluster_address

template "my.cnf" do
  path "/etc/my.cnf"
  source "my.cnf.erb"
  variables :conf => node["mysql"]["conf"]
  owner "mysql"
  group "mysql"
  mode "0644"
end

cluster_name = node["mysql"]["conf"]["mysqld"]["wsrep_cluster_name"]

# Join cluster if it's running
service node["mysql"]["servicename"] do
  action :start
  only_if { Galera.cluster_status(node) == 'running' }
end

# Wrapper for galera that adds the wsrep-new-cluster option
execute "recover_cluster" do
  command "mysqld_bootstrap"
  action :run
  only_if { Galera.cluster_status(node) == 'down' }
end

# Create cluster if it never existed and we're the init host
execute "mysql_init_root_user" do
  command lazy { "mysql -u #{node["mysql"]["root_user"]} -p'#{Galera.get_tmp_password(node)}' "\
                 "--connect-expired-password -e \"SET GLOBAL validate_password_policy=LOW;"\
                 "SET PASSWORD FOR '#{node["mysql"]["root_user"]}'@'localhost' = 'temporarypassword';"\
                 "uninstall plugin validate_password;"\
                 "SET PASSWORD FOR '#{node["mysql"]["root_user"]}'@'localhost' = PASSWORD('#{node["mysql"]["server_root_password"]}');"\
                 "FLUSH PRIVILEGES;\""}
  action :nothing
  subscribes :run, "execute[init_#{cluster_name}]", :immediately
end

# We need to clean the datadir because wsrep-recover can spawn a cluster now
# We check we are the init_host to avoid race condition on init
execute "init_#{cluster_name}" do
  command "rm -r #{node["mysql"]["conf"]["mysqld"]["datadir"]}/* ; mysqld_bootstrap"
  action :run
  only_if { my_ip == init_host && Galera.cluster_status(node) == 'non-existent' }
end

# In any case, we try to create the users from every nodes
node["mysql"]["fqdns"].each do |host|
  all_users = node["mysql"]["users"].merge(node["mysql"]["root_user"] => node["mysql"]["server_root_password"])
  all_users.each do |user, password|
    galera_user "create user for #{host}" do
      action :create
      login node["mysql"]["root_user"]
      login_pw node["mysql"]["server_root_password"]
      user user
      host host
      password password
      only_if { Galera.cluster_status(node) == 'running' &&
                !Galera.user_exists?(node["mysql"]["root_user"], node["mysql"]["server_root_password"], user, host) }
    end
  end
end
