# Contributing to Landrush

<!-- MarkdownTOC -->

- [Working on an issue](#working-on-an-issue)
- [Merging pull requests](#merging-pull-requests)
- [Releasing](#releasing)
- [Maintainers](#maintainers)

<!-- /MarkdownTOC -->


The following is a set of guidelines for contributing to Landrush.
These are just guidelines. Please use your best judgment and feel free
to propose changes to this document in a pull request.

At this point, this document is not complete, but as decisions are made
they will be added to this document.

<a name="working-on-an-issue"></a>
## Working on an issue

* All changes should have a matching issue in the GitHub [issue
  tracker](https://github.com/vagrant-landrush/landrush/issues). If
  there is not one, create one.
* Prepend each commit of a proposed change with the GitHub issue number,
  eg `Issue #xyz Fixing foo in bar`
* All changes should be applied to master via [pull
  requests](https://help.github.com/articles/using-pull-requests/)
  (even from maintainers).
* All changes should include documentation updates.
* Small changes need only 1 ACK while larger changes need 2 ACKs from
  maintainers before they will be merged. If the author of the pull
  request is a maintainer, the submission is considered 1 of the
  2 ACKs. Therefore pull requests from maintainers only require one
  additional ACK.

  By "2 ACKs" we mean that 2 maintainers must acknowledge
  that the change is a good one. The 2nd person to ACK the pull
  request should merge the pull request with a comment including their
  agreement. We default to moving forward and using revert if needed.

<a name="merging-pull-requests"></a>
## Merging pull requests

1. The merging committer should merge the pull request as follows. Avoid
   using the GitHub web UI. Instead, perform merges using the `git`
   command line. This avoids merge commits and keeps a linear commit
   history. The commands below demonstrated the suggested process.

       ```
       # Create a local branch for the pull request
       $ git checkout -b <branch-name> master

       # Pull the changes
       $ git pull <remote> <branch-name>

       # If necessary rebase changes on master to ensure we have a fast
       # forward. Also resolve any conflicts
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

Prerequisites:

* Push access to the `landrush` GitHub repository
* Owner of the `landrush` gem Rubygems 

Steps:

1. Update `lib/landrush/version.rb` with the new version number.
1. Update the `CHANGELOG.md` header with the new version number and
   current date.
1. Make a release commit:
   `git add lib/landrush/version.rb CHANGELOG.md; git commit -m 'cut vX.Y.Z'`
1. Make a release tag: `git tag -m vX.Y.Z vX.Y.Z`
1. Push the release commit: `git push origin master; git push origin master --tags`
1. Build the release: `rake build`
1. Push the newly built gem: `gem push pkg/landrush-X.Y.Z.gem`
1. Update the CHANGELOG to add an "Unreleased" section, commit as
   "clean up after vX.Y.Z".

<a name="maintainers"></a>
## Maintainers

* Brian Exelbierd (@bexelbie)
* Eric Sorenson (@ahpook)
* Florian Holzhauer (@fh)
* Hardy Ferentschik (@hferentschik)
* Josef Strzibny (@strzibny)
* Paul Hinze (@phinze)
* Reto Kaiser (@njam)
