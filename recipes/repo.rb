node['galera-cluster']['galera']['repositories'].each do |name, repo|
  yum_repository name do
    description repo['description']
    baseurl repo['baseurl']
    gpgkey repo['gpgkey']
    gpgcheck true
    enabled true
    action :create
  end
end

