# frozen_string_literal: true

# Reads wsrep_cluster_address from existing MySQL/MariaDB configuration so
# PuppetDB discovery can fall back to the running cluster when queries fail.
Facter.add(:galera_cluster_members) do
  confine { Facter.value(:kernel) != 'windows' }

  setcode do
    members = []
    search_paths = [
      '/etc/mysql/conf.d',
      '/etc/my.cnf.d',
      '/etc/mysql/mariadb.conf.d',
    ]
    config_files = search_paths.flat_map do |dir|
      next [] unless File.directory?(dir)

      Dir.glob(File.join(dir, '*.cnf'))
    end
    config_files += ['/etc/my.cnf', '/etc/mysql/my.cnf'].select { |f| File.file?(f) }

    config_files.each do |path|
      next unless File.readable?(path)

      File.read(path).scan(%r{wsrep_cluster_address\s*=\s*gcomm://([^/\s]+)}i) do |match|
        match[0].split(',').each do |entry|
          ip = entry.split(':').first.to_s.strip
          members << ip unless ip.empty?
        end
      end
    end

    members.uniq.sort
  end
end
