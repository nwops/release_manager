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
end
