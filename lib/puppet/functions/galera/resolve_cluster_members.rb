# frozen_string_literal: true

require Pathname.new(__FILE__).dirname.join('../../../galera/puppetdb').to_s

# Resolves Galera cluster member IP addresses from PuppetDB, static
# configuration, and the running cluster configuration on the node.
Puppet::Functions.create_function(:'galera::resolve_cluster_members') do
  dispatch :resolve do
    param 'Boolean', :discover_cluster_members
    param 'Optional[Array]', :galera_servers
    param 'String', :local_ip
    param 'String', :cluster_name
    param 'Optional[String]', :puppetdb_query_string
    param 'String', :puppetdb_ip_fact
    param 'Integer', :minimum_cluster_size
    param 'Boolean', :puppetdb_require_minimum_size
    param 'Boolean', :puppetdb_empty_query_safeguard
    param 'Array', :existing_cluster_members
    return_type 'Hash'
  end

  def resolve(
    discover_cluster_members,
    galera_servers,
    local_ip,
    cluster_name,
    puppetdb_query_string,
    puppetdb_ip_fact,
    minimum_cluster_size,
    puppetdb_require_minimum_size,
    puppetdb_empty_query_safeguard,
    existing_cluster_members
  )
    configured = normalize_members(galera_servers)
    existing = normalize_members(existing_cluster_members)
    discovered = discover_cluster_members ? query_puppetdb(
      cluster_name,
      puppetdb_query_string,
      puppetdb_ip_fact,
    ) : []

    candidates = (configured + discovered + existing + [local_ip]).uniq.sort

    if puppetdb_empty_query_safeguard && discover_cluster_members && discovered.empty?
      fallback = (configured + existing + [local_ip]).uniq.sort
      candidates = fallback unless fallback.empty?
    end

    if candidates.empty?
      raise Puppet::ParseError,
            'galera::resolve_cluster_members: no cluster members could be resolved. ' \
            'Set galera_servers and/or enable discover_cluster_members with a working PuppetDB query.'
    end

    discovered_with_local = (discovered + [local_ip]).uniq
    cluster_ready = !discover_cluster_members ||
                    !puppetdb_require_minimum_size ||
                    discovered_with_local.length >= minimum_cluster_size

    {
      'members' => candidates,
      'cluster_ready' => cluster_ready,
    }
  end

  def normalize_members(members)
    Array(members).map(&:to_s).reject(&:empty?).uniq.sort
  end

  def query_puppetdb(cluster_name, puppetdb_query_string, puppetdb_ip_fact)
    query = puppetdb_query_string || default_puppetdb_query(cluster_name, puppetdb_ip_fact)
    results = Galera::Puppetdb.query(self, query)
    extract_ips(results, puppetdb_ip_fact)
  rescue Puppet::ParseError
    raise
  rescue StandardError => e
    raise Puppet::ParseError,
          "galera::resolve_cluster_members: PuppetDB query failed: #{e.message}"
  end

  def default_puppetdb_query(cluster_name, puppetdb_ip_fact)
    escaped_cluster_name = cluster_name.gsub('\\', '\\\\').gsub('"', '\\"')
    <<~PQL.gsub(/\s+/, ' ').strip
      facts[value] {
        name = "#{puppetdb_ip_fact}" and
        certname in resources[certname] {
          (type = "Class" and title = "Galera" and
           parameters.cluster_name = "#{escaped_cluster_name}")
          or
          (type = "Class" and title = "galera" and
           parameters.cluster_name = "#{escaped_cluster_name}")
        }
      }
    PQL
  end

  def extract_ips(results, puppetdb_ip_fact)
    results.flat_map do |row|
      if row.is_a?(Hash)
        if row.key?('value')
          row['value']
        elsif row.key?(puppetdb_ip_fact)
          row[puppetdb_ip_fact]
        elsif row.values.length == 1
          row.values.first
        end
      else
        row
      end
    end.compact.map(&:to_s).reject(&:empty?).uniq.sort
  end
end
