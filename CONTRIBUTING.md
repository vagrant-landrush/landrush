# Contributing to Landrush

The following is a set of guidelines for contributing to Landrush.
These are just guidelines, please use your best judgment and feel free
to propose changes to this document in a pull request.

At this point, this document is not complete, but as decisions are made
they will be added to this document.

## Pull Requests

* All changes should be made by pull request (PR), even from maintainers.
* All changes should include documentation updates.
* Small changes need only 1 ACK. Larger changes need 2 ACKs from
  maintainers before they will be merged. If the author of the PR is a
  maintainer, the submission is considered 1 of the 2 ACKs. Therefore PRs
  from maintainers only require one additional ACK. By "2 ACKs" we mean
  that 2 maintainers must acknowledge that the change is a good one. The
  2nd person to ACK the PR should merge the PR with a comment including
  their agreement.  We default to moving forward and using revert if needed.

## Merging PRs

1. Merging committer should first merge the PR
2. Merging committer should update the changelog in the unreleased
   section.  Using the github web UI is sufficient

## Releasing

Prereqs:

* Push access to the `landrush` GitHub repository
* Rubygems owner of the `landrush` gem

Steps:

1. Update `lib/landrush/version.rb` with version number.
2. Update `CHANGELOG.md` header with version number and current date.
3. Make release commit: `git add lib/landrush/version.rb CHANGELOG.md; git commit -m 'cut vX.Y.Z'`
4. Make release tag: `git tag -m vX.Y.Z vX.Y.Z`
5. Push release commit: `git push origin master`
6. Build release: `rake build`
7. Push released gem: `gem push pkg/landrush-X.Y.Z.gem`
8. Update CHANGELOG to add an "Unreleased" section, commit as "clean up after vX.Y.Z".

## Maintainers

Brian Exelbierd (@bexelbie)
Eric Sorenson (@ahpook)
Florian Holzhauer (@fh)
Hardy Ferentschik (@hferentschik)
Josef Strzibny (@strzibny)
Paul Hinze (@phinze)
Reto Kaiser (@njam)
