property :login, String, default: 'root'
property :login_pw, String, required: true
property :user, String, required: true
property :host, String, required: true
property :password, String, required: true

action :create do
  cmd = [ "CREATE USER '#{user}'@'#{host}'" ]
  unless password.empty?
    cmd << "IDENTIFIED BY '#{password}'"
  end
  cmd << "; FLUSH PRIVILEGES;"
  cmd = cmd.join(" ")

  execute "mysql_create_user_#{user}@#{host}" do
    user 'mysql'
    command "mysql -u #{login} -p'#{login_pw}' -e \"#{cmd}\""
  end
end
