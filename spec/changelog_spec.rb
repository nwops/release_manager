require 'spec_helper'

describe Changelog do
  let(:path) do
    File.join(fixtures_dir, 'puppet-debug')
  end

  let(:changelog_file) do
    File.join(path, 'CHANGELOG.md')
  end

  let(:version) do
    '0.1.2'
  end

  let(:log) do
    Changelog.new(path, version)
  end

  describe 'No ChangeLog' do
    it 'check_requirements' do
      expect{Changelog.check_requirements(path)}.to_not raise_error(NoChangeLogFile)
    end
  end

  describe 'ChangeLog' do
    let(:changelog_file) do
      File.join(fixtures_dir, 'changelog_with_unreleased.md')
    end

    before(:each) do
      allow_any_instance_of(Changelog).to receive(:changelog_file).and_return(changelog_file)
    end

    it 'check_requirements' do
      expect{Changelog.check_requirements(path)}.to_not raise_error
    end

    describe 'has unreleased line' do
      it 'check_requirements' do
        expect{Changelog.check_requirements(path)}.to_not raise_error
      end
      it 'can find index' do
        expect(log.unreleased_index).to eq(2)
      end
      it 'updates line' do
        result = ["# Module name\n",
                  "\n",
                  "## Unreleased\n",
                  "\n## Version 0.1.2\nReleased: July 20, 2018\n",
                  "\n",
                  " * Fixes bug 1\n",
                  " * Fixes bug 2\n",
                  " \n",
                  "## Version 3.2\n",
                  " * fixed all the problems\n",
                  " * fixed even more issues\n",
                  " \n",
                  "## Version 3.1\n",
                  "\n",
                  " * did stuff"]
        expect(log.update_unreleased).to eq(result)
      end

    end

    describe 'already released' do
      let(:version) do
        '3.2'
      end
      it 'returns true' do
        expect(log.already_released?).to eq(true)
      end

      it '#get_version_contents for version' do
        expect(log.get_version_content(version)).to eq([" * fixed all the problems\n",
                                                        " * fixed even more issues\n", " \n"])
      end

      it '#unreleased content' do
        expect(log.get_unreleased_content).to eq(["\n", " * Fixes bug 1\n", " * Fixes bug 2\n", " \n"])
      end

      it '#get_version_contents for 3.1' do
        expect(log.get_version_content('3.1')).to eq(["\n", " * did stuff"])
      end

      it '#get_version of invalid version' do
        expect(log.get_version_content('2.9')).to eq(nil)
      end
    end

    describe 'not already released' do
      let(:version) do
        '9.0'
      end
      it 'returns true' do
        expect(log.already_released?).to eq(false)
      end
    end

    describe 'no unreleased line' do
      let(:changelog_file) do
        File.join(fixtures_dir, 'changelog_without_unreleased.md')
      end
      it 'check_requirements' do
        expect{Changelog.check_requirements(path)}.to raise_error(NoUnreleasedLine)
      end
    end
  end



  it 'works' do
    #require 'pry'; binding.pry
  end
end