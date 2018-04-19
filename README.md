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
  - [Usage Summary](#usage-summary)
  - [The workflow problem](#the-workflow-problem)
    - [R10k Sandbox Creation Steps (the hard way)](#r10k-sandbox-creation-steps-the-hard-way)
    - [R10k Sandbox Creation steps (the easy way)](#r10k-sandbox-creation-steps-the-easy-way)
  - [Detailed Usage](#detailed-usage)
    - [sandbox-create](#sandbox-create)
    - [release-mod](#release-mod)
    - [deploy-mod](#deploy-mod)
    - [bump-changelog](#bump-changelog)
  - [Common Workflows](#common-workflows)
    - [Creating releases](#creating-releases)
    - [Creating one off releases](#creating-one-off-releases)
  - [Configuration Settings](#configuration-settings)
    - [Sandbox-create environment variables](#sandbox-create-environment-variables)
  - [Ssh agent usage](#ssh-agent-usage)
  - [Development](#development)
  - [Develpment Environment Setup](#develpment-environment-setup)
    - [Setting up your Gitlab Instance](#setting-up-your-gitlab-instance)
    - [Configure your release manager client](#configure-your-release-manager-client)
    - [Testing the cli commands](#testing-the-cli-commands)
    - [Debugging](#debugging)
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
9. Must tag code with version tags ie. `v1.2.3`
10. Must keep a CHANGELOG.md

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'release_manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install release_manager
    

Release Manager depends on the Rugged gem which requires compilation and a few OS dependencies.

### Ubnutu / Debian
apt-get update && apt-get install libgit2-21 cmake libssh-dev

### RedHat Based
yum install cmake libssh2 libssh2-devel git
    
### Install directly from source
If you don't have access to a gem server you can use the `specific_install` gem.  This will install the latest version
directly from source.

```
gem install specific_install  # unless already installed
gem specific_install https://github.com/nwops/release_manager  
```

## Usage Summary
There are several cli utilities bundled with the gem, each one can be used independently of the other.  Detailed usage can be
found further below in this document.

* `sandbox-create -n my_sandbox`  - Sandbox creation and module repo forking (most popular)
* `deploy-mod`  - (module) Deploy the latest version of your mod to r10k-control Puppetfile
* `deploy-mod`  - (r10k repo) Deploy the latest version (tags) of your r10k-control repo branch to other branches
* `deploy-r10k` - Deploying your r10k repo to other branches in the same repo using merge requests
* `release-mod`  - Increments version, tags, updates changelog and releases version to gitlab
* `bump-changelog` - for directly manipulating the changelog

## Automating the release process
Over the last few years I have adapted the build->release->deploy process to r10k environments. This is done by
treating all puppet modules as separate projects, and r10k-control as the AIO (all in one) project the encomposes all the modules.

Where as most people would only merge the changes from one branch to the production branch, Release Manager expects there are multiple stages to pass in order to get to production.  This greatly reduces risk and follows a similar process to traditional software development.

Release Manager enforces this process and will version the r10k-control repo just like a module.  Once that version is released, the version is then deployed to the other puppet environments by merging only the differences between the two branches.  This is done purposely as we will be assured that the contents of v0.1.1 have been deployed to the dest branch (qa, staging, and production).  Additionally, you can have multiple versions in flight at any given time.  So a typical scenario can be something like:

 - feature_branch ( dev + feature/bugfix)
 - dev (bleeding edge)
 - qa (v1.1.5)
 - staging (v1.1.4)
 - production (v1.0.0)
 
Because most people are accustomed to this release process, it becomes easy to trace where changes are at any given moment. Keeping a changelog in r10k-control helps immensely as well.

Futhermore, if you realize a problem with v1.1.4 and need a hotfix, just create a branch `git checkout -b hotfix upstream/v1.1.4` apply the fix, and release a new version.  They deploy the hotfix to any branch you desire.

Keep in mind releases are immutable.  So once you create a release, you have to cut another release to deploy any changes.  This is by design so that you always know what is deployed.
 
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
it is in our best interest to follow these steps.  Most humans we will always resort to the path of least resistance. 

In an effort to force good practices and reduce time and effort, release-manager will automate almost all of the tasks into 
a single command called `sandbox-create`.

Additionally there are other commands that help with the release and deploy process of modules to the r10k-control repository.

### R10k Sandbox Creation steps (the easy way)
`sandbox-create -n my_sandbox --modules='roles,profiles,hieradata,sqlserver'`  

## Detailed Usage

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


Note: If you already have any of these modules cloned, this script will attempt to update those modules
      using git fetch and git checkout -b sandbox_name upstream/master.  So this should not destroy anything.

Configuration:

This script uses the following environment variables to automatically set some options, please ensure 
they exist in your shell environment.  You can set an environment variable in the shell or define 
in your shell startup files.

Shell:  export VARIABLE_NAME=value

R10K_REPO_URL            - The git repo url to r10k-control (ie. git@gitlab.com:devops/r10k-control.git)
GITLAB_API_ENDPOINT      - The api path to the gitlab server  (ie. https://gitlab_server/api/v3)
                           replace gitlab_server with your server hostname
GITLAB_API_PRIVATE_TOKEN - The gitlab user api token.  
                           You can get a token here (http://web/profile/personal_access_tokens, 
                           Ensure api box is checked.
DEFAULT_MODULES          - The default set of modules to fork use when 
                           a sandbox (ie. export DEFAULT_MODULES='hieradata, roles')

DEFAULT_MEMBERS          - The default members each forked project should add permissions
                           to ( ie, DEFAULT_MEMBERS='ci_runner,r10k_user' )

If your gitlab server has a invalid certificate you can set the following variable to "fix" that trust issue.
export GITLAB_API_HTTPARTY_OPTIONS="{verify: false}"

Examples:
  sandbox-create -n my_sandbox -m "roles,profiles,developer" 
  sandbox-create -n my_sandbox -m "roles,profiles,developer" --members="p1dksk2,devops,ci_runner"
  sandbox-create -n my_sandbox -s "upstream/v0.5.0" 

Options:
        --members DEFAULT_MEMBERS    A comman seperated list of members to add to forked projects
    -n, --name NAME                  The name of your sandbox
    -s, --src-target REMOTE/REF      The source of the target to create your sandbox from, defaults to upstream/dev
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
    -l, --level			     Semantic versioning level to bump (major.minor.patch), defaults to patch
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

## Common Workflows
### Creating releases
You worked hard on your code and now you want to release your software for others to enjoy.
Follow the steps below to version your code before deployment.  This these changes are considered major
we want to create a 2.0.0 release.

1. run `release-mod -l major` from the root of the module directory (use `-d` for a dry run)

That's it, all you need to do is run that command.  Note, by design you are not allowed to enter a version number.  Release Manager
uses the version in metadata.json file as a reference and increments to semver identifiers. 


### Creating one off releases

1. Did you deploy a release all the way to production only to find a bug?
2. Do you want to skip all other deployment stages with your patch?

Follow the steps below to create a new patch release and deploy straight to production

1. Create a new sandbox based on the branch or tag you want to fix. `sandbox-create -s upstream/v0.5.0 -n patch_0.5.1`
2. cd ~/repos/r10k-control
3. Make your changes in that branch and update the changelog
4. Push your code to the remote Git repo and activate your CI pipeline (recommended)
5. Release the new version `release-mod -l patch -s patch_0.5.1`  (creates tag v0.5.1 from the sandbox)
6. Deploy the patch release to production `deploy-r10k -s v0.5.1 -d production`

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


## Develpment Environment Setup
### Setting up your Gitlab Instance
1. Ensure you have docker and docker-compose installed
2. run `docker-compose up` to start all the services
3. Visit http://localhost:8000/
4. Create a password  (password123)
5. Login (root/password123)
6. Create a user account for yourself (add Admin role)
7. Logout as Admin and login as the new user account
10. Create a `.env` file in the repo directory and paste these contents in it
  ```ruby
GITLAB_API_ENDPOINT='http://web/api/v4'
GITLAB_API_PRIVATE_TOKEN='your token goes here'
R10K_REPO_URL="git@web:devops/control-repo.git"

  ```
11. Create an Personal Access Token (API) token for your user account
12. Replace the token in your .env file

### Configure your release manager client
1. run `docker-compose run client`
2. From the container run source .env
3. From client container `source .bash_profile`
4. Add the ~/.ssh/id_rsa.pub key to your gitlab account
5. From the new client container session, run `bundle exec bash app_startup_script.sh`
6. From the client container, run `bundle exec ruby setup_repos.rb`
7. From the client container attempt to connect to the git server and accept the key `ssh git@web`
8. Test to ensure you can clone a repository inside the container `git clone git@web:devops/docker.git /tmp/docker`

### Testing the cli commands
1. `bundle exec exe/sandbox-create -n my_sandbox -m docker`  # example
2. `bundle exec exe/release-mod --level minor -m ~/repos/docker`

### Debugging
if you cannot connect to the gitlab server via ssh you see errros about private key 
has wrong permission you will need to do the following:

`chmod 600 srv/gitlab/config/ssh_host_ecdsa_key srv/gitlab/config/ssh_host_ed25519_key srv/gitlab/config/ssh_host_rsa_key`

If the sandbox create command freezes after the first output make sure you can connect
to the git server using git clone or running `ssh-add` to add your ssh key to the ssh agent.

## Contributing

Bug reports and pull requests are welcome on release_manager.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

