property :login, String, default: 'root'
property :login_pw, String, required: true
property :user, String, required: true
property :host, String, required: true
property :password, String, required: true

action :create do
  cmd = [ "CREATE USER '#{new_resource.user}'@'#{new_resource.host}'" ]
  unless new_resource.password.empty?
    cmd << "IDENTIFIED BY '#{new_resource.password}'"
  end
  cmd << "; FLUSH PRIVILEGES;"
  cmd = cmd.join(" ")

  execute "mysql_create_user_#{new_resource.user}@#{new_resource.host}" do
    user 'mysql'
    command "mysql -u #{new_resource.login} -p'#{new_resource.login_pw}' -e \"#{cmd}\""
  end
end
