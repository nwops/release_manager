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
    expect(find_or_create_remote('upstream3')).to be false
    expect(remote_exists?('upstream3')).to be_falsey
  end

  it '#find_or_create_remote with find' do
    expect(find_or_create_remote('git@someserver.example.com:group/project.git')).to be_an_instance_of(Rugged::Remote)
  end

  it 'changed files shows new file' do
    src = '0ed81d64c4657303a6a25ec4f5389b7d1572bf03'
    dest = '2ae908405fb47ea5c2bf8f4ee3faa60701250f28'
    files = changed_files(repo.lookup(src), repo.lookup(dest))
    expect(files).to eq(['new_commit.rb'])
  end

  it 'changed files shows files and file method' do
    src = '0ed81d64c4657303a6a25ec4f5389b7d1572bf03'
    dest = 'f44882011791a4499a9818c1842ff00064e6034f'
    files = create_diff_obj(dest, src)
    result = [{:old_path=>"changed_file2.rb",
               :status=>:added,
               :new_path=>"changed_file2.rb",
               :content=>"dsfasd\n"},
              {:old_path=>"new_commit.rb",
               :status=>:added,
               :new_path=>"new_commit.rb",
               :content=>"blsdafsdfds"}]
    expect(files).to eq(result)
  end

  it 'changed files shows files and file method' do
    src = '0ed81d64c4657303a6a25ec4f5389b7d1572bf03'
    dest = '9bfc0adb6200d1da7c7161091820da6d32844cc4'
    files = create_diff_obj(dest, src)
    result = [{:old_path=>"changed_file.rb",
               :status=>:added,
               :new_path=>"changed_file.rb",
               :content=>"dsfasd\n"},
              {:old_path=>"new_commit.rb",
               :status=>:added,
               :new_path=>"new_commit.rb",
               :content=>"blsdafsdfds"}]
    expect(files).to eq(result)
  end

  it 'changed files shows files and file method' do
    src = '9bfc0adb6200d1da7c7161091820da6d32844cc4'
    dest = 'f44882011791a4499a9818c1842ff00064e6034f'
    files = create_diff_obj(dest, src)
    result = [{:old_path=>"changed_file.rb", :status=>:deleted,
               :new_path=>"changed_file.rb", :content=>nil},
              {:old_path=>"changed_file2.rb", :status=>:added,
               :new_path=>"changed_file2.rb", :content=>"dsfasd\n"}]
    expect(files).to eq(result)
  end

  describe '#create_diff' do
    it 'with tag' do
      src = 'v0.0.1'
      dest = 'master'
      diff = create_diff(src, dest)
      expect(diff).to be_a Rugged::Diff
    end

    it 'with branch' do
      src = 'dev'
      dest = 'master'
      diff = create_diff(src, dest)
      expect(diff).to be_a Rugged::Diff
    end

    it 'with ref' do
      src = '9bfc0adb6200d1da7c7161091820da6d32844cc4'
      dest = 'master'
      diff = create_diff(src, dest)
      expect(diff).to be_a Rugged::Diff
    end

    it 'up2date? is true' do
      src = 'dev'
      expect(up2date?(src,src)).to be true
    end

    xit 'up2date? is false' do
      src = 'dev2'
      dest = 'dev'
      expect(up2date?(src,dest)).to be false
    end
  end

  it 'changed files shows files and file method' do
    src = '9bfc0adb6200d1da7c7161091820da6d32844cc4'
    dest = 'f44882011791a4499a9818c1842ff00064e6034f'
    files = create_diff_obj(dest, src)
    result = [{:old_path=>"changed_file.rb", :status=>:deleted,
               :new_path=>"changed_file.rb", :content=>nil},
              {:old_path=>"changed_file2.rb", :status=>:added,
               :new_path=>"changed_file2.rb", :content=>"dsfasd\n"}]
    expect(files).to eq(result)
  end

  it 'can delete branch' do
    create_branch('old_dev', 'dev')
    checkout_branch('old_dev')
    checkout_branch('dev')
    expect(delete_branch('old_dev')).to be true
  end



  # it 'create commit' do
  #   expect(create_commit('fancy new message')).to match(/\b[0-9a-f]{5,40}\b/)
  # end
end