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
[`cran-submission.yaml`](/.github/workflows/cran-submission.yaml) runs only when started by hand,
from the Actions tab or with `gh workflow run cran-submission.yaml --repo duckdb/duckdb-r --ref <ref>`,
and submits the commit that ref points to.
It first stops on a development version, one with more than three components such as `1.99.99.9001`,
unless it was dispatched with the input `allow-dev-version`.
It then drafts the GitHub release `duckdb X.Y.Z` with the `NEWS.md` section as its notes, or updates the draft already there,
and stops instead if that release is published.
It tags the commit as `vX.Y.Z` with the same section,
and [`scripts/cran-submit.sh`](/scripts/cran-submit.sh) builds the tarball with `R CMD build`,
recompresses it with zopfli (`pigz -11`, about 5% smaller than the gzip R writes),
and verifies that it passes `gzip -t` and holds the same tar stream as the original.
The run keeps that tarball as an artifact named `<package>_<version>`,
and the script then posts it to CRAN's submission form and confirms the submission, as `devtools:::upload_cran()` does.
The comment that goes with the upload is the single line `<package> <version>`, such as `duckdb 2.0.0`, and nothing more.
The workflow neither checks the package nor asks for a confirmation:
the commit has a green build before it is released,
and the confirmation is the mail CRAN sends to the `cre` address in `DESCRIPTION`,
whose link has to be followed before the upload is queued.
Each stage reports what it did on the run's summary page, and a failure says how to resolve it there;
[`scripts/cran-submit-test.sh`](/scripts/cran-submit-test.sh) checks both stages offline, the upload against a fake form.
With the input `dry-run` (`-f dry-run=true`), a run tags, drafts and sends nothing:
after the same version check, the tag job prints the release and the tag it would write, and whether it would update a draft or move a tag,
and the submission job builds, verifies and keeps the tarball as a real run does,
then lists every field the upload would post, under a banner on the summary page that says it was a dry run.
Acceptance is asynchronous — days, overlapping the next cycle —
so the release is tagged and published to r-universe without
waiting; a rejection is fixed on the release branch and
resubmitted as a follow-up patch, never rolled back.

**Publishing the release:**
the draft's notes end with the marker `<!-- cran-submission: duckdb X.Y.Z -->`, which GitHub does not render,
and every night [`cran-release.yaml`](/.github/workflows/cran-release.yaml) runs [`scripts/cran-release.sh`](/scripts/cran-release.sh)
on the drafts that carry it with the tag `vX.Y.Z`.
A draft is published, as the latest release,
once the source index of <https://packagemanager.posit.co/cran/latest> lists the package at that version,
the test `fledge:::release_after_cran_built_binaries()` made in `fledge.yaml` before
([`versioning/`](/handbook/operations/releases/versioning/README.md)),
and only if the tag exists and points at the commit the draft targets; a missing or moved tag fails the run with how to resolve it.
A version not listed yet is one line on the summary page, and the run stays green.
Started by hand, the workflow takes the input `dry-run`, which publishes nothing and says what it would publish;
[`scripts/cran-release-test.sh`](/scripts/cran-release-test.sh) checks the script against a fake package manager and a stubbed `gh`.

**Policy the tree obeys all year:**
no warning suppression
([`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md)),
no heavy tests or examples on the check farm
([`testing/guards/`](/handbook/testing/guards/README.md)),
tarball size watched at release,
and a maintainer reachable at the `cre` address.
The authoritative list is CRAN's
[Repository Policy](https://cran.r-project.org/web/packages/policies.html).
