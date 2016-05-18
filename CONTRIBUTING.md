# Contributing to Landrush

<!-- MarkdownTOC -->

- [Working on an issue](#working-on-an-issue)
- [Merging pull requests](#merging-pull-requests)
- [Releasing](#releasing)
- [Maintainers](#maintainers)

<!-- /MarkdownTOC -->


The following is a set of guidelines for contributing to Landrush.
These are just guidelines, please use your best judgment and feel free
to propose changes to this document in a pull request.

At this point, this document is not complete, but as decisions are made
they will be added to this document.

<a name="working-on-an-issue"></a>
## Working on an issue

* All changes should have a matching issue in the GitHub [issue tracker](https://github.com/vagrant-landrush/landrush/issues). If there is none, create one.
* Prepend each commit of a porposed change with the GitHub issue key, eg `Issue #xyz Fixing foo in bar`
* All changes should be applied to master via [pull requests](https://help.github.com/articles/using-pull-requests/) (even from maintainers).
* All changes should include documentation updates.
* Small changes need only 1 ACK. Larger changes need 2 ACKs from
  maintainers before they will be merged. If the author of the pull request is a
  maintainer, the submission is considered 1 of the 2 ACKs. Therefore pull requests
  from maintainers only require one additional ACK. By "2 ACKs" we mean
  that 2 maintainers must acknowledge that the change is a good one. The
  2nd person to ACK the pull request should merge the pull request with a
  comment including their agreement. We default to moving forward and using
  revert if needed.

<a name="merging-pull-requests"></a>
## Merging pull requests

1. Merging committer should merge the pull request. Avoid using GitHub UI and
   prefer merges over the the command line to avoid merge commits and to keep
   a linear commit history:

       ```
       # Create a local branch for the pull request
       $ git checkout -b <branch-name> master

       # Pull the changes
       $ git pull <remote> <branch-name>

       # If necessary rebase changes on master to ensure we have a fast forward. Also resolve any conflicts
       $ git rebase -i master

       # Merge changes into master
	   $ git checkout master
	   $ git merge <branch-name>

	   # Update changelog in the unreleased section. Commit!

	   # Push to origin
       $ git push origin master
       ```

<a name="releasing"></a>
## Releasing

Prereqs:

* Push access to the `landrush` GitHub repository
* Rubygems owner of the `landrush` gem

Steps:

1. Update `lib/landrush/version.rb` with version number.
1. Update `CHANGELOG.md` header with version number and current date.
1. Make release commit: `git add lib/landrush/version.rb CHANGELOG.md; git commit -m 'cut vX.Y.Z'`
1. Make release tag: `git tag -m vX.Y.Z vX.Y.Z`
1. Push release commit: `git push origin master`
1. Build release: `rake build`
1. Push released gem: `gem push pkg/landrush-X.Y.Z.gem`
1. Update CHANGELOG to add an "Unreleased" section, commit as "clean up after vX.Y.Z".

<a name="maintainers"></a>
## Maintainers

* Brian Exelbierd (@bexelbie)
* Eric Sorenson (@ahpook)
* Florian Holzhauer (@fh)
* Hardy Ferentschik (@hferentschik)
* Josef Strzibny (@strzibny)
* Paul Hinze (@phinze)
* Reto Kaiser (@njam)
