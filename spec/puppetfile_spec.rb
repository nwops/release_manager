require 'spec_helper'

describe Puppetfile do
  let(:path) do
    File.join(fixtures_dir, 'r10k-control')
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

end
