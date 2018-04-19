# Release Manager

## Unreleased
## 0.8.3
 * Fixes issue when git urls with hypens not being found

## 0.8.2
 * Fixes #7 - sandbox-create hangs when ssh does not have host id key
 * Fixes #6 - sandbox-create hangs when ssh-agent does not have a key/id
 * Fixes #10 - Add better error handling with a token is not set
 * Add MERGE_REQUEST_URL environment variable when creating a MR for r10k
## 0.8.1
 * Improves error handling when tags already exist
 * Fixes #12 - deploy-r10k does not write a patch file
## 0.8.0
 * Allows for creating sandboxes from different targets
 * Allow for releasing one off patches with release-mod
 * Fixes #11 - release-mod should show which variables to set
## 0.7.0
 * Fixes #3 - release-mod fails when trying to sort tags
 * Fixes #8 - files disappear from change set
 * Fixes #1 - deploy-mod creates commit everytime
## 0.6.0
 * Adds the ability to release-mod to dump a specific SemVer release level
 * Fixes issue with changelog file not existing

## 0.5.3

 * Fixes output when applying patch

## 0.5.2

 * Adds proper error handling when missing git author name and email with r10k-deploy

## 0.5.1
 * Fixes missing error object when credentials are not present
 * Fixes error when deploy-r10k is used and remote setting was not set
## 0.5.0
 * Adds more error handling instead of stack dumps
 * Updates gitlab gem to 4.2
 * Updates rugged gem to 0.26
 * Adds deploy-r10k cli command
 * Refactors more git commands to use rugged
 * Adds ability to run deploy-mod  without interaction
 * Moves gitlab methods to gitlab adapter
 * Adds support to create merge request
 * Adds ability to remote create a commit with the changelog
 * Adds ability to calculate changes files between two refs
## v0.4.0
 * Adds ability to sort the puppetfile when writing to file
## v0.3.1
 * Adds ability to add the module to the puppetfile at deployment time
## v0.3.0
 * Fixes color with fatal errors
 * Changes PuppetModule to use rugged commit commands
 * Auto corrects bad source attribute with metadata.json
 * Adds new methods to git utilities
 * Fixes error when fetching remotes that do not exist
 * Fixes issue where pushing of remotes via url failed
 * Adds automatic fetching or remote before creating branch from remote
 * Fixes #11 - Add output during dry run for deploy-mod
## v0.2.4
 * Fixes puppetfile not return instance of controlmod
## v0.2.3
 * Allows the user to add new modules when they don't already exist
 * Sets the upstream url based on the module source defined in metadata
## v0.2.2
 * Fixes issue when existing branch exists on remote but not local
 * improves docker setup
 * Fixes issue where module branch was not pushed
## v0.2.1
 * Improves docker setup
 * Removes ability to push upon deploying module
 * Fixes issue with git source not updating when deploying module
 * Refactors cli into individual files
 * Removes checking of modules before sandbox creation

## v0.2.0
 * adds the ability to auto generate a complete r10k sandbox
 * adds gitlab adapter
 * adds rugged git dependency
## v0.1.8
 * Fix pinning of version to puppetfile
 * adds more testing

## v0.1.7
 * Adds more tests
 * Fixes typos
 * Fixes issue with push and commit during deployment
 * Fixes stack level issue when calling upstream
 * Adds ability to easily add upstream remote
## v0.1.6
 * add dry run to deploy-mod

## v0.1.5
 * Fixes an issue where the latest tag was not being selected correctly

## v0.1.4
 * Fixes #8 - upstream does not exist
 * Fixes #9 - bump changelog assumes changelog exists
 * Fixes #10 - executable scripts should communicate options more clearly

## v0.1.0
* initial implementation
