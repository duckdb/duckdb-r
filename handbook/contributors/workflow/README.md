# Workflow

Making a change, from branch to merged pull request.
Little of this is codified; what is settled:

* Branch from `main`, open the pull request against `main`;
  it merges without a merge commit
  ([`branches/invariants/`](/handbook/branches/invariants/README.md)).
* Write the pull request title as a
  [Conventional Commit](https://www.conventionalcommits.org),
  phrased to be read:
  it is what squashes onto `main`,
  and fledge turns that history into `NEWS.md`
  ([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
  The commit messages inside the branch are discarded.
* Run the tests the change touches
  ([`testing/suite/`](/handbook/testing/suite/README.md));
  the full suite can also be left to CI.
  Add a test with every bug fix.
* Formatting is suggested on the PR by CI;
  accept it rather than arguing with it.
  A snapshot the change legitimately moved is accepted deliberately
  ([`testing/snapshots/`](/handbook/testing/snapshots/README.md)).
* Never edit generated or vendored files
  ([`architecture/`](/handbook/architecture/README.md),
  [`operations/vendoring/`](/handbook/operations/vendoring/README.md)).

The review side — what gets checked, who drives CI — is
[`operations/review/`](/handbook/operations/review/README.md).

*To deepen: write the path from lived practice,
including how a contributor without push access gets CI green.*
