# frozen_string_literal: true

require 'spec_helper'

describe 'galera::resolve_cluster_members' do
  let(:local_ip) { '10.0.0.1' }
  let(:cluster_name) { 'testcluster' }
  let(:base_args) do
    {
      'discover_cluster_members' => false,
      'galera_servers' => ['10.0.0.1', '10.0.0.2', '10.0.0.3'],
      'local_ip' => local_ip,
      'cluster_name' => cluster_name,
      'puppetdb_query_string' => nil,
      'puppetdb_ip_fact' => 'networking.ip',
      'minimum_cluster_size' => 1,
      'puppetdb_require_minimum_size' => true,
      'puppetdb_empty_query_safeguard' => true,
      'existing_cluster_members' => [],
    }
  end

  it 'returns configured servers when discovery is disabled' do
    is_expected.to run.with(base_args).and_return(
      'members' => ['10.0.0.1', '10.0.0.2', '10.0.0.3'],
      'cluster_ready' => true,
    )
  end

  it 'always includes the local IP' do
    args = base_args.merge('galera_servers' => ['10.0.0.2'])
    is_expected.to run.with(args).and_return(
      'members' => ['10.0.0.1', '10.0.0.2'],
      'cluster_ready' => true,
    )
  end

  context 'when PuppetDB discovery is enabled' do
    before(:each) do
      allow(Galera::Puppetdb).to receive(:query).and_call_original
      allow(Galera::Puppetdb).to receive(:query).with(anything, anything).and_return([])
    end

    it 'merges PuppetDB results with configured servers' do
      args = base_args.merge(
        'discover_cluster_members' => true,
        'galera_servers' => ['10.0.0.1'],
      )
      allow(Galera::Puppetdb).to receive(:query).with(anything, anything).and_return(
        [{ 'value' => '10.0.0.2' }, { 'value' => '10.0.0.3' }],
      )

      is_expected.to run.with(args).and_return(
        'members' => ['10.0.0.1', '10.0.0.2', '10.0.0.3'],
        'cluster_ready' => true,
      )
    end

    it 'preserves configured servers when PuppetDB returns no nodes' do
      args = base_args.merge(
        'discover_cluster_members' => true,
        'galera_servers' => ['10.0.0.1', '10.0.0.2', '10.0.0.3'],
      )
      allow(Galera::Puppetdb).to receive(:query).with(anything, anything).and_return([])

      is_expected.to run.with(args).and_return(
        'members' => ['10.0.0.1', '10.0.0.2', '10.0.0.3'],
        'cluster_ready' => false,
      )
    end

    it 'preserves existing cluster members when PuppetDB returns no nodes' do
      args = base_args.merge(
        'discover_cluster_members' => true,
        'galera_servers' => nil,
        'existing_cluster_members' => ['10.0.0.1', '10.0.0.2', '10.0.0.3'],
      )
      allow(Galera::Puppetdb).to receive(:query).with(anything, anything).and_return([])

      is_expected.to run.with(args).and_return(
        'members' => ['10.0.0.1', '10.0.0.2', '10.0.0.3'],
        'cluster_ready' => false,
      )
    end

    it 'keeps partial PuppetDB membership while cluster_ready is false' do
      args = base_args.merge(
        'discover_cluster_members' => true,
        'galera_servers' => nil,
        'minimum_cluster_size' => 3,
      )
      allow(Galera::Puppetdb).to receive(:query).with(anything, anything).and_return(
        [{ 'value' => '10.0.0.2' }],
      )

      is_expected.to run.with(args).and_return(
        'members' => ['10.0.0.1', '10.0.0.2'],
        'cluster_ready' => false,
      )
    end

    it 'marks the cluster ready once minimum_cluster_size is reached' do
      args = base_args.merge(
        'discover_cluster_members' => true,
        'galera_servers' => ['10.0.0.1'],
        'minimum_cluster_size' => 3,
      )
      allow(Galera::Puppetdb).to receive(:query).with(anything, anything).and_return(
        [{ 'value' => '10.0.0.2' }, { 'value' => '10.0.0.3' }],
      )

      is_expected.to run.with(args).and_return(
        'members' => ['10.0.0.1', '10.0.0.2', '10.0.0.3'],
        'cluster_ready' => true,
      )
    end
  end
end
