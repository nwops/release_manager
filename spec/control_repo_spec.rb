require 'spec_helper'

describe ControlRepo do
  let(:r10k_path) do
    File.join(fixtures_dir, 'r10k-control')
  end

  let(:reference) do
    Rugged::Reference.new
  end

  let(:repo) do
    ControlRepo.new(r10k_path)
  end

  before(:all) do

  end

  before(:each) do

    #allow_any_instance_of(Rugged::Repository).to receive(:create_branch).and_return(reference)
  end

  after(:all) do
    #`rm -rf #{File.join(fixtures_dir, 'r10k-control')}/.git`
  end

  it 'works' do
    expect(repo).to be_a(ControlRepo)
  end

  it 'create branch' do
    expect(repo.create_branch('my_sandbox')).to be_a(Rugged::Reference)
  end

  it 'puppetfile' do
    expect(repo.puppetfile).to be_a(Puppetfile)
  end
end
