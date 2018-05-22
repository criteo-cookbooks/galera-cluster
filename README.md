Description
===========
Galera Cluster provides synchronous multi-master replication for MySQL (replication plugin).

* No master failover scripting (automatic failover and recovery)
* No slave lag
* Read and write to any node
* Write scalabilty
* WAN Clustering

This cookbook enables you to install a Galera cluster. At minimum you need to change a few attributes like:

* ['galera-cluster']['root_password'] = "password"
* ['galera-cluster']['fqdns'] = ["fqdn1", "fqdn2", "fqdn3"]

If you want to set the init_host, you use:
* ['galera-cluster']['init_fqdn'] = "init_fqdn"

Engine choice
-------------
This cookbook supports mysql or mariadb engine by setting `['galera-cluster']['mysql_engine']` to `mysql` or `mariadb`.
The default is `mysql`

Requirements
============

Platform
--------
* CentOS7

Usage
=====

Include the recipe "galera::server" on galera nodes.
