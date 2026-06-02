# frozen_string_literal: true

module Galera
  # Helpers for optional PuppetDB integration.
  module Puppetdb
    module_function

    # Run a PQL query via the built-in puppetdb_query function (PuppetDB terminus).
    def query(function_caller, pql)
      function_caller.call_function('puppetdb_query', pql)
    rescue Puppet::ParseError
      raise
    rescue StandardError => e
      raise Puppet::ParseError,
            'Galera PuppetDB query failed: the puppetdb_query function is not available on ' \
            "this Puppet compiler (#{Facter.value(:fqdn)}). PuppetDB must be configured in " \
            'puppet.conf on every server that compiles catalogs (see puppetdb.conf), or set ' \
            'galera_servers and discover_cluster_members => false. ' \
            "Original error: #{e.message}"
    end
  end
end
