# puppet-galera

[![Build Status](https://github.com/markt-de/puppet-galera/actions/workflows/ci.yaml/badge.svg)](https://github.com/markt-de/puppet-galera/actions/workflows/ci.yaml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/markt/galera.svg)](https://forge.puppetlabs.com/markt/galera)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/markt/galera.svg)](https://forge.puppetlabs.com/markt/galera)

NOTE: The "main" branch on GitHub contains the development version, which may break anything at any time. Consider using one of the official releases instead.

#### Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Usage](#usage)
    - [Basic usage](#basic-usage)
    - [WSREP provider options](#wsrep-provider-options)
    - [More complex example](#more-complex-example)
    - [Configuring an Arbitrator](#configuring-an-arbitrator)
    - [Custom repository configuration](#custom-repository-configuration)
    - [FreeBSD support](#freebsd-support)
    - [EPP supported for many options](#epp-supported-for-many-options)
4. [OS and Cluster Compatibility](#os-and-cluster-compatibility)
5. [Reference](#reference)
6. [Limitations](#limitations)
7. [Development](#development)
    - [Contributing](#contributing)

## Overview

This module will massage puppetlabs-mysql into creating a Galera cluster on MySQL, MariaDB or XtraDB. It also supports setting up an Arbitrator node.

Automatic cluster bootstrap is controlled by `$bootstrap_mode` (default: `initial`). By default, bootstrap runs **only once** on `$galera_master` during first install. After a cluster has existed, Puppet will **not** bootstrap automatically during a full outage — recovery must be done manually or with `$bootstrap_mode => 'newest'`.

## Requirements

* Puppet 7 or higher
* [puppetlabs/mysql](https://github.com/puppetlabs/puppetlabs-mysql)
* A [supported version](#os-and-cluster-compatibility) of Codership Galera (MySQL), MariaDB or Percona XtraDB Cluster
* `nmap` is required for the cluster bootstrap functionality
* [puppetlabs/xinetd](https://github.com/puppetlabs/puppetlabs-xinetd) if `galera::status_type` is set to `xinetd` (default for FreeBSD)
* [puppet/systemd](https://github.com/voxpupuli/puppet-systemd) if `galera::status_type` is set to `systemd` (default for newer Linux distributions)
* [puppetlabs/firewall](https://github.com/puppetlabs/puppetlabs-firewall) unless `galera::configure_firewall` is disabled
* A working **PuppetDB** connection on the compiler (built-in `puppetdb_query` function) when `galera::discover_cluster_members` is enabled — there is **no** separate Forge module

## Usage

### Basic usage

Basic usage requires only the FQDN of the master node, a list of IP addresses of other nodes and two passwords:

```puppet
class { 'galera':
  # Galera vendor and version
  vendor_type    => 'codership',
  vendor_version => '8.0',
  # Galera cluster config
  cluster_name    => 'mycluster',
  galera_servers  => ['10.0.99.101', '10.0.99.102', '10.0.99.103'],
  galera_master   => 'node1.example.com',
  root_password   => 'pa$$w0rd',
  status_password => 'pa$$w0rd',
}
```

On Debian/Ubuntu systems the user `debian-sys-maint@localhost` is required for updates and will be created automatically, but you should set a proper password when using these platforms:

```puppet
class { 'galera':
  deb_sysmaint_password => 'secretpassword',
  ...
```

### WSREP provider options

Note that the module will automatically add the required Galera/WSREP provider options to the server configuration.
Currently the following parameters are automatically added: `wsrep_cluster_address`, `wsrep_cluster_name`, `wsrep_node_address`, `wsrep_node_incoming_address`, `wsrep_on`, `wsrep_provider`, `wsrep_slave_threads`, `wsrep_sst_method`, `wsrep_sst_auth`, `wsrep_sst_receive_address`.

Some of these values are used directly from their respective class parameter. For example, to change the SST method:

```puppet
class { 'galera':
  wsrep_sst_method => 'xtrabackup',
  ...
```

Other values like `wsrep_cluster_address` and `wsrep_sst_auth` are generated from several class parameters. Please have a look at the parameter reference and the module's `data` directory for further details.

Of course, all Galera/WSREP provider options can be overridden by using the `$override_options` parameter (see below for an example).

### More complex example

Furthermore, a number of simple options are available to customize the cluster configuration according to your needs:

```puppet
class { 'galera':
  # Galera vendor and version
  vendor_type     => 'codership',
  vendor_version  => '8.0',
  #
  # Galera cluster config
  cluster_name    => 'mycluster',
  galera_servers  => ['10.0.99.101', '10.0.99.102', '10.0.99.103'],
  galera_master   => 'node1.example.com',
  root_password   => 'pa$$w0rd',
  status_password => 'pa$$w0rd',
  #
  # This will be used to populate my.cnf values that
  # control where wsrep binds, advertises, and listens
  local_ip => $facts['networking']['ip'],
  #
  # This will be set when the cluster is bootstrapped
  root_password => 'myrootpassword',
  #
  # Disable this if you don't want firewall rules to be set
  configure_firewall => true,
  #
  # Configure the SST method
  wsrep_sst_method => 'xtrabackup-v2',
  #
  # These options are only used for the firewall -
  # to change the my.cnf settings, use the override options
  # described below
  mysql_port => 3306,
  wsrep_state_transfer_port => 4444,
  wsrep_inc_state_transfer_port => 4568,
  #
  # This is used for the firewall + for status checks
  # when deciding whether to bootstrap
  wsrep_group_comm_port => 4567,
}
```

A catch-all parameter `$override_options` can be used to populate my.cnf and overwrite default values in the same way as the puppetlabs-mysql module:

```puppet
class { 'galera':
  override_options => {
    'mysqld' => {
      'bind_address' => '0.0.0.0',
    }
  }
  ...
}
```

### Discovering cluster members with PuppetDB

Instead of maintaining a static list of IP addresses, cluster members can be
discovered automatically from PuppetDB. This uses the built-in `puppetdb_query`
function from the [PuppetDB terminus](https://www.puppet.com/docs/puppetdb/) —
**not** a separate Forge module (there is no `puppetlabs/puppetdb_query` package).

The Puppet compiler must have PuppetDB configured, for example in
`/etc/puppetlabs/puppet/puppetdb.conf` on the server.

Test on a compiler:

```bash
puppet apply -e "notice(puppetdb_query('resources[certname] { type = \"Class\" and title = \"Galera\" }'))"
```

If that fails, use a static member list instead (recommended for getting started):

```puppet
class { 'galera':
  vendor_type    => 'mariadb',
  vendor_version => '10.11',
  cluster_name   => 'mycluster',
  galera_servers => ['10.0.99.101', '10.0.99.102', '10.0.99.103'],
  galera_master  => 'node1.example.com',
  mysql_service_name => 'mariadb',
  ...
}
```

With PuppetDB discovery enabled:

```puppet
class { 'galera':
  vendor_type              => 'mariadb',
  vendor_version           => '10.11',
  cluster_name             => 'mycluster',
  discover_cluster_members => true,
  galera_master            => 'node1.example.com',
  root_password            => 'pa$$w0rd',
  status_password          => 'pa$$w0rd',
}
```

All nodes must declare the `galera` class with the same `$cluster_name`. The
default PuppetDB query selects nodes where the `Galera` class is present and
`cluster_name` matches.

You can still provide `$galera_servers` as a fallback when PuppetDB is
unavailable. With `$puppetdb_empty_query_safeguard` enabled (default), an empty
PuppetDB response will **not** shrink an existing cluster: configured servers,
the local IP, and the `wsrep_cluster_address` already present in MySQL
configuration are preserved.

`$minimum_cluster_size` together with `$puppetdb_require_minimum_size` (both
enabled by default) act as a safeswitch for **cluster bootstrap**: the master
node will not run the bootstrap command until enough nodes have registered in
PuppetDB. Cluster membership (`wsrep_cluster_address`) still includes all
nodes discovered so far, so configuration stays consistent across nodes.

Until `cluster_ready` is true on the bootstrap node, MySQL startup is deferred
there. Join nodes are blocked by an exec gate until port 4567 is open on a
peer — re-run Puppet after `$galera_master` has bootstrapped.

### Greenfield rollout order

1. Run `puppet agent -t` on **all** cluster nodes (registers them in PuppetDB).
2. Run `puppet agent -t` on `$galera_master` — bootstraps and starts MySQL.
3. Run `puppet agent -t` on the other nodes — they join once the master listens on 4567.

If step 3 fails with `galera_require_cluster_peer`, the bootstrap node is not up yet — complete step 2 first.

Debug with:

```bash
facter -j galera_wsrep_state
tail -50 /var/log/mysql/error.log
nmap -Pn -p 4567 <galera_master_ip>
grep wsrep /etc/mysql/my.cnf /etc/mysql/conf.d/*.cnf 2>/dev/null
```

A custom query can be supplied via `$puppetdb_query_string` if you use tags,
roles, or other criteria to identify cluster members.

### Cluster bootstrap

Bootstrap is controlled by `$bootstrap_mode`:

| Mode | Behaviour |
|------|-----------|
| `initial` (default) | Bootstrap only on `$galera_master` during **first install** (no `grastate.dat` yet, or `safe_to_bootstrap: 1`). After the cluster has existed once, automatic bootstrap is disabled. |
| `newest` | Bootstrap the node with the highest **fresh** `bootstrap_seqno` (local fact is always current; peer seqnos must be newer than `$bootstrap_fact_max_age` in PuppetDB). Requires `$discover_cluster_members => true`. |
| `disabled` | Never bootstrap automatically. Equivalent to `bootstrap_command => '/bin/false'`. |

Example for a production role that never auto-bootstraps after install:

```puppet
class { 'galera':
  bootstrap_mode => 'disabled',
  ...
}
```

Example for automated recovery using the node with the newest data:

```puppet
class { 'galera':
  discover_cluster_members => true,
  bootstrap_mode           => 'newest',
  bootstrap_fact_max_age   => 300,
  ...
}
```

**Important:** `$bootstrap_mode => 'newest'` compares seqnos from PuppetDB for peer nodes. A report that is 30 minutes old can show an outdated seqno and lead to the wrong node winning (or no bootstrap at all). With `$bootstrap_require_fresh_facts` enabled (default), **every** cluster member must have reported `galera_wsrep_state` within `$bootstrap_fact_max_age` seconds (default: 300) before any node bootstraps.

After a complete outage, refresh facts on all nodes first:

```bash
# On each cluster node, with MySQL stopped:
puppet agent -t
```

Then run Puppet again so the bootstrap decision uses current seqnos. The local node always uses its live `galera_wsrep_state` fact (including `mysqld --wsrep-recover`); only peer nodes rely on PuppetDB timestamps.

For production clusters, `$bootstrap_mode => 'initial'` (default) or `disabled` remains the safer choice.

After a **complete outage** with `$bootstrap_mode => 'initial'` (default), no node will bootstrap automatically. Follow your vendor's Galera recovery procedure manually (find the node with the highest seqno, bootstrap that node, then start the others).

### Configuring an Arbitrator

Configuring an Arbitrator service is straight-forward:

```puppet
class { 'galera':
  arbitrator      => true,
  cluster_name    => 'mycluster',
  galera_servers  => ['10.0.99.101', '10.0.99.102', '10.0.99.103'],
  ...
}
```

You may even use the same parameters that you would normally use for database nodes, when `$arbitrator` is set to `true` they will be ignored. This makes it easy to share the same parameters across all cluster nodes, no matter if they are real database nodes or just an arbitrator service.

### Custom repository configuration

This module automatically determines which APT/YUM repositories need to be configured. This depends on your choices for `$vendor_type`, `$vendor_version` and `$wsrep_sst_method`. Each of these choices may enable additional repositories.

For example, if setting `$vendor_type=codership` and `$wsrep_sst_method=xtrabackup`, the module will enable the Codership repository to install the Galera server and the Percona repository to install the XtraBackup tool. This works because every vendor/version and SST method may specify the internal `$want_repos` parameter, which is essentially a list of repositories.

Disable repo management if you are managing your own repos and mirrors:

```puppet
class { 'galera':
  configure_repo => false,
  ...
}
```

Or if you just want to switch to using a local mirror, simply change the repo URL for the chosen `$vendor_type`. For Codership you would add something like this to Hiera:

```puppet
# RHEL-based systems
galera::repo::codership::yum:
  baseurl: "http://repo.example.com/RPMS/<%= $vendor_version_real %>/%{facts.os.release.major}/%{facts.os.architecture}/"
  ...
```

```puppet
# Debian-based systems
galera::repo::codership::apt:
  location: "http://repo.example.com/apt/<%= $vendor_version_real %>/%{facts.os.distro.codename}/"
  ...
```

### FreeBSD support

This module (and all its dependencies) provide support for the FreeBSD operating system. However, from all vendors MariaDB seems to provide the best support for Galera clusters on FreeBSD. The following configuration is known to work:

```puppet
class { 'galera':
  configure_firewall => false,
  configure_repo     => false,
  galera_servers     => ['10.0.99.101', '10.0.99.102'],
  galera_master      => 'node1.example.com',
  root_password      => 'pa$$w0rd',
  status_password    => 'pa$$w0rd',
  vendor_type        => 'mariadb',
  vendor_version     => '10.11',
}
```

### EPP supported for many options

This module supports inline EPP for many of its options and parameters. This way class parameters and internal variables can be used when specifying options. Currently this is enabled for `$override_options`, `$wsrep_sst_auth` and all repository options.

    # server/wsrep options
```puppet
galera::override_options:
  mysqld:
    wsrep_sst_method: "<%= $wsrep_sst_method %>"
    wsrep_provider: "<%= $params['libgalera_location'] %>"

galera::wsrep_sst_auth: "root:<%= $root_password %>"
```

    # repo configuration
```puppet
galera::repo::codership::yum:
  baseurl: "http://releases.galeracluster.com/mysql-wsrep-<%= $vendor_version_real %>/%{os_name_lc}/%{os.release.major}/%{os.architecture}/"
  ...
```

## OS and Cluster Compatibility

Note that not all versions of Percona XtraDB, Codership Galera and MariaDB are supported on all operating systems. Please consult the official documentation to find out if your operating system is supported.

Below you will find an **incomplete** and possibly **outdated** list of known (in)compatiblities. Take it with a grain of salt.

|  | RedHat | Debian | Ubuntu | FreeBSD |
| :---     |  :---: |  :---: |  :---: |  :---: |
| **Percona XtraDB Cluster** | 8 / 9 | 11 / 12 | 22.04 / 24.04 | 14.x |
| 8.0 | ✔️ **/** ✔️ | ✔️ **/** ✔️ | ✔️ **/** ❌ | ❌ |
| **Codership Galera (MySQL)** |  |  |  |  |
| 8.0 / 8.4 | ✔️ ✔️ **/** ✔️ ✔️ | ✔️ ✔️ **/** ✔️ ✔️ | ✔️ ✔️ **/** ✔️ ✔️ | ❌ ❌ |
| **MariaDB Galera Cluster** |  |  |  |  |
| 10.11 / 11.4 | ❌ ❌ **/** ✔️ ✔️ | ❌ ❌ **/** ✔️ ✔️ | ❌ ❌ **/** ✔️ ✔️ | ✔️ ✔️ |

The table only includes the **two most recent** (LTS) versions.
Older and possibly outdated releases are not listed, although they may still be supported by their vendors.

## Reference

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

## Limitations

This module was created to work in tandem with the puppetlabs-mysql module, rather than replacing it. As the stages in the mysql module are quite strictly laid out in the `mysql::server` class, this module places its own resources in the gaps between them.

Bootstrap only runs when no peer already listens on the Galera port (`nmap` check) and `$bootstrap_permitted` is true for the selected `$bootstrap_mode`. The `nmap` check should not be considered terribly reliable.

With `$bootstrap_mode => 'newest'`, seqno comparison uses the local `galera_wsrep_state` fact on each node and PuppetDB for peers. Stale PuppetDB facts (older than `$bootstrap_fact_max_age`) block automatic bootstrap when `$bootstrap_require_fresh_facts` is enabled (default).

It should also be noted that it is not possible to unset default configuration variables (see [GH-174](https://github.com/markt-de/puppet-galera/issues/174)). This is true for this modules' own variables, but also for pre-defined variables that are set by the puppetlabs/mysql module.

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

All contributions must pass all existing tests, new features should provide additional unit/acceptance tests.
