require 'spec_helper'
require 'release_manager/sandbox'

describe Sandbox do
  let(:box) do
    Sandbox.new('mybox', ['mod1', 'mod2', 'mod3'],
                r10k_path, '/tmp/repos')
  end

  let(:user) do
  end

  before(:each) do
    user = double(Object)
    allow(user).to receive(:name).and_return('user1')
    allow(Gitlab).to receive(:user).and_return(user)
    allow_any_instance_of(Sandbox).to receive(:repo_exists?).and_return(gitlab_repo)
  end

  let(:r10k_repo) do
    r = Rugged::Repository.init_at(File.join(fixtures_dir, 'r10k-control'))
    r.remotes.create('upstream', 'https://github.com/nwops/r10k-control') unless r.remotes['upstream']
    r
  end

  let(:repository) do
    r = Rugged::Repository.init_at(File.join(fixtures_dir, 'puppet-debug'))
    r.remotes.create('upstream', 'https://github.com/nwops/puppet-debug') unless r.remotes['upstream']
    r
  end

  let(:gitlab_repo) do
    r = double(Gitlab::ObjectifiedHash)
    allow(r).to receive(:ssh_url_to_repo).and_return('git@github.com:puppetlabs/puppetlabs-apache.git')
    r
  end

  let(:options) do
    {
      r10k_repo_url: 'git@github.com:puppetlabs/control-repo.git',
      r10k_repo_path: File.expand_path(File.join(ENV['HOME'], 'repos', 'r10k-control')),
      modules: ['module1', 'module2', 'module3'],
      repos_path: File.expand_path(File.join(ENV['HOME'], 'repos')),
    }
  end

  let(:mod) do
    ControlMod.new('apache', {git: 'git@github.com:puppetlabs/puppetlabs-apache.git', branch: 'docs'})
  end

  let(:r10k_path) do
    File.join(fixtures_dir, 'r10k-control')
  end

  let(:r10k_url) do
    'git@github.com:example42/control-repo.git'
  end

  it 'works' do
    expect(box).to be_a(Sandbox)
  end

  it 'create' do
    allow_any_instance_of(Rugged::Repository).to receive(:create_branch).and_return(Rugged::Branch.new)
    allow_any_instance_of(Rugged::Repository).to receive(:checkout).and_return(Rugged::Branch.new)
    allow(gitlab_repo).to receive(:id).and_return('123')
    expect_any_instance_of(Puppetfile).to receive(:push).with('upstream', 'my_sandbox', true)
    allow_any_instance_of(Sandbox).to receive(:repo_id).and_return('123455')
    allow_any_instance_of(Puppetfile).to receive(:find_mod).and_return(mod)
    allow(Gitlab).to receive(:create_fork).and_return(gitlab_repo)
    allow(Gitlab).to receive(:repo_create_branch).and_return(gitlab_repo)
    allow_any_instance_of(ControlRepo).to receive(:clone).and_return(repository)
    allow_any_instance_of(ControlRepo).to receive(:repo).and_return(r10k_repo)
    allow_any_instance_of(ControlRepo).to receive(:add_remote).and_return(Rugged::Remote.new)
    allow_any_instance_of(ControlRepo).to receive(:fetch).and_return(repository)
    allow_any_instance_of(ControlRepo).to receive(:create_branch).and_return(Rugged::Branch.new)
    allow_any_instance_of(ControlRepo).to receive(:checkout_branch).and_return(Rugged::Branch.new)
    allow_any_instance_of(Sandbox).to receive(:create_repo_fork).and_return(gitlab_repo)
    allow_any_instance_of(Sandbox).to receive(:setup_module_repo).and_return(true)
    allow_any_instance_of(Sandbox).to receive(:check_requirements).and_return(true)
    expect(Sandbox.create('my_sandbox', options)).to be_a(Sandbox)
  end

  it 'fetch repo id' do
    allow(gitlab_repo).to receive(:id).and_return('123')
    allow(Gitlab).to receive(:project_search).with('nwops/project').and_return(gitlab_repo)
    expect(box.repo_id('git@gitlab.com:nwops/project.git')).to eq("nwops%2Fproject")
  end

  it 'setup control repo' do
    allow_any_instance_of(Rugged::Repository).to receive(:create_branch).and_return(Rugged::Branch.new)
    allow_any_instance_of(Rugged::Repository).to receive(:checkout).and_return(Rugged::Branch.new)
    allow_any_instance_of(Sandbox).to receive(:create_repo_fork).and_return(gitlab_repo)
    allow(gitlab_repo).to receive(:ssh_url_to_repo).and_return("git@github.com:example42/control-repo.git")
    allow_any_instance_of(ControlRepo).to receive(:fetch).and_return(repository)
    expect_any_instance_of(ControlRepo).to receive(:clone).with(r10k_url, r10k_path).and_return(true)
    allow_any_instance_of(ControlRepo).to receive(:repo).and_return(r10k_repo)

    expect(box.setup_control_repo(r10k_url)).to be_a(ControlRepo)
  end

  # it 'setup module repo' do
  #   branch = double(Rugged::Branch)
  #   remote_collection = double(Rugged::RemoteCollection)
  #   allow(branch).to receive(:canonical_name).and_return('refs/heads/mybranch')
  #   allow(branch).to receive(:url).and_return("git@github.com:example42/control-repo.git")
  #   allow(branch).to receive(:set_url).and_return("git@github.com:example42/control-repo.git")
  #
  #   allow_any_instance_of(Rugged::Repository).to receive(:create_branch).and_return(Rugged::Branch.new)
  #   allow_any_instance_of(Rugged::Repository).to receive(:checkout).and_return(Rugged::Branch.new)
  #   allow_any_instance_of(Puppetfile).to receive(:find_mod).and_return(mod)
  #   allow_any_instance_of(PuppetModule).to receive(:fetch).and_return(repository)
  #
  #   allow_any_instance_of(PuppetModule).to receive(:repo).and_return(repository)
  #   allow(box).to receive(:create_repo_fork).with(mod.repo).and_return(gitlab_repo)
  #   expect_any_instance_of(PuppetModule).to receive(:clone).with(mod.repo, "/tmp/repos/apache").and_return(true)
  #   allow_any_instance_of(PuppetModule).to receive(:credentials).and_return({})
  #   allow_any_instance_of(Rugged::Repository).to receive(:remotes).and_return(remote_collection)
  #   allow(remote_collection).to receive(:[]).and_return(branch)
  #   allow(remote_collection).to receive(:push).and_return(true)
  #   expect(box.setup_module_repo(mod)).to be_a(PuppetModule)
  #end
  #
  # it 'r10k control repo should have origin and upstream set to same' do
  #
  # end
  #
  # it 'should try to push Puppetfile to upstream sandbox' do
  #
  # end
  #
  # it 'credentials should work with ssh-agent' do
  #
  # end
  #
  # it 'credentials should work with password protected but no ssh agent' do
  #
  # end
  #
  # it 'credentials should work with key only no password' do
  #
  # end
  #
  # it 'when sandbox already exists, and fork of module was deleted, create a new fork based off the dev branch' do
  #
  # end

  # it 'should not create a new local branch when existing remote branch already exists' do
  #   fail
  # end
  #
  # it 'should push branch module to fork' do
  #   fail
  # end

end
