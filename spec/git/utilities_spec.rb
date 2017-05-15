require 'spec_helper'
require 'release_manager/git/credentials'

describe ReleaseManager::Git::Utilities do
  include ReleaseManager::Git::Utilities
  include ReleaseManager::Logger


  let(:path) do
    File.join(fixtures_dir, 'r10k-control')
  end

  before(:each) do
    repo.remotes.delete('source') if remote_exists?('source')
  end

  it '#git_url?' do
    expect(git_url?('git@someserver.example.com:group/project.git')).to be_truthy
  end

  it '#remote_from_url' do
    expect(remote_from_url('git@someserver.example.com:group/project.git')).to be nil
  end

  it '#find_or_create_remote' do
    expect(find_or_create_remote('git@someserver.example.com:group/project.git')).to be_an_instance_of(Rugged::Remote)
  end

  it '#find_or_create_remote with name' do
    expect(find_or_create_remote('upstream')).to be_an_instance_of(Rugged::Remote)
  end

  it '#find_or_create_remote with name and no url' do
    expect(find_or_create_remote('upstream3')).to be nil
    expect(remote_exists?('upstream3')).to be_falsey
  end

  it '#find_or_create_remote with find' do
    expect(find_or_create_remote('git@someserver.example.com:group/project.git')).to be_an_instance_of(Rugged::Remote)
  end

  it 'create commit' do
    require 'pry'; binding.pry
    File.write()
    expect(create_commit('fancy new message')).to match(/\b[0-9a-f]{5,40}\b/)
  end
end