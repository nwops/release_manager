require 'spec_helper'
require 'release_manager/git/credentials'

describe ReleaseManager::Git::Credentials do
  let(:manager) do
    ReleaseManager::Git::Credentials.new
  end

  let(:url) do
    'https://github.com/puppetlabs/puppetlabs-stdlib'
  end

  it 'works' do
    expect(manager).to be_a(ReleaseManager::Git::Credentials)
  end

  it 'private_key' do
    #Rugged::Credentials::SshKey:0x007faca8a8c968 @username="git", @publickey=nil, @privatekey="/Users/cosman/.ssh/id_rsa", @passphrase=nil
    expect(manager.ssh_key_credentials(url)).to be_a(Rugged::Credentials::SshKey)

  end

  it 'ssh_agent' do
    expect(manager.ssh_agent_credentials).to be_a(Rugged::Credentials::SshKeyFromAgent)
  end
end