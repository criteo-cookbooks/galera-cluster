package 'mysql-libs' do
  action :remove
end

node.normal["ipaddress"] = "127.0.0.1"
node.automatic["ipaddress"] = "127.0.0.1"
node.automatic['galera-cluster']["fqdns"] = ["127.0.0.1"]
include_recipe "galera-cluster::server"
