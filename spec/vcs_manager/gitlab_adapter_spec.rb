require 'spec_helper'
require 'release_manager/git/credentials'

describe 'gitlab apdapter' do
  include ReleaseManager::Git::Utilities
  include ReleaseManager::VCSManager
  include ReleaseManager::Logger

  let(:path) do
    File.join(fixtures_dir, 'r10k-control')
  end

  let(:diff_obj) do
    src = '9bfc0adb6200d1da7c7161091820da6d32844cc4'
    dest = 'f44882011791a4499a9818c1842ff00064e6034f'
    create_diff_obj(dest, src)
  end

  it 'vcs' do
    expect(vcs).to be_a(ReleaseManager::VCSManager::VcsAdapter)
    expect(vcs).to be_a(ReleaseManager::VCSManager::GitlabAdapter)
  end

  it 'create merge request' do
    obj_hash = double(Gitlab::ObjectifiedHash)
    allow(obj_hash).to receive(:web_url).and_return('http://web/devops/r10k-control')
    allow(vcs).to receive(:repo_id).and_return(22)
    allow(vcs).to receive(:name_to_id).and_return(22)
    allow(vcs.client).to receive(:create_merge_request).with(22, 'This is a title', {:source_branch=>"dev", :target_branch=>"qa"}).and_return(obj_hash)
    options = { source_branch: 'dev', target_branch: 'qa'}
    expect(vcs.create_merge_request('22', 'This is a title', options)).to eq(obj_hash)
  end

  it 'diff2commit' do
    result = [{:action=>"delete", :file_path=>"changed_file.rb", :content=>nil},
              {:action=>"create", :file_path=>"changed_file2.rb", :content=>"dsfasd\n"}]
    expect(vcs.diff_2_commit(diff_obj)).to eq(result)
  end

end
