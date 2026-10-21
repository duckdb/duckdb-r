# CRAN

How a release reaches CRAN, and the policy constraints the tree
lives under year-round.
Only the current line ships to CRAN, as `duckdb`;
every other flavor publishes to r-universe and has no CRAN tail
([`branches/flavors/`](/handbook/branches/flavors/README.md)).
Where submission sits in the release sequence is
[`process/`](/handbook/operations/releases/process/README.md).

**Before submitting:**
the release branch `cran-X.Y.Z` is what gets checked and submitted.
The engine's version and source id, which extension downloads rely on,
are committed in the vendored tree, so a tarball built from any checkout of that branch carries them.
Pushing a `cran-*` branch triggers
[`rhub.yaml`](/.github/workflows/rhub.yaml) for R-hub's platforms,
[`release-gate.yaml`](/.github/workflows/release-gate.yaml) for the mechanical release checks,
and, when the push adds or changes it,
[`winbuilder.yaml`](/.github/workflows/winbuilder.yaml),
which uploads the tarball to WinBuilder against R-devel.
Run by hand, `winbuilder.yaml` also takes R-release and R-oldrelease; every upload mails the `cre` address.
Apart from the known package-size NOTE, every error, warning, and note is a blocker.

**Submitting:**
[`cran-submission.yaml`](/.github/workflows/cran-submission.yaml),
run by hand on the release branch with the input `confirmation` set to `CONFIRM`,
tags the commit as `vX.Y.Z` with its `NEWS.md` section, then checks the package and uploads it to CRAN.
[`cran-comments.md`](/cran-comments.md) is the comment that goes with the upload:
the name and version submitted, that the CRAN Repository Policy was reviewed at its stated revision date,
and what the CRAN check page showed and what became of it.
It is rewritten for each release, and `.Rbuildignore` keeps it out of the tarball.
Without it, the submission action sends a generic note of its own.
It carries no backreference to this leaf, because its whole text reaches a CRAN maintainer verbatim.
The `cre` address in `DESCRIPTION` receives the confirmation mail,
and the upload is not queued until it is answered.
Acceptance is asynchronous — days, overlapping the next cycle —
so the release is tagged and published to r-universe without
waiting; a rejection is fixed on the release branch and
resubmitted as a follow-up patch, never rolled back.

**Policy the tree obeys all year:**
no warning suppression
([`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md)),
no heavy tests or examples on the check farm
([`testing/guards/`](/handbook/testing/guards/README.md)),
tarball size watched at release,
and a maintainer reachable at the `cre` address.
The authoritative list is CRAN's
[Repository Policy](https://cran.r-project.org/web/packages/policies.html).
