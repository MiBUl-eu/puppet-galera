# frozen_string_literal: true

# Shared helpers for reading Galera wsrep state from the local node.
module GaleraWsrep
  DEFAULT_DATADIR = '/var/lib/mysql'
  CONFIG_PATHS = [
    '/etc/my.cnf',
    '/etc/mysql/my.cnf',
  ].freeze
  CONFIG_DIRS = [
    '/etc/my.cnf.d',
    '/etc/mysql/conf.d',
    '/etc/mysql/mariadb.conf.d',
  ].freeze

  module_function

  def datadir
    CONFIG_PATHS.each do |path|
      next unless File.readable?(path)

      if (match = File.read(path).match(/^\s*datadir\s*=\s*(\S+)/))
        return match[1].strip
      end
    end

    CONFIG_DIRS.each do |dir|
      next unless File.directory?(dir)

      Dir.glob(File.join(dir, '*.cnf')).each do |path|
        next unless File.readable?(path)

        if (match = File.read(path).match(/^\s*datadir\s*=\s*(\S+)/))
          return match[1].strip
        end
      end
    end

    DEFAULT_DATADIR
  end

  def grastate_path(data_directory = datadir)
    File.join(data_directory, 'grastate.dat')
  end

  def grastate_valid?(path)
    File.file?(path) && File.readable?(path) && !File.zero?(path)
  end

  def parse_grastate(path)
    return {} unless grastate_valid?(path)

    state = {}
    File.read(path).each_line do |line|
      next unless (match = line.match(/^\s*(seqno|safe_to_bootstrap|uuid)\s*:\s*(\S+)/))

      key = match[1]
      value = match[2]
      state[key] = case key
                   when 'seqno' then value.to_i
                   when 'safe_to_bootstrap' then value.to_i == 1
                   else value
                   end
    end
    state
  end

  def bootstrap_seqno(state)
    seqno = state['seqno']
    return seqno if seqno && seqno >= 0

    return 0 if state['safe_to_bootstrap']

    -1
  end
end
