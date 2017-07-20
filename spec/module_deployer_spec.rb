require 'spec_helper'

describe ModuleDeployer do
  let(:path) do
    File.join(fixtures_dir, 'puppet-debug')
  end

  let(:options) do
    {
        puppetfile: File.join(fixtures_dir, 'puppetfile.txt'),
        modulepath: File.join(fixtures_dir, 'puppet-debug'),
        commit: false,
        push: false,
        remote: nil,
        dry_run: true,
        auto: true
    }
  end

  let(:upstream) { "git@github.com:nwops/puppet-debug" }

  let(:puppetmodule) do
    PuppetModule.new(path)
  end

  let(:puppetfile) do
    Puppetfile.new(options[:puppetfile])
  end

  let(:deployer) do
    ModuleDeployer.new(options)
  end

  it 'works' do
    expect(deployer).to be_a(ModuleDeployer)
  end

  describe 'real run' do
    let(:options) do
      {
          puppetfile: File.join(fixtures_dir, 'r10k-control', 'Puppetfile'),
          modulepath: File.join(fixtures_dir, 'puppet-debug'),
          commit: true,
          push: true,
          remote: 'git@github.com/nwops/something.git',
          dry_run: false,
          auto: true
      }
    end

    it 'creates file' do
      allow_any_instance_of(Rugged::Remote).to receive(:push).and_return(true)
      allow(puppetmodule).to receive(:latest_tag).and_return('v0.1.3')
      allow(deployer).to receive(:puppet_module).and_return(puppetmodule)
      expect(deployer.puppetfile).to receive(:write_to_file).at_least(:once)
      expect{deployer.run}.to_not raise_error
    end

    it 'can run' do
      allow_any_instance_of(PuppetModule).to receive(:source).and_return(options[:remote])
      allow_any_instance_of(Puppetfile).to receive(:current_branch).and_return('dev')
      allow_any_instance_of(Puppetfile).to receive(:commit).and_return(true)
      allow_any_instance_of(Puppetfile).to receive(:push).and_return(true)
      allow_any_instance_of(Puppetfile).to receive(:write_version).and_return(true)
      allow_any_instance_of(Puppetfile).to receive(:write_to_file).and_return(true)
      allow(puppetmodule).to receive(:latest_tag).and_return('v0.1.3')
      allow(deployer).to receive(:puppet_module).and_return(puppetmodule)
      deployer.run
    end

  end

  describe 'real run without push' do
    let(:options) do
      {
          puppetfile: File.join(fixtures_dir, 'r10k-control', 'Puppetfile'),
          modulepath: File.join(fixtures_dir, 'puppet-debug'),
          commit: true,
          push: false,
          remote: 'git@github.com/nwops/something.git',
          dry_run: false,
          auto: true
      }
    end

    it do
      allow_any_instance_of(Puppetfile).to receive(:current_branch).and_return('dev')
      allow_any_instance_of(Puppetfile).to receive(:commit).and_return(true)
      allow_any_instance_of(Puppetfile).to receive(:push).and_return(true)
      allow_any_instance_of(Puppetfile).to receive(:write_version).and_return(true)
      allow_any_instance_of(Puppetfile).to receive(:write_to_file).and_return(true)
      allow(puppetmodule).to receive(:latest_tag).and_return('v0.1.3')
      allow(deployer).to receive(:puppet_module).and_return(puppetmodule)
      deployer.run
    end

  end

  describe 'real run without push and commit' do
    let(:options) do
      {
          puppetfile: File.join(fixtures_dir, 'r10k-control', 'Puppetfile'),
          modulepath: File.join(fixtures_dir, 'puppet-debug'),
          commit: false,
          push: false,
          remote: 'git@github.com/nwops/something.git',
          dry_run: false,
          auto: true
      }
    end

    it do
      allow_any_instance_of(Puppetfile).to receive(:current_branch).and_return('dev')
      allow_any_instance_of(Puppetfile).to receive(:write_version).and_return(true)
      allow_any_instance_of(Puppetfile).to receive(:write_to_file).and_return(true)
      allow(puppetmodule).to receive(:latest_tag).and_return('v0.1.3')
      allow(deployer).to receive(:puppet_module).and_return(puppetmodule)
      allow_any_instance_of(Rugged::Remote).to receive(:push)
      deployer.run
    end

  end

  describe 'dry run' do
    let(:options) do
      {
          puppetfile: File.join(fixtures_dir, 'r10k-control', 'Puppetfile'),
          modulepath: File.join(fixtures_dir, 'puppet-debug'),
          commit: true,
          push: true,
          remote: 'git@github.com/nwops/something.git',
          dry_run: true,
          auto: true
      }
    end

    it 'can run' do
      allow_any_instance_of(Puppetfile).to receive(:current_branch).and_return('dev')
      allow(puppetmodule).to receive(:latest_tag).and_return('v0.1.3')
      allow(deployer).to receive(:puppet_module).and_return(puppetmodule)
      expect{deployer.run.to match(%r{Found module debug with version: v0.1.3})}
      expect{deployer.run.to match(%r{Would have updated module debug in Puppetfile})}
      expect{deployer.run.to match(%r{Would have just pushed branch: dev to remote: git@github.com/nwops/something.git})}
    end
  end
end
