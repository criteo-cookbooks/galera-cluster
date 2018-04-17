build_essential 'install_packages' do
  compile_time node['build-essential']['compile_time']
end

node['galera-cluster']['galera']['ruby']['packages'].each do |name|
  package name do
    action :install
  end
end

chef_gem "mysql" do
  compile_time false
end
