# This should work with any yum/chef version
# yum_repository resource has been removed from the yum cookbook in latests versions
# If we don't want to fix the yum version, or the chef version (which now includes
# yum_repository in >=12.14), we have to recreate the behavior of yum_repository


# We recommand to replace it by a recipe using yum_repository resource
# Also, use a mirror instead of the internet repo
repository_id = "galera-#{node['mysql']['galera']['version']}"

execute "yum clean metadata #{repository_id}" do
  command "yum clean metadata --disablerepo=* --enablerepo=#{repository_id}"
  action :nothing
  subscribes :run, "template[/etc/yum.repos.d/#{repository_id}.repo]", :immediately
end
# get the metadata for this repo only
execute "yum-makecache-#{repository_id}" do
  command "yum -q -y makecache --disablerepo=* --enablerepo=#{repository_id}"
  action :nothing
  subscribes :run, "template[/etc/yum.repos.d/#{repository_id}.repo]", :immediately
end

template "/etc/yum.repos.d/#{repository_id}.repo" do
  source "galera.repo.erb"
  variables ({
               "baseurl" => node["mysql"]["galera"]["repo"]["baseurl"],
               "gpgkey" => node["mysql"]["galera"]["repo"]["gpgkey"]
             })
  owner "root"
  group "root"
  mode "0644"
end
