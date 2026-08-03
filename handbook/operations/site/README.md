# The site

The package's public documentation at <https://r.duckdb.org/>,
built by pkgdown from the reference pages the package already ships
([`meta/handbook/`](/handbook/meta/handbook/README.md) explains why
those are a canonical home and this tree is not).

[`_pkgdown.yml`](/_pkgdown.yml) is the curated index:
it groups reference pages under titled sections, each with prose
introducing them.
It is curated rather than derived, which is the thing to know —
adding a reference page does not put it on the site, and the index
carries fewer topics than `man/` holds.

**Building and deploying are separate, and only deploying is gated.**
[`R-CMD-check.yaml`](/.github/workflows/R-CMD-check.yaml) builds the
site on events other than a push, and deploys — via
`pkgdown::deploy_to_branch()` — only on a push whose check succeeded,
on the reasoning that a broken package's website is worse than a stale
one. The standalone [`pkgdown.yaml`](/.github/workflows/pkgdown.yaml)
serves `docs*` and `cran-*` branches and manual dispatch.
`pkgdown` is also one of the per-commit gates
([`ci/per-commit/contract/`](/handbook/operations/ci/per-commit/contract/README.md)),
so the site building is checked far more often than it is published.

*To deepen: state where the deploy branch is served from, and what
`pkgdown/` carries beyond the favicons.*
