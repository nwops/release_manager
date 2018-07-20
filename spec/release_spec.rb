require 'spec_helper'

describe Release do
  let(:options) do
    {
      path: File.join(fixtures_dir, 'puppet-debug'),
      auto: true
    }
  end

  before(:each) do
    allow_any_instance_of(Changelog).to receive(:changelog_file).and_return(changelog_file)
  end

  let(:release) do
    Release.new(options[:path], options)
  end

  let(:changelog_file) do
    File.join(fixtures_dir, 'changelog_with_unreleased.md')
  end


  it 'works' do
    expect(release).to be_a(Release)
  end

  describe 'r10k-control' do
    let(:options) do
      {
          path: File.join(fixtures_dir, 'r10k-control'),
          auto: true
      }
    end

    it 'does nothing if already released' do
      allow(release.puppet_module).to receive(:already_latest?).and_return(true)
      expect{release.check_requirements}.to raise_error(AlreadyReleased)
    end

    it 'returns true if not already released' do
      allow(release.puppet_module).to receive(:already_latest?).and_return(false)
      expect(release.check_requirements).to eq(2)
    end

    it '#release_notes' do
      expect(release.release_notes).to eq("\n  * Fixes bug 1\n  * Fixes bug 2\n  \n")
    end

  end

  describe 'module' do
    let(:options) do
      {
          path: File.join(fixtures_dir, 'puppet-debug'),
          auto: true
      }
    end

    describe 'requirements' do
      describe 'invalid metadata' do
        it 'upstream does not match' do
          allow(release.puppet_module).to receive(:source).and_return('git@github.com:puppetlabs/puppet-debug')
          allow(release.puppet_module).to receive(:git_upstream_url).and_return('git@gitlab.com:puppetlabs/puppet-debug')
          allow(release).to receive(:add_upstream_remote).and_return(true)
          expect(release).to receive(:check_requirements).once
          expect(release.logger).to_not receive(:fatal).with(/The upstream remote url does not match the source url in the metadata.json source/)
          release.check_requirements
        end

        it 'invalid source' do
          allow(release.puppet_module).to receive(:source).and_return('https://www.github.com/puppet.git')
          expect(release).to receive(:check_requirements).once
          expect(release.logger).to_not receive(:fatal).with(/source field must be a git url/)
          release.check_requirements
        end
      end
    end
  end


end