# frozen_string_literal: true

require 'spec_helper'

describe 'galera::bootstrap_permitted' do
  let(:fqdn) { 'node01.example.com' }
  let(:galera_master) { 'node01.example.com' }
  let(:cluster_name) { 'testcluster' }
  let(:wsrep_state) do
    {
      'grastate_present' => false,
      'safe_to_bootstrap' => false,
      'bootstrap_seqno' => 0,
    }
  end
  let(:base_args) do
    {
      'bootstrap_mode' => 'initial',
      'fqdn' => fqdn,
      'galera_master' => galera_master,
      'cluster_name' => cluster_name,
      'discover_cluster_members' => false,
      'wsrep_state' => wsrep_state,
      'bootstrap_fact_max_age' => 300,
      'bootstrap_require_fresh_facts' => true,
    }
  end

  it 'returns false when bootstrap is disabled' do
    args = base_args.merge('bootstrap_mode' => 'disabled')
    is_expected.to run.with(args).and_return(false)
  end

  context 'with bootstrap_mode initial' do
    it 'permits bootstrap on galera_master during first install' do
      is_expected.to run.with(base_args).and_return(true)
    end

    it 'denies bootstrap on non-master nodes' do
      args = base_args.merge('fqdn' => 'node02.example.com')
      is_expected.to run.with(args).and_return(false)
    end

    it 'denies bootstrap after the cluster has existed' do
      args = base_args.merge(
        'wsrep_state' => {
          'grastate_present' => true,
          'safe_to_bootstrap' => false,
          'bootstrap_seqno' => 42,
        },
      )
      is_expected.to run.with(args).and_return(false)
    end

    it 'permits bootstrap when safe_to_bootstrap is set' do
      args = base_args.merge(
        'wsrep_state' => {
          'grastate_present' => true,
          'safe_to_bootstrap' => true,
          'bootstrap_seqno' => 0,
        },
      )
      is_expected.to run.with(args).and_return(true)
    end
  end

  context 'with bootstrap_mode newest' do
    let(:fresh_timestamp) { Time.now.utc.iso8601 }
    let(:stale_timestamp) { (Time.now - 1800).utc.iso8601 }

    before(:each) do
      allow(Galera::Puppetdb).to receive(:query).and_return([])
      allow(Galera::Puppetdb).to receive(:query).with(anything, %r{resources\[certname\]}).and_return(
        [
          { 'certname' => 'node01.example.com' },
          { 'certname' => 'node02.example.com' },
        ],
      )
    end

    it 'permits bootstrap on the node with the highest bootstrap_seqno' do
      args = base_args.merge(
        'bootstrap_mode' => 'newest',
        'discover_cluster_members' => true,
        'fqdn' => 'node02.example.com',
        'galera_master' => 'node01.example.com',
        'wsrep_state' => {
          'grastate_present' => true,
          'safe_to_bootstrap' => false,
          'bootstrap_seqno' => 500,
        },
      )
      allow(Galera::Puppetdb).to receive(:query).with(anything, %r{facts\[certname, value, timestamp\]}).and_return(
        [
          { 'certname' => 'node01.example.com', 'value' => { 'bootstrap_seqno' => 498 }, 'timestamp' => fresh_timestamp },
          { 'certname' => 'node02.example.com', 'value' => { 'bootstrap_seqno' => 500 }, 'timestamp' => fresh_timestamp },
        ],
      )

      is_expected.to run.with(args).and_return(true)
    end

    it 'denies bootstrap on a node with stale data' do
      args = base_args.merge(
        'bootstrap_mode' => 'newest',
        'discover_cluster_members' => true,
        'wsrep_state' => {
          'grastate_present' => true,
          'safe_to_bootstrap' => false,
          'bootstrap_seqno' => 498,
        },
      )
      allow(Galera::Puppetdb).to receive(:query).with(anything, %r{facts\[certname, value, timestamp\]}).and_return(
        [
          { 'certname' => 'node01.example.com', 'value' => { 'bootstrap_seqno' => 498 }, 'timestamp' => fresh_timestamp },
          { 'certname' => 'node02.example.com', 'value' => { 'bootstrap_seqno' => 500 }, 'timestamp' => fresh_timestamp },
        ],
      )

      is_expected.to run.with(args).and_return(false)
    end

    it 'denies bootstrap when a peer fact is too old' do
      args = base_args.merge(
        'bootstrap_mode' => 'newest',
        'discover_cluster_members' => true,
        'wsrep_state' => {
          'grastate_present' => true,
          'safe_to_bootstrap' => false,
          'bootstrap_seqno' => 498,
        },
      )
      allow(Galera::Puppetdb).to receive(:query).with(anything, %r{facts\[certname, value, timestamp\]}).and_return(
        [
          { 'certname' => 'node01.example.com', 'value' => { 'bootstrap_seqno' => 498 }, 'timestamp' => fresh_timestamp },
          { 'certname' => 'node02.example.com', 'value' => { 'bootstrap_seqno' => 500 }, 'timestamp' => stale_timestamp },
        ],
      )

      is_expected.to run.with(args).and_return(false)
    end

    it 'uses galera_master as tie-breaker when seqnos are equal' do
      args = base_args.merge(
        'bootstrap_mode' => 'newest',
        'discover_cluster_members' => true,
        'wsrep_state' => {
          'grastate_present' => true,
          'safe_to_bootstrap' => false,
          'bootstrap_seqno' => 500,
        },
      )
      allow(Galera::Puppetdb).to receive(:query).with(anything, %r{facts\[certname, value, timestamp\]}).and_return(
        [
          { 'certname' => 'node01.example.com', 'value' => { 'bootstrap_seqno' => 500 }, 'timestamp' => fresh_timestamp },
          { 'certname' => 'node02.example.com', 'value' => { 'bootstrap_seqno' => 500 }, 'timestamp' => fresh_timestamp },
        ],
      )

      is_expected.to run.with(args).and_return(true)
    end
  end
end
