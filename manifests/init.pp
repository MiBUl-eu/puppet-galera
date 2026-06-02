# @summary Installs MySQL/MariaDB with galera cluster plugin
#
# @param additional_packages
#   Specifies a list of additional packages that may be required for SST and
#   other features. The module automatically discovers all additional packages
#   that are required for the selected vendor/sst, but this parameter can be
#   used to overwrite the discovered package list.
#   Default: A vendor-, version- and OS-specific value.
#
# @param arbitrator
#   Specifies whether this node should run Galera Arbitrator instead of a
#   MySQL/MariaDB server.
#
# @param arbitrator_config_file
#   Specifies the configuration file for the Arbitrator service.
#   Default: A vendor-, version- and OS-specific value.
#
# @param arbitrator_log_file
#   Specifies the optional log file for the Arbitrator service.
#   By default it logs to syslog.
#
# @param arbitrator_options
#   Specifies configuration options for the Arbitrator service.
#
# @param arbitrator_package_ensure
#   Specifies the ensure state for the Arbitrator package.
#   Valid options: all values supported by the package type.
#   Default: `present`
#
# @param arbitrator_package_name
#   Specifies the name of the Arbitrator package to install.
#   Default: A vendor-, version- and OS-specific value.
#
# @param arbitrator_service_enabled
#   Specifies whether the Arbitrator service should be enabled.
#   Expects that `$arbitrator` is also set to `true`.
#   Default: `true`
#
# @param arbitrator_service_name
#   Specifies the name of the Arbitrator service.
#   Default: A vendor-, version- and OS-specific value.
#
# @param arbitrator_template
#   Specifies the template to use when creating `$arbitrator_config_file`.
#
# @param bind_address
#   Specifies the IP address to bind MySQL/MariaDB to. The module expects the
#   server to listen on localhost for proper operation. Default: `::`
#
# @param bootstrap_command
#   Specifies a command used to bootstrap the galera cluster.
#   Default: A vendor-, version- and OS-specific bootstrap command.
#
# @param client_package_name
#   Specifies the name of the MySQL/MariaDB client package to install.
#   Default: A vendor-, version- and OS-specific value.
#
# @param cluster_name
#   Specifies the name of the cluster and should be identical on all nodes.
#   This must be set for the module to work properly (although galera does
#   not require this value.)
#
# @param configure_firewall
#   Specifies whether to open firewall ports used by galera using
#   puppetlabs-firewall. Default: `true`
#
# @param configure_repo
#   Specifies whether to configure additional repositories that are required for
#   installing galera. Default: `true`
#
# @param create_root_my_cnf
#   A flag to indicate if we should manage the root .my.cnf. Set this to false
#   if you wish to manage your root .my.cnf file elsewhere. Default: `true`
#
# @param create_root_user
#   A flag to indicate if we should manage the root user. Set this to false if
#   you wish to manage your root user elsewhere. If this is set to `undef`, the
#   module will use `true` if this node is `$galera_master`. Default: `undef`
#
# @param create_status_user
#   A flag to indicate if we should manage the status user. Set this to false
#   if you wish to manage your status user elsewhere. Default: `true`
#
# @param deb_sysmaint_password
#   Specifies the password to set on Debian/Ubuntu for the sysmaint user used
#   during updates. Default: `sysmaint`
#
# @param default_options
#   Internal parameter, *do NOT change!* Use `$override_options` to customize
#   MySQL options.
#
# @param epel_needed
#   Specifies whether or not the EPEL repository should be enabled on
#   RedHat-based systems. This is required for certain vendors and SST methods
#   to install packages such as socat.
#   Default: `true`
#
# @param galera_master
#   Specifies the node that bootstraps the cluster on first install when
#   `$bootstrap_mode` is `initial`. Also used as a tie-breaker when
#   `$bootstrap_mode` is `newest`. Default: `$fqdn`
#
# @param bootstrap_mode
#   Controls automatic cluster bootstrap. Valid options:
#   `disabled` — never bootstrap automatically;
#   `initial` — bootstrap only on `$galera_master` during first install
#   (no existing `grastate.dat`, or `safe_to_bootstrap: 1`);
#   `newest` — bootstrap the node with the highest `bootstrap_seqno` among
#   cluster members with fresh PuppetDB facts (requires
#   `$discover_cluster_members`). Default: `initial`
#
# @param bootstrap_fact_max_age
#   Maximum age in seconds for a peer's `galera_wsrep_state` fact in PuppetDB
#   when `$bootstrap_mode` is `newest` and `$bootstrap_require_fresh_facts`
#   is enabled. Default: `300`
#
# @param bootstrap_require_fresh_facts
#   When enabled with `$bootstrap_mode` set to `newest`, every cluster member
#   must have reported `galera_wsrep_state` within `$bootstrap_fact_max_age`
#   before any node may bootstrap. Prevents decisions based on stale seqnos.
#   Default: `true`
#
# @param galera_package_ensure
#   Specifies the ensure state for the galera package. Note that some vendors
#   do not allow installation of the wsrep-enabled MySQL/MariaDB and galera
#   (arbitrator) on the same server. Valid options: all values supported by
#   the package type. Default: `absent`
#
# @param galera_package_name
#   Specifies the name of the galera wsrep package to install.
#   Default: A vendor-, version- and OS-specific value.
#
# @param galera_servers
#   Specifies a list of IP addresses of the nodes in the galera cluster.
#   When `$discover_cluster_members` is enabled, this list is merged with
#   PuppetDB results and used as a fallback when PuppetDB returns no nodes.
#
# @param discover_cluster_members
#   When enabled, cluster members are discovered via PuppetDB in addition to
#   any statically configured `$galera_servers`. Requires the built-in
#   `puppetdb_query` function (PuppetDB terminus on the compiler). Default: `false`
#
# @param puppetdb_query_string
#   Optional PuppetDB Query Language (PQL) query used to discover cluster
#   members. When unset, a default query selects nodes with the `Galera` class
#   and a matching `$cluster_name`. The query must return IP addresses.
#
# @param puppetdb_ip_fact
#   Fact name used in the default PuppetDB query to obtain node IP addresses.
#   Default: `networking.ip`
#
# @param minimum_cluster_size
#   Minimum number of nodes (including this node) that must register in
#   PuppetDB before the master node is allowed to bootstrap the cluster.
#   Default: `3`
#
# @param puppetdb_require_minimum_size
#   When enabled together with `$discover_cluster_members`, the master node
#   will not bootstrap until `$minimum_cluster_size` nodes have registered.
#   This prevents premature cluster bootstrap while nodes are still joining.
#   Default: `true`
#
# @param puppetdb_empty_query_safeguard
#   When enabled, an empty PuppetDB response will not shrink the cluster
#   membership. Configured servers and the existing `wsrep_cluster_address`
#   on the node are preserved instead. Default: `true`
#
# @param libgalera_location
#   Specifies the location of the WSREP libraries.
#
# @param local_ip
#   Specifies the IP address of this node to use for communications.
#   Default: `$networking.ip`
#
# @param manage_additional_packages
#   Specifies whether additional packages should be installed that may be
#   required for SST and other features. Default: `true`
#
# @param mysql_package_name
#   Specifies the name of the server package to install.
#   Default: A vendor-, version- and OS-specific value.
#
# @param mysql_port
#   Specifies the port to use for MySQL/MariaDB. Default: `3306`
#
# @param mysql_restart
#   Specifies the option to pass through to `mysql::server::restart`. This can
#   cause issues during bootstrapping if switched on. Default: `false`
#
# @param mysql_service_name
#   Specifies the option to pass through to `mysql::server`.
#   Default: A vendor-, version- and OS-specific value.
#
# @param override_options
#   Specifies options to pass to `mysql::server` class. See the puppetlabs-mysql
#   documentation for more information. Default: `{}`
#
# @param override_repos
#   Usually the required YUM/APT repositories are automatically selected,
#   depending on the values of `$vendor_type` and `$vendor_version`. This
#   parameter will override this to provide a custom selection of repositories.
#
# @param package_ensure
#   Specifies the ensure state for packages. Valid options: all values supported
#   by the package type. Default: `present`
#
# @param purge_conf_dir
#   Specifies the option to pass through to `mysql::server`. Default: `true`
#
# @param root_password
#   Specifies the MySQL/MariaDB root password.
#
# @param rundir
#   Specifies the rundir for the MySQL/MariaDB service.
#   Default: `/var/run/mysqld`
#
# @param service_enabled
#   Specifies whether the MySQL/MariaDB service should be enabled.
#   Default: `true`
#
# @param status_allow
#   Specifies the subnet or host(s) (in MySQL/MariaDB syntax) to allow status
#   checks from. Default: `%`
#
# @param status_available_when_donor
#   Specifies whether the node will remain in the cluster when it enters donor
#   mode. Valid options: `0` (remove), `1` (remain). Default: `0`
#
# @param status_available_when_readonly
#   When set to 0, clustercheck will return a "503 Service Unavailable" if the
#   node is in the read_only state, as defined by the `read_only` MySQL/MariaDB
#   variable. Values other than 0 have no effect. Default: `-1`
#
# @param status_check
#   Specifies whether to configure a user and script that will check the status
#   of the galera cluster. Default: `true`
#
# @param status_check_type
#   Specifies the type of service to use for status checks. Supported values
#   are either `systemd` or `xinetd`, depending on the operating system.
#
# @param status_cps
#   Rate limit config for the xinetd status service.
#
# @param status_flags
#   Flags for the xinetd status service.
#
# @param status_host
#   Specifies the cluster to add the cluster check user to. Default: `localhost`
#
# @param status_instances
#   Number of active instances for the xinetd status service.
#
# @param status_log_on_failure
#   Specifies which fields xinetd will log on failure. Default: `undef`
#
# @param status_log_on_failure_operator
#   Specifies which operator xinetd uses to output logs on failure.
#
# @param status_log_on_success
#   Specifies which fields xinetd will log on success. Default: `''`
#
# @param status_log_on_success_operator
#   Specifies which operator xinetd uses to output logs on success.
#   Default: `=`
#
# @param status_log_type
#   Log type for the xinetd status service.
#
# @param status_password
#   Specifies the password of the status check user.
#
# @param status_port
#   Specifies the port for cluster check service. Default: `9200`
#
# @param status_script
#   The script that will be used for status checks.
#
# @param status_service_type
#   Service type for the xinetd status service.
#
# @param status_system_group
#   The operating system group that will be managed for the status check.
#
# @param status_system_user
#   The operating system user that will be managed for the status check.
#
# @param status_system_user_config
#   The config for the operating system user.
#
# @param status_systemd_service_name
#   The name of the systemd status service.
#
# @param status_user
#   Specifies the name of the user to use for status checks.
#   Default: `clustercheck`
#
# @param status_xinetd_service_name
#   The name of the xinetd status service.
#
# @param validate_connection
#   Specifies whether the module should ensure that the cluster can accept
#   connections at the point where the `mysql::server` resource is marked
#   as complete. This is used because after returning success, the service
#   is still not quite ready. Default: `true`
#
# @param vendor_type
#   Specifies the galera vendor (or flavour) to use.
#   Valid options: codership, mariadb, percona. Default: `percona`
#
# @param vendor_version
#   Specifies the galera version to use. To avoid accidential updates,
#   set this to the required version.
#   Default: A vendor- and OS-specific value. (Usually the most recent version.)
#
# @param wsrep_group_comm_port
#   Specifies the port to use for galera clustering. Default: `4567`
#
# @param wsrep_inc_state_transfer_port
#   Specifies the port to use for galera incremental state transfer.
#   Default: `4568`
#
# @param wsrep_sst_auth
#   Specifies the authentication information to use for SST.
#   Default: `root:<%= $root_password %>`
#
# @param wsrep_sst_method
#   Specifies the method to use for state snapshot transfer between nodes.
#   Valid options: clone, mysqldump, rsync, skip, xtrabackup, xtrabackup-v2.
#   Default: `rsync`
#
# @param wsrep_state_transfer_port
#   Specifies the port to use for galera state transfer.
#   Default: `4444`
#
class galera (
  # parameters that need to be evaluated early
  Enum['codership', 'mariadb', 'percona'] $vendor_type,
  String $vendor_version,
  # required parameters
  Boolean $arbitrator,
  String $arbitrator_options,
  String $arbitrator_package_ensure,
  Boolean $arbitrator_service_enabled,
  String $arbitrator_template,
  String $bind_address,
  String $cluster_name,
  Boolean $configure_firewall,
  Boolean $configure_repo,
  Boolean $create_root_my_cnf,
  Boolean $create_status_user,
  String $deb_sysmaint_password,
  Hash $default_options,
  Boolean $epel_needed,
  String $galera_master,
  Enum['disabled', 'initial', 'newest'] $bootstrap_mode,
  Integer $bootstrap_fact_max_age,
  Boolean $bootstrap_require_fresh_facts,
  String $local_ip,
  Boolean $manage_additional_packages,
  Integer $mysql_port,
  Boolean $mysql_restart,
  Hash $override_options,
  String $package_ensure,
  Boolean $purge_conf_dir,
  String $root_password,
  String $rundir,
  Boolean $service_enabled,
  String $status_allow,
  Integer $status_available_when_donor,
  Integer $status_available_when_readonly,
  Boolean $status_check,
  Enum['systemd', 'xinetd'] $status_check_type,
  Stdlib::Absolutepath $status_script,
  String $status_host,
  String $status_log_on_success_operator,
  String $status_password,
  Integer $status_port,
  String $status_system_group,
  String $status_system_user,
  Hash $status_system_user_config,
  String $status_systemd_service_name,
  String $status_user,
  String $status_xinetd_service_name,
  Boolean $validate_connection,
  Integer $wsrep_group_comm_port,
  Integer $wsrep_inc_state_transfer_port,
  String $wsrep_sst_auth,
  Enum['clone', 'mariabackup', 'mysqldump', 'rsync', 'skip', 'xtrabackup', 'xtrabackup-v2'] $wsrep_sst_method,
  Integer $wsrep_state_transfer_port,
  # optional parameters
  # (some of them are actually required, see notes)
  Optional[Array] $additional_packages = undef,
  Optional[String] $arbitrator_config_file = undef,
  Optional[String] $arbitrator_log_file = undef,
  Optional[String] $arbitrator_package_name = undef,
  Optional[String] $arbitrator_service_name = undef,
  Optional[String] $bootstrap_command = undef,
  Optional[String] $client_package_name = undef,
  Optional[Boolean] $create_root_user = undef,
  Optional[String] $galera_package_ensure = undef,
  Optional[String] $galera_package_name = undef,
  Optional[Array] $galera_servers = undef,
  Boolean $discover_cluster_members = false,
  Optional[String] $puppetdb_query_string = undef,
  String $puppetdb_ip_fact = 'networking.ip',
  Integer $minimum_cluster_size = 3,
  Boolean $puppetdb_require_minimum_size = true,
  Boolean $puppetdb_empty_query_safeguard = true,
  Optional[String] $libgalera_location = undef,
  Optional[String] $mysql_package_name = undef,
  Optional[String] $mysql_service_name = undef,
  Optional[Array] $override_repos = undef,
  Optional[String] $status_cps = undef,
  Optional[String] $status_flags = undef,
  Optional[String] $status_instances = undef,
  Optional[String] $status_log_on_failure = undef,
  Optional[String] $status_log_on_failure_operator = undef,
  Optional[String] $status_log_on_success = undef,
  Optional[String] $status_log_type = undef,
  Optional[String] $status_service_type = undef,
) {
  # Adjust $vendor_version for use with lookup()
  # The '_real' variable is kept for compatibility reasons, it may be
  # used in inline epp templates.
  $vendor_version_real = $vendor_version
  $vendor_version_internal = regsubst($vendor_version_real, '\.', '', 'G')

  # Percona supports 'xtrabackup-v2', but this value cannot be used in our automatic
  # lookups, so we have to use a temporary value.
  $wsrep_sst_method_internal = regsubst($wsrep_sst_method, '-', '_', 'G')

  # Lookup additional packages from all possible sources:
  #   galera::sst::SSTMETHOD::VENDOR::VERSION::additional_packages
  #   galera::sst::SSTMETHOD::additional_packages
  #   galera::VENDOR::VERSION::additional_packages
  #   galera::VENDOR::additional_packages
  # A user-specified value takes precedence over automatic lookup results.
  if !$additional_packages {
    # Lookup packages for the selected vendor.
    $_packages_vendor = lookup("${module_name}::${vendor_type}::${vendor_version_internal}::additional_packages", { default_value => undef }) ? {
      undef => lookup("${module_name}::${vendor_type}::additional_packages", { default_value => [] }),
      default => lookup("${module_name}::${vendor_type}::${vendor_version_internal}::additional_packages", { default_value => [] }),
    }
    # Lookup packages for the selected SST method.
    if !$arbitrator {
      $_packages_sst = lookup("${module_name}::sst::${wsrep_sst_method_internal}::${vendor_type}::${vendor_version_internal}::additional_packages", { default_value => undef }) ? {
        undef => lookup("${module_name}::sst::${wsrep_sst_method_internal}::additional_packages", { default_value => [] }),
        default => lookup("${module_name}::sst::${wsrep_sst_method_internal}::${vendor_type}::${vendor_version_internal}::additional_packages", { default_value => [] })
      }
    } else { $_packages_sst = [] }
    # Merge packages from both sources and make them unique.
    $additional_packages_real = ($_packages_sst + $_packages_vendor).unique
  } else { $additional_packages_real = $additional_packages }

  # The following compatibility layer (part 2) is only required for parameters
  # that may vary depending on the values of $vendor_version and $vendor_type.
  $params = {
    arbitrator_config_file => $arbitrator_config_file,
    arbitrator_package_name => $arbitrator_package_name,
    arbitrator_service_name => $arbitrator_service_name,
    bootstrap_command => $bootstrap_command,
    client_package_name => $client_package_name,
    galera_package_ensure => $galera_package_ensure,
    galera_package_name => $galera_package_name,
    libgalera_location => $libgalera_location,
    mysql_package_name => $mysql_package_name,
    mysql_service_name => $mysql_service_name,
  }.reduce({}) |$memo, $x| {
    # If a value was specified as class parameter, then use it. Otherwise use
    # lookup() to find a value in Hiera (or to fallback to default values from
    # module data).
    if !$x[1] {
      $_v = lookup("${module_name}::${vendor_type}::${vendor_version_internal}::${$x[0]}", { default_value => undef }) ? {
        undef => lookup("${module_name}::${vendor_type}::${$x[0]}"),
        default => lookup("${module_name}::${vendor_type}::${vendor_version_internal}::${$x[0]}"),
      }
    } else {
      $_v = $x[1]
    }
    $memo + { $x[0] => $_v }
  }
  $mysql_service_name_effective = $params['mysql_service_name']

  # Lookup *optional* parameters that may vary depending on the values of
  # $vendor_version and $vendor_type. These parameters will later be passed
  # to the mysql::server class.
  $optional_params = {
    config_file => undef,
    includedir => undef,
  }.reduce({}) |$memo, $x| {
    $_v = lookup("${module_name}::${vendor_type}::${vendor_version_internal}::${$x[0]}", { default_value => undef }) ? {
      undef => lookup("${module_name}::${vendor_type}::${$x[0]}", { default_value => undef }),
      default => lookup("${module_name}::${vendor_type}::${vendor_version_internal}::${$x[0]}"),
    }
    $memo + { $x[0] => $_v }
  }

  $existing_cluster_members = if $facts['galera_cluster_members'] {
    $facts['galera_cluster_members']
  } else {
    []
  }

  $_cluster_members = galera::resolve_cluster_members(
    $discover_cluster_members,
    $galera_servers,
    $local_ip,
    $cluster_name,
    $puppetdb_query_string,
    $puppetdb_ip_fact,
    $minimum_cluster_size,
    $puppetdb_require_minimum_size,
    $puppetdb_empty_query_safeguard,
    $existing_cluster_members,
  )
  $galera_servers_effective = $_cluster_members['members']
  $cluster_ready = $_cluster_members['cluster_ready']

  $wsrep_state = if $facts['galera_wsrep_state'] {
    $facts['galera_wsrep_state']
  } else {
    {
      'grastate_present' => false,
      'safe_to_bootstrap' => false,
      'bootstrap_seqno' => -1,
      'grastate_path' => '/var/lib/mysql/grastate.dat',
    }
  }

  $bootstrap_permitted = galera::bootstrap_permitted(
    $bootstrap_mode,
    $facts['networking']['fqdn'],
    $galera_master,
    $cluster_name,
    $discover_cluster_members,
    $wsrep_state,
    $bootstrap_fact_max_age,
    $bootstrap_require_fresh_facts,
  )

  # Galera cannot start without bootstrap (master) or a running peer to join.
  $_peer_ips = $galera_servers_effective.filter |$ip| { $ip != $local_ip }
  $_peer_list = join($_peer_ips, ' ')

  $await_puppetdb_peers = (
    $discover_cluster_members and
    $puppetdb_require_minimum_size and
    !$cluster_ready and
    !$wsrep_state['grastate_present']
  )

  $bootstrap_waiting = ($bootstrap_permitted and $await_puppetdb_peers)
  $join_waiting = (!$bootstrap_permitted and $_peer_list == '')
  $mysql_start_deferred = $bootstrap_waiting or $join_waiting
  $bootstrap_allowed = $bootstrap_permitted and ($cluster_ready or !$await_puppetdb_peers)

  # Add the wsrep_cluster_address option to the server configuration.
  # It requires some preprocessing...
  $_nodes_tmp = $galera_servers_effective.map |$node| { "${node}:${wsrep_group_comm_port}" }
  $node_list = join($_nodes_tmp, ',')
  $_wsrep_cluster_address = {
    'mysqld' => {
      'wsrep_cluster_address' => "gcomm://${node_list}/",
    },
  }

  # Lookup vendor specific options for MySQL/MariaDB.
  $_defaults_vendor = lookup("${module_name}::${vendor_type}::default_options", { default_value => {} })
  $_defaults_vendor_version = lookup("${module_name}::${vendor_type}::${vendor_version_internal}::default_options", { default_value => {} })
  # Merge results, the version-specific values take precedence.
  $_default_pre = deep_merge($_defaults_vendor, $_defaults_vendor_version)
  # Now merge the vendor specific options with the global default values.
  $_default_tmp = deep_merge($default_options, $_default_pre)

  # XXX: The following is sort-of a compatibility layer. It passes all options
  # to the inline_epp() function. This way it is possible to use the values of
  # module parameters in MySQL/MariaDB options by specifying them in epp syntax.
  $wsrep_sst_auth_real = inline_epp($wsrep_sst_auth)
  $_default_options = $_default_tmp.reduce({}) |$memo, $x| {
    # A nested hash contains the configuration options.
    if ($x[1] =~ Hash) {
      $_values = $x[1].reduce({}) |$m,$y| {
        # epp expects a string, so skip all other types.
        if ($y[1] =~ String) {
          $_v = inline_epp($y[1])
        } else {
          $_v = $y[1]
        }
        $m + { $y[0] => $_v }
      }
    } else {
      $_values = $x[1]
    }
    $memo + { $x[0] => $_values }
  }
  $_override_options = $override_options.reduce({}) |$memo, $x| {
    # A nested hash contains the configuration options.
    if ($x[1] =~ Hash) {
      $_values = $x[1].reduce({}) |$m,$y| {
        # epp expects a string, so skip all other types.
        if ($y[1] =~ String) {
          $_v = inline_epp($y[1])
        } else {
          $_v = $y[1]
        }
        $m + { $y[0] => $_v }
      }
    } else {
      $_values = $x[1]
    }
    $memo + { $x[0] => $_values }
  }
  # Finally merge options from all 3 sources.
  $options = $_default_options.deep_merge($_wsrep_cluster_address.deep_merge($override_options))

  # Manage MySQL/MariaDB root user.
  if ($create_root_user =~ Undef) {
    # Automatically determine if we should manage the root user.
    if ($facts['networking']['fqdn'] == $galera_master) {
      # Manage root user only on the galera master.
      $create_root_user_real = true
    } else {
      # Skip manage root user on nodes that are not the galera master since
      # they should get a database with the root user already configured when
      # they sync from the master.
      $create_root_user_real = false
    }
  } else {
    # Use user-specified or default value.
    $create_root_user_real = $create_root_user
  }

  # Skip MySQL account management while startup is intentionally deferred.
  if $mysql_start_deferred {
    $create_root_user_effective = false
    $create_status_user_effective = false
  } else {
    $create_root_user_effective = $create_root_user_real
    $create_status_user_effective = $create_status_user
  }

  if $configure_repo {
    # Ensure that repos are setup before trying to install packages.
    $_packages_require = [Class['galera::repo']]
    include galera::repo
    unless $galera::arbitrator {
      if ($galera::params['galera_package_name']) {
        Class['galera::repo'] -> Package[$galera::params['galera_package_name']]
      }
      Class['galera::repo'] -> Class['mysql::server']
    }
  } else {
    $_packages_require = []
  }

  if $configure_firewall {
    include galera::firewall
  }

  # Include workarounds for Debian-based systems
  if ($facts['os']['family'] == 'Debian') {
    include galera::debian
  }

  # Include workarounds for RedHat-based systems
  if ($facts['os']['family'] == 'RedHat') {
    include galera::redhat
  }

  # Evaluate dependencies before performing package installation
  if $arbitrator {
    $_packages_before = [Class['galera::arbitrator']]
  } else {
    if ($bootstrap_permitted) {
      $_packages_before = [
        Class['mysql::server::install'],
        Exec['bootstrap_galera_cluster']
      ]
    } else {
      $_packages_before = [
        Class['mysql::server::install']
      ]
    }
  }

  # Install additional packages
  if ($manage_additional_packages and $additional_packages_real) {
    stdlib::ensure_packages($additional_packages_real,
      {
        ensure  => $package_ensure,
        before  => $_packages_before,
        require => $_packages_require,
    })
  }

  # Configure a MySQL/MariaDB cluster node or an Arbitrator?
  if $arbitrator {
    class { 'galera::arbitrator':
      config_file  => $params['arbitrator_config_file'],
      package_name => $params['arbitrator_package_name'],
      service_name => $params['arbitrator_service_name'],
    }
  } else {
    if $status_check {
      # This is expected to be executed when mysql::server has finished
      # and the cluster was successfully bootstrapped. However it should
      # be run prior to galera::validate because it sets up the users that
      # are needed during validation.
      include galera::status

      $_root_my_cnf_before = [
        Class['mysql::server::root_password'],
        Class['galera::status']
      ]
    } else {
      $_root_my_cnf_before = [
        Class['mysql::server::root_password']
      ]
    }

    if $validate_connection and !$mysql_start_deferred {
      include galera::validate
      # Ensure that MySQL server setup is complete, otherwise the service
      # might not be running and validation would fail.
      Class['mysql::server'] -> Class['galera::validate']
    }

    if ($create_root_my_cnf == true and !$mysql_start_deferred) {
      # Check if we can already login with the given password
      $my_cnf = "[client]\r\nuser=root\r\nhost=localhost\r\npassword='${root_password}'\r\n"

      exec { 'create .my.cnf for user root':
        path    => '/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin',
        command => "echo \"${my_cnf}\" > ${facts['root_home']}/.my.cnf",
        onlyif  => [
          "mysql --user=root --password=${root_password} -e 'select count(1);'",
          "test `cat ${facts['root_home']}/.my.cnf | grep -c \"password='${root_password}'\"` -eq 0",
        ],
        require => Service['mysqld'],
        before  => $_root_my_cnf_before,
      }
    }

    # --- MySQL service startup (Galera-specific) ---
    $mysql_service_enabled_real = $mysql_start_deferred ? {
      true    => false,
      default => $service_enabled,
    }

    if $bootstrap_waiting {
      notify { 'galera_bootstrap_waiting':
        message => "Galera: waiting for ${minimum_cluster_size} nodes in PuppetDB before bootstrap. Run puppet agent on all cluster nodes, then retry on ${galera_master}.",
      }
    }

    if $join_waiting {
      notify { 'galera_join_waiting':
        message => 'Galera: no peer addresses known yet; configure galera_servers or wait for PuppetDB discovery, then retry after the bootstrap node is up.',
      }
    }

    # Setup MySQL server with custom parameters.
    class { 'mysql::server':
      create_root_my_cnf => $create_root_my_cnf,
      create_root_user   => $create_root_user_effective,
      override_options   => $options,
      package_ensure     => $package_ensure,
      package_name       => $params['mysql_package_name'],
      purge_conf_dir     => $purge_conf_dir,
      restart            => $mysql_restart,
      root_password      => $root_password,
      service_enabled    => $mysql_service_enabled_real,
      service_name       => $mysql_service_name_effective,
      *                  => $optional_params,
    }

    # Join nodes: block service start until a peer listens on the wsrep port.
    if (!$bootstrap_permitted and !$join_waiting and $_peer_list != '') {
      exec { 'galera_require_cluster_peer':
        command => '/bin/false',
        unless  => "nmap -Pn -p ${wsrep_group_comm_port} ${_peer_list} 2>/dev/null | grep -q '${wsrep_group_comm_port}/tcp open'",
        before  => Class['mysql::server::service'],
        path    => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
      }

      notify { 'galera_join_peer_gate':
        message => "Galera: this node joins the cluster; bootstrap ${galera_master} first, then re-run puppet here.",
      }
    }

    file { $rundir:
      ensure  => directory,
      owner   => 'mysql',
      group   => 'mysql',
      require => Class['mysql::server::install'],
      before  => Class['mysql::server::installdb'],
    }

    # Overrule puppetlabs/mysql default value
    Package<| title == 'mysql_client' |> {
      name => $params['client_package_name']
    }

    # Install galera provider
    package { [$galera::params['galera_package_name']]:
      ensure => $params['galera_package_ensure'],
      before => $_packages_before,
    }

    if ($bootstrap_allowed) {
      # Bootstrap only when permitted by bootstrap_mode and no peer is already up.
      $server_list = join($galera_servers_effective, ' ')

      if ($bootstrap_mode == 'newest' and !$wsrep_state['safe_to_bootstrap'] and $wsrep_state['grastate_present']) {
        exec { 'prepare_galera_bootstrap':
          command => "sed -i 's/^safe_to_bootstrap: 0/safe_to_bootstrap: 1/' ${wsrep_state['grastate_path']}",
          onlyif  => "grep -q '^safe_to_bootstrap: 0' ${wsrep_state['grastate_path']}",
          require => Class['mysql::server::installdb'],
          before  => Exec['bootstrap_galera_cluster'],
          path    => ['/usr/bin', '/bin', '/usr/local/bin'],
        }
      }

      exec { 'bootstrap_galera_cluster':
        command  => $params['bootstrap_command'],
        unless   => "nmap -Pn -p ${wsrep_group_comm_port} ${server_list} | grep -q '${wsrep_group_comm_port}/tcp open'",
        require  => Class['mysql::server::installdb'],
        before   => Service['mysqld'],
        provider => shell,
        path     => '/usr/bin:/bin:/usr/local/bin:/usr/sbin:/sbin:/usr/local/sbin',
      }
    }
  }
}
