require 'spec_helper'

describe PModule do
  let(:path) do
    File.join(fixtures_dir, 'puppet-debug')
  end

  let(:args) do

  end

  let(:mod) do
    PModule.new('apache', { git: 'https://github.com/puppetlabs/puppetlabs-apache', branch: 'docs'})
  end

  it 'works' do
    expect(mod).to be_a(PModule)
  end

  it 'can bump version' do
    mod.version = 'v0.0.1'
    before = mod.version
    mod.bump_patch_version
    after = mod.version
    expect(before).to_not eq(after)
    expect(after).to eq(before.next)
  end

  it 'bump_patch_version' do
    mod.version = 'v0.0.1'
    mod.bump_patch_version
    expect(mod.metadata.key?(:branch)).to eq(false)
    expect(mod.version).to eq('v0.0.2')
  end

  it 'do not bump_patch_version when version does not exist' do
    mod.bump_patch_version
    expect(mod.metadata.key?(:branch)).to eq(true)
    expect(mod.metadata.key?(:tag)).to eq(false)
    expect(mod.version).to eq(nil)
  end

  it 'pin version' do
    mod.pin_version('v0.0.1')
    expect(mod.metadata.key?(:branch)).to eq(false)
    expect(mod.version).to eq('v0.0.1')
  end
end
