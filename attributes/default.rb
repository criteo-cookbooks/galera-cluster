platform_version = node['platform_version'].to_i

default['galera-cluster']['version'] = '5.7'
default['galera-cluster']['galera']['version'] = '3'

# This shoud be overridden by a mirror
default['galera-cluster']['galera']['repositories'] = {
  "mysql-wsrep-#{node['galera-cluster']['version']}" => {
    'description' => 'Mysql WSREP',
    'baseurl' => "http://releases.galeracluster.com/mysql-wsrep-#{node['galera-cluster']["version"]}/centos/#{platform_version}/x86_64/",
    'gpgkey' => 'http://releases.galeracluster.com/GPG-KEY-galeracluster.com',
  },
  "galera-#{node['galera-cluster']['galera']['version']}" => {
    'description' => 'Galera repository',
    'baseurl' => "http://releases.galeracluster.com/galera-#{node['galera-cluster']["galera"]["version"]}/centos/#{platform_version}/x86_64/",
    'gpgkey' => 'http://releases.galeracluster.com/GPG-KEY-galeracluster.com',
  },
}

# Mysql default attributes
default['galera-cluster']["servicename"] = "mysqld"
default['galera-cluster']["root_user"] = "root"
default['galera-cluster']["server_root_password"] = ""
default['galera-cluster']["users"] = {}
# First fqdn of the list will be considered as the default init_fqdn
default['galera-cluster']["init_fqdn"] = nil
default['galera-cluster']["fqdns"] = nil

conf = {
  #conf basic attributes
  "mysqld" => {
    "datadir" =>  "/var/lib/mysql",
    "socket" => "/var/lib/mysql/mysql.sock",
    "user" => "mysql",
    "max_connections" => "800",
    "max_connect_errors" => "100000",
    "thread_stack" => "256K",
    "thread_cache_size" => "8",
    "sort_buffer_size" => "2M",
    "read_buffer_size" => "128k",
    "read_rnd_buffer_size" => "256k",
    "join_buffer_size" => "128k",
    "auto-increment-increment" => "1",
    "auto-increment-offset" => "1",
    "concurrent_insert" => "2",
    "connect_timeout " => "10",
    "wait_timeout " => "31536000",
    "net_read_timeout" => "30",
    "net_write_timeout" => "30",
    "back_log " => "128",
    "tmp_table_size " => "32M",
    "max_heap_table_size" => "32M",
    "bulk_insert_buffer_size" => "32M",
    "open-files-limit" => "1024",
    "query_cache_limit" => "1M",
    "query_cache_size" => "16M",
    "long_query_time " => "1",
    "expire_logs_days" => "10",
    "binlog_format" => "ROW",
    "max_binlog_size " => "100M",
    "binlog_cache_size" => "32K",
    "sync_binlog" => "0",
    "bind-address" => "0.0.0.0",
    "default_storage_engine" => "innodb",
    "innodb_autoinc_lock_mode" => "2",
    "innodb_buffer_pool_size" => "2G",
    "innodb_table_locks" => "true",
    "innodb_lock_wait_timeout" => "60",
    "innodb_thread_concurrency" => "48",
    "innodb_commit_concurrency" => "48",
    "innodb_support_xa" => "true",
    "innodb_log_file_size" => "5M",
    "innodb_data_file_path"   => "ibdata1:10M:autoextend",
    "innodb_flush_log_at_trx_commit" => "48",
    "innodb_log_buffer_size"  => "8M",
    "port" => "3306",
    "wsrep_provider" => "/usr/lib64/galera-#{node['galera-cluster']['galera']['version']}/libgalera_smm.so",
    "wsrep_provider_options" => "gcache.size=300M; gcache.page_size=300M",
    "wsrep_cluster_name" => "mysql_cluster",
    "wsrep_sst_method" => "rsync",
    "ignore-db-dir" => "lost+found",
    "default_password_lifetime" => "0",
    "log-error" => "/var/log/mysqld.log",
  },
  #conf safe attributes
  "mysqld_safe" => {
    "datadir" =>  "/var/lib/mysql",
    "pid-file" => "/var/run/mysqld/mysqld.pid",
  },
}

# We want the build-essential package to be install at compile time
default['build-essential']['compile_time'] = true

# Packages to install at compile time
default['galera-cluster']['galera']['ruby']['packages'] =  [
  "mysql-wsrep-devel-5.7",
  "mysql-wsrep-libs-compat-5.7",
  "mysql-wsrep-shared-5.6"
]

# At bootstrap, we need to clean this directory recursively
# Looks safer to fix the value
default['galera-cluster']["conf"]["mysqld"]["datadir"] = "/var/lib/mysql"

conf.each do |k,v|
  default['galera-cluster']["conf"][k] = v
end
