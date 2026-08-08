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

**The site follows the reader's theme.**
`template.light-switch` puts a light/dark/auto control in the navbar,
and pkgdown resolves whichever the reader picks — `auto` included —
to a `data-bs-theme` attribute on the page.
[`pkgdown/extra.css`](/pkgdown/extra.css) keys the package logo off that
attribute, which is the only way it can follow one:
pkgdown knows one logo and no dark variant, so the dark file is swapped
in by hand. Both files are vendored
([`vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).

**The home page carries one logo, and it is that one.**
[`README.Rmd`](/README.Rmd) writes two READMEs
([`meta/handbook/`](/handbook/meta/handbook/README.md)),
and the wordmark banner goes only into the one GitHub reads.
The site builds its home page from the root `README.md`, which has no
banner — so the header logo above is the only one on the page,
rather than the second of two.

*To deepen: state where the deploy branch is served from.*
