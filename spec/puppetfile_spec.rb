require 'spec_helper'

describe Puppetfile do
  let(:path) do
    File.join(fixtures_dir, 'r10k-control')
  end

  let(:mod) do
    ControlMod.new('apache', {repo: 'https://github.com/puppetlabs/puppetlabs-apache', branch: 'docs'})
  end

  let(:upstream) { "git@github.com:nwops/r10k-control" }

  let(:puppetfile) do
    Puppetfile.new(File.join(path, 'Puppetfile'))
  end
  it 'works' do
    expect(puppetfile).to be_a(Puppetfile)
  end

  it 'updates version' do
    before = puppetfile.find_mod('apache1').version
    puppetfile.write_version('apache1', '0.0.8')
    after = puppetfile.find_mod('apache1').version
    expect(before).to_not eq(after)
  end

  it 'outputs correct version' do
    before = puppetfile.find_mod('apache1').version
    puppetfile.write_version('apache1', '0.0.8')
    after = puppetfile.find_mod('apache1').version
    expect(puppetfile.to_s).to match(/0\.0\.8/)
  end

  it 'creates file' do
    before = puppetfile.find_mod('apache1').version
    puppetfile.write_version('apache1', '0.0.8')
    after = puppetfile.find_mod('apache1').version
    expect(puppetfile.to_s).to match(/0\.0\.8/)
    expect(File).to receive(:write).with(puppetfile.puppetfile, puppetfile.to_s ).and_return(true)
    puppetfile.write_to_file
  end

  it 'writes version to the module' do
    allow(puppetfile).to receive(:find_mod).and_return(mod)
    expect(puppetfile.write_version('apache', 'v0.0.8')).to eq('v0.0.8')
    expect(mod.metadata.key?(:branch)).to eq(false)
    expect(mod.metadata.key?(:tag)).to eq(true)
  end

  it 'writes source to the module' do
    allow(puppetfile).to receive(:find_mod).and_return(mod)
    updated_mod = puppetfile.write_source('apache', 'git@github.com:puppetlabs/puppetlabs-apache')
    expect(updated_mod.repo).to eq('git@github.com:puppetlabs/puppetlabs-apache')
  end

  it 'create file with source' do
    before = puppetfile.find_mod('apache1').version
    puppetfile.write_version('apache1', '0.0.8')
    puppetfile.write_source('apache1', 'git@github.com:puppetlabs/puppetlabs-apache' )
    after = puppetfile.find_mod('apache1').version
    expect(puppetfile.to_s).to match(%r{git@github.com:puppetlabs/puppetlabs-apache})
    expect(File).to receive(:write).with(puppetfile.puppetfile, puppetfile.to_s ).and_return(true)
    puppetfile.write_to_file
  end

end
