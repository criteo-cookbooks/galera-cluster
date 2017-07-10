Description
===========
Galera Cluster provides synchronous multi-master replication for MySQL (replication plugin).

* No master failover scripting (automatic failover and recovery)
* No slave lag
* Read and write to any node
* Write scalabilty
* WAN Clustering

This cookbook enables you to install a Galera cluster. At minimum you need to change a few attributes like:

* ['mysql']['root_password'] = "password"
* ['mysql']['fqdns'] = ["fqdn1", "fqdn2", "fqdn3"]

If you want to set the init_host, you use:
* ['mysql']['init_fqdn'] = "init_fqdn"

Requirements
============

Platform
--------
* CentOS6

Usage
=====

Include the recipe "galera::server" on galera nodes.
