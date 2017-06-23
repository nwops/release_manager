```shell

__________       .__                                   _____                                             
\______   \ ____ |  |   ____ _____    ______ ____     /     \ _____    ____ _____     ____   ___________ 
 |       _// __ \|  | _/ __ \\__  \  /  ___// __ \   /  \ /  \\__  \  /    \\__  \   / ___\_/ __ \_  __ \
 |    |   \  ___/|  |_\  ___/ / __ \_\___ \\  ___/  /    Y    \/ __ \|   |  \/ __ \_/ /_/  >  ___/|  | \/
 |____|_  /\___  >____/\___  >____  /____  >\___  > \____|__  (____  /___|  (____  /\___  / \___  >__|   
        \/     \/          \/     \/     \/     \/          \/     \/     \/     \//_____/      \/       
```

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [ReleaseManager](#releasemanager)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
    - [Install directly from source](#install-directly-from-source)
  - [The workflow problem](#the-workflow-problem)
    - [R10k Sandbox Creation Steps (the hard way)](#r10k-sandbox-creation-steps-the-hard-way)
    - [R10k Sandbox Creation steps (the easy way)](#r10k-sandbox-creation-steps-the-easy-way)
  - [Usage](#usage)
    - [sandbox-create](#sandbox-create)
    - [release-mod](#release-mod)
    - [deploy-mod](#deploy-mod)
    - [bump-changelog](#bump-changelog)
  - [Configuration Settings](#configuration-settings)
    - [Sandbox-create environment variables](#sandbox-create-environment-variables)
  - [Ssh agent usage](#ssh-agent-usage)
  - [Development](#development)
  - [Contributing](#contributing)
  - [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# ReleaseManager

This gem provides workflow automations around releasing and deploying puppet modules within r10k environments.

## Prerequisites 

1. Must be running Gitlab 9.0+
2. Must be using ssh keys with gitlab
3. Must be using ssh-agent to handle git authentication
4. Must be using Git
5. Must be using r10k
6. Must have a r10k-control repo (name can vary)
7. Must have a Gitlab API Access token (per user)
8. Must have the libssh-dev library package installed

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'release_manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install release_manager
    
### Install directly from source
If you don't have access to a gem server you can use the `specific_install` gem.  This will install the latest version
directly from source.

```
gem install specific_install  # unless already installed
gem specific_install https://github.com/nwops/release_manager  
```


## The workflow problem
R10k allows us to create a puppet environment for each branch on the r10k-control repository. This makes isolating code deployments
simple to use because each branch corresponds to a puppet environment.  However, this workflow implies that you will fork
all the modules you work on and create branches on those forks.  Additionally, you then need to update the r10k-control Puppetfile
to use those new branches and forks.  This can be a huge burden and consume some of your time.  Below is an example of that workflow.

### R10k Sandbox Creation Steps (the hard way)
1. fork r10k-control
2. clone r10k-control fork
3. create new branch called my_sandbox on r10k-control fork
4. Decide which module(s) you need to work on  (ie. roles, profiles, sqlserver) for a given sandbox (branch)
5. Fork the roles repo
6. Fork the profiles repo
7. Fork the sqlserver repo
8. Clone all three of the forked repos above
9. Create a branch called my_sandbox on each of the repos above
10. Update the puppetfile in r10k-control to use your fork and branch for each module above
11. Commit the puppetfile
12. Push the commit to the r10k-control
13. Add the upstream remote for all of the repos you just cloned
14. Add members to your forked projects
15. push new branch on each forked project

Yikes!  This is a long list of things to do.  It is human nature to skip some or all of these steps to save time even though
it is in our best interest to follow these steps.  As humans we will always resort to the path of least resistance. 

In an effort to force good practices and reduce time and effort, release-manager will automate almost all of the tasks into 
a single command called `sandbox-create`.

Additionally there are other commands that help with the release and deploy process of modules to the r10k-control repository.

### R10k Sandbox Creation steps (the easy way)
`sandbox-create -n my_sandbox --modules='roles,profiles,hieradata,sqlserver'`  

## Usage

Release manager provides the following commands to help you create sandboxes, release and deploy puppet code.

### sandbox-create
The sandbox-create command wraps all the git, git cloning, and git forking tasks into a single command.  Usage of this command
will save you a great deal of time upon each run.

Please note: this requires the usage of [ssh-agent](#ssh-agent-usage). 


```
Usage: sandbox-create [options]

Summary: Creates a new r10k sandbox by forking and creating a new branch on r10k-control,
         creates a fork and branch for each module passed in, adds the upstream remote
         for each module, updates the r10k-control Puppetfile to use those forks and branches
         and pushes the branch to the upstream r10k-control.

Example: sandbox-create -n my_sandbox -m "roles,profiles,developer"
Example: sandbox-create -n my_sandbox -m "roles,profiles,developer" --members="p1dksk2, p2ksdafs,devops,ci_runner" 


Note: If you already have any of these modules cloned, this script will attempt to update those modules
      using git fetch and git checkout -b sandbox_name upstream/master.  So this should not destroy anything.

        --members DEFAULT_MEMBERS    A comman seperated list of members to add to forked projects
    -n, --name NAME                  The name of your sandbox
        --control-url R10K_REPO_URL  git url to the r10k-control repo, defaults to R10K_CONTROL_URL env variable
    -m, --modules MODULES            A comma separated list of modules names from the Puppetfile to fork and branch
    -r, --repos-dir [REPOS_PATH]     The repos path to clone modules to. Defaults to: /home/appuser/repos
    -c, --control-dir [CONTROL_DIR]  The r10k-control repo path. Defaults to: /home/appuser/repos/r10k-control
        --verbose                    Extra logging


```

Example Run

```shell
appuser@28523330e507:/app$ export DEFAULT_MODULES=gitlab 
appuser@28523330e507:/app$ export DEFAULT_MEMBERS=r10k_user,ci_runner
appuser@28523330e507:/app$ sandbox-create -n sdafsd -m r10k

INFO - ReleaseManager: Resetting upstream remote to git@web:cosman/control-repo.git for /home/appuser/repos/r10k-control
INFO - ReleaseManager: Fetching upstream from git@web:cosman/control-repo.git
INFO - ReleaseManager: Resetting upstream remote to git@web:devops/control-repo.git for /home/appuser/repos/r10k-control
INFO - ReleaseManager: Fetching upstream from git@web:devops/control-repo.git
INFO - ReleaseManager: Checking out branch: upstream/dev for /home/appuser/repos/r10k-control
INFO - ReleaseManager: Fetching upstream from git@web:cosman/r10k.git
INFO - ReleaseManager: Fetching upstream from git@web:cosman/r10k.git
INFO - ReleaseManager: Updating r10k-control Puppetfile to use fork: git@web:cosman/r10k.git with branch: sdafsd
INFO - ReleaseManager: Adding member r10k_user to project cosman/puppet-gitlab
INFO - ReleaseManager: Adding member ci_runner to project cosman/puppet-gitlab
INFO - ReleaseManager: Resetting upstream remote to git@web:cosman/puppet-gitlab.git for /home/appuser/repos/gitlab
INFO - ReleaseManager: Fetching upstream from git@web:cosman/puppet-gitlab.git
INFO - ReleaseManager: Fetching upstream from git@web:cosman/puppet-gitlab.git
INFO - ReleaseManager: Updating r10k-control Puppetfile to use fork: git@web:cosman/puppet-gitlab.git with branch: sdafsd
INFO - ReleaseManager: Checking out branch: sdafsd for /home/appuser/repos/r10k-control
INFO - ReleaseManager: Committing Puppetfile changes to r10k-control branch: sdafsd

```

**Note: This script assumes you will have the following environment variables set:**

You can throw this in your .bash_profile or .zprofile and have this set automatically for each run.

Example Only:

```
export GITLAB_API_ENDPOINT='http://web/api/v3'
export GITLAB_API_PRIVATE_TOKEN='A_zJJfgE8P-8mFGK2_r9'
export R10K_REPO_URL="git@web:devops/control-repo.git"

```

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
pass in the `--push` and `--remote r10k-control` option.

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


## Configuration Settings
The following environment variables will automatically set required parameters and defaults.  It is suggested you put 
this in your shell script like .bash_profile or .zprofile

### Sandbox-create environment variables

GITLAB_API_ENDPOINT - The api path to the gitlab server (ie. https://gitlab.com/api/v3)

GITLAB_API_PRIVATE_TOKEN - The gitlab user api token 

DEFAULT_MODULES - The default set of modules to use when creating a sandbox  (ie. hieradata)

R10K_REPO_URL - The git repo url to r10k-control (ie. git@gitlab.com:nwops/r10k-control.git)

DEFAULT_MEMBERS - The default members each forked project should add permissions to (ie, 'ci_runner', 'r10k_user')

## Ssh agent usage
In order to use sandbox-create you need to ensure you have ssh-agent running in the background and the following 
environment variables are exported.  In some cases you might have this automated via a shell login script.

* SSH_AUTH_SOCK
* SSH_AGENT_PID

Automated usage

```
#!/usr/bin/env bash
#
# setup ssh-agent
#
# set environment variables if user's agent already exists
[ -z "$SSH_AUTH_SOCK" ] && SSH_AUTH_SOCK=$(ls -l /tmp/ssh-*/agent.* 2> /dev/null | grep $(whoami) | awk '{print $9}')
[ -z "$SSH_AGENT_PID" -a -z `echo $SSH_AUTH_SOCK | cut -d. -f2` ] && SSH_AGENT_PID=$((`echo $SSH_AUTH_SOCK | cut -d. -f2` + 1))
[ -n "$SSH_AUTH_SOCK" ] && export SSH_AUTH_SOCK
[ -n "$SSH_AGENT_PID" ] && export SSH_AGENT_PID

# start agent if necessary
if [ -z $SSH_AGENT_PID ] && [ -z $SSH_TTY ]; then  # if no agent & not in ssh
  eval `ssh-agent -s` > /dev/null
fi

# setup addition of keys when needed
if [ -z "$SSH_TTY" ] ; then                     # if not using ssh
  ssh-add -l > /dev/null                        # check for keys
  if [ $? -ne 0 ] ; then
    alias ssh='ssh-add -l > /dev/null || ssh-add && unalias ssh ; ssh'
    if [ -f "/usr/lib/ssh/x11-ssh-askpass" ] ; then
      SSH_ASKPASS="/usr/lib/ssh/x11-ssh-askpass" ; export SSH_ASKPASS
    fi
  fi
fi

```
Manual Usage

```
ssh-agent bash
ssh-add
# this should prompt for password if your ssh key is protected

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on release_manager.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

