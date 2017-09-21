include_recipe "build-essential"

node['galera-cluster']['galera']['ruby']['packages'].each do |name|
  package name do
    action :install
  end
end

chef_gem "mysql" do
  compile_time false
end
