name             'galera-cluster'
maintainer       'Criteo'
maintainer_email 'lake@criteo.com'
license          'Apache-2.0'
description      'Installs Galera Cluster for MySQL'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url       ''
source_url       'https://github.com/criteo-cookbooks/galera-cluster'
version          '0.0.4'
supports         'centos'

chef_version '>= 12.14.34'

depends          'build-essential'
