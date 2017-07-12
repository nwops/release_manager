require 'spec_helper'

describe PuppetModule do
  let(:path) do
    File.join(fixtures_dir, 'puppet-debug')
  end

  let(:upstream) { "git@github.com:nwops/puppet-debug" }

  let(:puppetmodule) do
    PuppetModule.new(path)
  end

  it 'works' do
    expect(puppetmodule).to be_a(PuppetModule)
  end

  describe 'invalid metadata' do
    before(:each) do
      allow_any_instance_of(PuppetModule).to receive(:source).and_return('https://github.com/nwops/puppet-debug')
    end
    it 'raise error' do
      expect{PuppetModule.check_requirements(path)}.to raise_error(InvalidMetadataSource)
    end
    it 'raise error when no source' do
      allow_any_instance_of(PuppetModule).to receive(:source).and_return('')
      expect{PuppetModule.check_requirements(path)}.to raise_error(InvalidMetadataSource)
    end
    it 'valid uptream' do
      allow(puppetmodule).to receive(:git_upstream_url).and_return('git@github.com/nwops/something.git')
      expect(puppetmodule.git_upstream_set?).to eq(false)
    end
  end

  describe 'invalid upstream' do
    before(:each) do
      allow_any_instance_of(PuppetModule).to receive(:source).and_return('git@github.com:puppetlabs/puppet-debug')
    end
    it 'raise error' do
      expect{PuppetModule.check_requirements(path)}.to raise_error(UpstreamSourceMatch)
    end
  end

  describe 'valid metadata' do
    before(:each) do
      allow_any_instance_of(PuppetModule).to receive(:git_upstream_url).and_return('git@github.com:nwops/puppet-debug')
      allow_any_instance_of(PuppetModule).to receive(:source).and_return('git@github.com:nwops/puppet-debug')
    end
    it 'not raise error' do
      expect{PuppetModule.check_requirements(path)}.to_not raise_error
    end
    it 'valid uptream' do
      allow(puppetmodule).to receive(:git_upstream_url).and_return(upstream)
      expect(puppetmodule.git_upstream_set?).to eq(true)
    end
  end

  let(:tags) do
    %w{v0.0.1 v0.0.2 v0.0.3 v0.0.10 v0.0.11 0.0.11 0.0.1 v0.0.12}
  end

  it 'return latest tag when not ordered' do
    allow(puppetmodule).to receive(:tags).and_return(tags)
    expect(puppetmodule.latest_tag).to eq('v0.0.12')
  end

  describe 'r10k-control' do
    let(:path) do
      File.join(fixtures_dir, 'r10k-control')
    end

    it 'correct branch' do
      expect(puppetmodule.src_branch).to eq('dev')
    end

    it 'already_latest? returns true' do
      allow(puppetmodule).to receive(:tags).and_return(tags)
      allow(puppetmodule).to receive(:latest_tag).and_return('v0.0.12')
      allow(puppetmodule).to receive(:find_ref).with('v0.0.12').and_return("852852d24923b834b0a8d616fa7322b94bbfbc95")
      allow(puppetmodule).to receive(:find_ref).with('dev').and_return("852852d24923b834b0a8d616fa7322b94bbfbc95")
      expect(puppetmodule.already_latest?).to be true
    end

    it 'already_latest? returns false' do
      allow(puppetmodule).to receive(:tags).and_return(tags)
      allow(puppetmodule).to receive(:latest_tag).and_return('v0.0.12')
      allow(puppetmodule).to receive(:find_ref).with('v0.0.12').and_return("852852d24923b834b0a8d616fa7322b94bbfbc95")
      allow(puppetmodule).to receive(:find_ref).with('dev').and_return("f4d7cec4ce8288a854df67cd7758b0d222a99ff0")
      expect(puppetmodule.already_latest?).to be false
    end
  end

  describe 'module' do
    let(:path) do
      File.join(fixtures_dir, 'puppet-debug')
    end

    it 'correct branch' do
      expect(puppetmodule.src_branch).to eq('master')
    end
  end


end
