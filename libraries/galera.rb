module Galera
  def self.cluster_running?(hosts, port)
    commands = hosts.map { |host| spawn("echo '' | nc -w 10 #{host} #{port}", :out => "/dev/null") }
    all_status = commands.map { |pid| Process.wait2(pid)[1].exitstatus  }
    all_status.min.zero?
  end

  def self.get_global_transaction_id(node)
    # http://galeracluster.com/documentation-webpages/restartingcluster.html
    log_file = node['galera-cluster']["conf"]["mysqld"]["log-error"]
    begin
      cmd = ::Mixlib::ShellOut.new("mysqld --wsrep-recover").run_command
      cmd.error!
    rescue => e
      Chef::Log.warn("Unable to run mysqld --wsrep-recover : #{e}")
    end

    if File.exist?(log_file)
      return IO.readlines(log_file).last(100).select { |line| line =~ /WSREP: Recovered position/ }[-1].strip.split(/[\s:]/)[-2]
    else
      return "00000000-0000-0000-0000-000000000000"
    end
  end

  def self.get_tmp_password(node)
    log_file = node['galera-cluster']["conf"]["mysqld"]["log-error"]
    if File.exist?(log_file)
      match_pw = File.readlines(log_file).select { |line| line =~ /temporary password/ }[-1]
      match_pw.nil? ? tmp_pw = '' : tmp_pw = match_pw.split(" ")[-1]
      return tmp_pw
    else
      return ''
    end
  end

  def self.transactions_exist?(node)
    # https://mariadb.com/kb/en/mariadb/galera-cluster-system-variables/
    gid = get_global_transaction_id(node)
    Chef::Log.warn("Galera cluster gid : " + gid)
    return gid != "00000000-0000-0000-0000-000000000000"
  end

  def self.user_exists?(login, login_pw, user, host)
    cmd = [ "mysql -u #{login} -p'#{login_pw}'",
            "\"SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '#{user}' and host = '#{host}');\"" ].join(" <<< ")
    res = ::Mixlib::ShellOut.new(cmd).run_command.stdout.split("\n").last
    return res == "1"
  end

  def self.cluster_status(node)
    hosts = node['galera-cluster']["fqdns"]
    port = node['galera-cluster']["conf"]["mysqld"]["port"]
    if cluster_running?(hosts, port)
      return 'running'
    elsif transactions_exist?(node)
      return 'down'
    else
      return 'non-existent'
    end
  end
end
