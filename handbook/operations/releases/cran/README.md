# CRAN

How a release reaches CRAN, and the policy constraints the tree
lives under year-round.
Only the current line ships to CRAN, as `duckdb`;
every other flavor publishes to r-universe and has no CRAN tail
([`branches/flavors/`](/handbook/branches/flavors/README.md)).
Where submission sits in the release sequence is
[`process/`](/handbook/operations/releases/process/README.md).

**Before submitting:**
the tarball is built from `duckdb/duckdb@main` rather than from a
fork — take it from the upstream R workflow's `r-package-source`
artifact or the post-CI release asset, so the embedded revision
ids for extension downloads are right.
Upload it to WinBuilder against R-devel;
apart from the known package-size NOTE, every error, warning, and
note is a blocker.
Pushing a `cran-*` branch triggers
[`rhub.yaml`](/.github/workflows/rhub.yaml) for R-hub's platforms.

**Submitting:**
<https://cran.r-project.org/submit.html>, with the tarball and a
short note in the form's comment field —
the name and version submitted, and that the CRAN Repository Policy
was reviewed at its stated revision date.
No `cran-comments.md` is kept in the repository,
and `.Rbuildignore` keeps a locally written one out of the tarball.
The `cre` address in `DESCRIPTION` receives the confirmation mail,
and the upload is not queued until it is answered.
Acceptance is asynchronous — days, overlapping the next cycle —
so the release is tagged and published to r-universe without
waiting; a rejection is fixed on the release branch and
resubmitted as a follow-up patch, never rolled back.

**Policy the tree obeys all year:**
no warning suppression
([`architecture/glue/`](/handbook/architecture/glue/README.md)),
no heavy tests or examples on the check farm
([`testing/guards/`](/handbook/testing/guards/README.md)),
tarball size watched at release,
and a maintainer reachable at the `cre` address.
The authoritative list is CRAN's
[Repository Policy](https://cran.r-project.org/web/packages/policies.html).
