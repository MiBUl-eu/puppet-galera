# frozen_string_literal: true

require 'time'
require Pathname.new(__FILE__).dirname.join('../../../galera/puppetdb').to_s

# Determines whether this node may automatically bootstrap a Galera cluster.
Puppet::Functions.create_function(:'galera::bootstrap_permitted') do
  dispatch :permitted do
    param "Enum['disabled', 'initial', 'newest']", :bootstrap_mode
    param 'String', :fqdn
    param 'String', :galera_master
    param 'String', :cluster_name
    param 'Boolean', :discover_cluster_members
    param 'Hash', :wsrep_state
    param 'Integer', :bootstrap_fact_max_age
    param 'Boolean', :bootstrap_require_fresh_facts
    return_type 'Boolean'
  end

  def permitted(
    bootstrap_mode,
    fqdn,
    galera_master,
    cluster_name,
    discover_cluster_members,
    wsrep_state,
    bootstrap_fact_max_age,
    bootstrap_require_fresh_facts
  )
    case bootstrap_mode
    when 'disabled'
      false
    when 'initial'
      initial_bootstrap_permitted?(fqdn, galera_master, wsrep_state)
    when 'newest'
      newest_bootstrap_permitted?(
        fqdn,
        galera_master,
        cluster_name,
        discover_cluster_members,
        wsrep_state,
        bootstrap_fact_max_age,
        bootstrap_require_fresh_facts,
      )
    end
  end

  def initial_bootstrap_permitted?(fqdn, galera_master, wsrep_state)
    return false unless fqdn == galera_master
    return true unless wsrep_state['grastate_present']

    wsrep_state['safe_to_bootstrap'] == true
  end

  def newest_bootstrap_permitted?(
    fqdn,
    galera_master,
    cluster_name,
    discover_cluster_members,
    wsrep_state,
    bootstrap_fact_max_age,
    bootstrap_require_fresh_facts
  )
    unless discover_cluster_members
      raise Puppet::ParseError,
            'galera::bootstrap_permitted: bootstrap_mode "newest" requires discover_cluster_members => true'
    end

    local_seqno = wsrep_state['bootstrap_seqno'].to_i
    return false if local_seqno.negative?

    cluster_certnames = query_cluster_certnames(cluster_name)
    cluster_facts = query_cluster_wsrep_facts(cluster_name)

    if bootstrap_require_fresh_facts && !all_cluster_facts_fresh?(
      cluster_certnames,
      cluster_facts,
      fqdn,
      bootstrap_fact_max_age,
    )
      return false
    end

    cluster_seqnos = cluster_facts.transform_values { |fact| fact['bootstrap_seqno'].to_i }
    cluster_seqnos[fqdn] = local_seqno

    known_seqnos = cluster_seqnos.values.reject(&:negative?)
    return false if known_seqnos.empty?

    max_seqno = known_seqnos.max
    return false if local_seqno < max_seqno

    tied_certnames = cluster_seqnos.select { |_certname, seqno| seqno == max_seqno }.keys.sort
    winner = tied_certnames.include?(galera_master) ? galera_master : tied_certnames.first

    fqdn == winner
  end

  def all_cluster_facts_fresh?(cluster_certnames, cluster_facts, local_fqdn, bootstrap_fact_max_age)
    cluster_certnames.all? do |certname|
      if certname == local_fqdn
        true
      else
        fact = cluster_facts[certname]
        fact && fact_fresh?(fact['timestamp'], bootstrap_fact_max_age)
      end
    end
  end

  def fact_fresh?(timestamp, bootstrap_fact_max_age)
    return false if timestamp.nil? || timestamp.to_s.empty?

    age_seconds = Time.now - Time.parse(timestamp.to_s)
    age_seconds <= bootstrap_fact_max_age
  rescue ArgumentError
    false
  end

  def query_cluster_certnames(cluster_name)
    escaped_cluster_name = cluster_name.gsub('\\', '\\\\').gsub('"', '\\"')
    query = <<~PQL.gsub(/\s+/, ' ').strip
      resources[certname] {
        (type = "Class" and title = "Galera" and
         parameters.cluster_name = "#{escaped_cluster_name}")
        or
        (type = "Class" and title = "galera" and
         parameters.cluster_name = "#{escaped_cluster_name}")
      }
    PQL

    results = Galera::Puppetdb.query(self, query)
    results.filter_map do |row|
      next unless row.is_a?(Hash)

      row['certname']
    end.uniq
  rescue StandardError => e
    raise Puppet::ParseError,
          "galera::bootstrap_permitted: PuppetDB cluster certname query failed: #{e.message}"
  end

  def query_cluster_wsrep_facts(cluster_name)
    escaped_cluster_name = cluster_name.gsub('\\', '\\\\').gsub('"', '\\"')
    query = <<~PQL.gsub(/\s+/, ' ').strip
      facts[certname, value, timestamp] {
        name = "galera_wsrep_state" and
        certname in resources[certname] {
          (type = "Class" and title = "Galera" and
           parameters.cluster_name = "#{escaped_cluster_name}")
          or
          (type = "Class" and title = "galera" and
           parameters.cluster_name = "#{escaped_cluster_name}")
        }
      }
    PQL

    results = Galera::Puppetdb.query(self, query)
    facts = {}

    results.each do |row|
      next unless row.is_a?(Hash)

      certname = row['certname']
      value = row['value']
      next if certname.nil? || value.nil?

      state = value.is_a?(Hash) ? value : {}
      seqno = state['bootstrap_seqno']
      next if seqno.nil?

      facts[certname] = {
        'bootstrap_seqno' => seqno.to_i,
        'timestamp' => row['timestamp'],
      }
    end

    facts
  rescue StandardError => e
    raise Puppet::ParseError,
          "galera::bootstrap_permitted: PuppetDB wsrep fact query failed: #{e.message}"
  end
end
