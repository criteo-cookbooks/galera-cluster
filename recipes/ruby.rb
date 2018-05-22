build_essential 'install_packages' do
  compile_time node['build-essential']['compile_time']
end

yum_package node['galera-cluster']['galera']['ruby']['packages']

if node['galera-cluster']['mysql_engine'] == 'mariadb'
  execute 'force install' do
    command 'yum install -y MariaDB-shared && touch /root/.force-mariadb-shared-install'
    creates '/root/.force-mariadb-shared-install'
  end
end

chef_gem "mysql2" do
  compile_time false
end
