# ReleaseManager

This gem provides workflow automations around releasing and deploying puppet modules within r10k environments.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'release_manager'
```

or the following if you don't have a gemserver

```ruby
gem 'release_manager', git: 'git@nr1plvgit01.gcs.frb.org:devops/release_manager.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install release_manager

## Usage

Release manager provides the following commands to help you release and deploy puppet code.

### release-mod
The `release-mod` command will help you release new module and r10k-control repo code by doing the following
1. increment the version in the metadata.json file version field
2. increment the version in the changelog file
3. create a commit with the above changes
4. create a git tag with the name as the version ie. v0.1.4
5. push the changes and tag to the upstream repo using the metadata.json's source field

```
Usage: release-mod [options]

Summary: Bumps the module version to the next revision and
         updates the changelog.md file with the new
         version by reading the metadata.json file. This should
         be run inside a module directory.

    -d, --dry-run                    Do a dry run, without making changes
    -a, --auto                       Run this script without interaction
    -m, --module-path                The path to the module, defaults to current working directory
    -b, --no-bump                    Do not bump the version in metadata.json
    -r, --repo [REPO]                The repo to use, defaults to repo found in the metadata source
        --verbose                    Extra logging
```

### deploy-mod
The `deploy-mod` command assists you with updating an r10k environment with the new module version by doing the following.
1. search the r10k-control repo's Puppetfile for a module with a similar name of the current module
2. removes the branch or ref argument from the "mod" declaration
3. adds a tag argument with the latest version defined in the module's metadata.json file.

You can also optionally pass in the `--commmit` flag to create a commit.  

Additonally if you wish to push the current branch you can also
pass in the `--push` and `--remote git@nr1plvgit01.gcs.frb.org:cosman/r10k-control` option.

```
Usage: deploy-mod [options]

Summary: Gets the version of your module found in the metadata
         and populates the r10k-control Puppetfile with the updated
         tag version. Revmoes any branch or ref reference and replaces
         with tag.  Currently it is up to you to commit and push the Puppetfile change.

    -p, --puppetfile PUPPETFILE      Path to R10k Puppetfile, defaults to ~/repos/r10k-control/Puppetfile
    -m, --modulepath MODULEPATH      Path to to module, defaults to: /home/p1cxom2/repos/release_manager
    -c, --commit                     Commit the Puppetfile change
    -u, --push                       Push the changes to the remote
    -r, --remote REMOTE              Remote name or url to push changes to
```

### bump-changelog
The `bump-changelog` command simply changes 'Unreleased' section with the version string found the in the module's metadata file
and creates a new 'Unrelease Section on top
1. increment version in changelog
2. create commit with change

If using the `release-mod` command there is no need to run the `bump-changelog`command as it is part of the process already.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on https://nr1plvgit01.gcs.frb.org/devops/release_manager.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

