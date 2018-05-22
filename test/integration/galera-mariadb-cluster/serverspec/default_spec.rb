require 'spec_helper'

describe service('mysqld') do
  it { should be_enabled }
end

status_checks = { "wsrep_local_state_comment" => "Synced",
           "wsrep_ready" => "ON",
           "wsrep_cluster_size" => "1"
         }

status_checks.each do |var, expected_val|
  cmd = "SHOW GLOBAL STATUS LIKE '#{var}';"
  describe command("mysql -u root -p'testpassword' -e \"#{cmd}\"") do
    its(:stdout) { should contain(expected_val) }
  end
end
