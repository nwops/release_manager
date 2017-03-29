require 'spec_helper'

describe Release do
  let(:options) do
    {
      path: File.join(fixtures_dir, 'puppet-debug')
    }
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

  describe 'requirements' do
    describe 'invalid metadata' do
      it 'upstream does not match' do
        allow_any_instance_of(Changelog).to receive(:changelog_file).and_return(changelog_file)
        allow_any_instance_of(PuppetModule).to receive(:source).and_return('git@github.com:puppetlabs/puppet-debug')
        allow_any_instance_of(PuppetModule).to receive(:git_upstream_url).and_return('git@gitlab.com:puppetlabs/puppet-debug')
        expect(release).to receive(:exit)
        expect{release.check_requirements}.to output(/The upstream remote url does not match the source url in the metadata.json source/).to_stdout
      end

      it 'invalid source' do
        allow_any_instance_of(Changelog).to receive(:changelog_file).and_return(changelog_file)
        allow_any_instance_of(PuppetModule).to receive(:source).and_return('https://www.github.com/puppet.git')
        expect(release).to receive(:exit)
        expect{release.check_requirements}.to output(/The module\'s metadata source is invalid, please fix it/).to_stdout
      end
    end

    describe 'valid metadata' do

    end
  end


end