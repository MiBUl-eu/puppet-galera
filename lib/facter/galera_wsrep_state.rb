# frozen_string_literal: true

require Pathname.new(__FILE__).dirname.join('util', 'galera_wsrep')

# Exposes local Galera wsrep state used for safe bootstrap decisions.
Facter.add(:galera_wsrep_state) do
  confine { Facter.value(:kernel) != 'windows' }

  setcode do
    data_directory = GaleraWsrep.datadir
    grastate = GaleraWsrep.grastate_path(data_directory)
    valid = GaleraWsrep.grastate_valid?(grastate)
    state = GaleraWsrep.parse_grastate(grastate)

    {
      'datadir' => data_directory,
      'grastate_path' => grastate,
      'grastate_present' => valid,
      'seqno' => state.fetch('seqno', -1),
      'safe_to_bootstrap' => state.fetch('safe_to_bootstrap', false),
      'uuid' => state['uuid'],
      'bootstrap_seqno' => GaleraWsrep.bootstrap_seqno(state),
    }
  rescue StandardError => e
    Facter.debug("galera_wsrep_state failed: #{e.message}")
    nil
  end
end
