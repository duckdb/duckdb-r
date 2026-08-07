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
[`pkgdown/extra.css`](/pkgdown/extra.css) keys both logos off that
attribute, which is the only way either can follow it.
For the README logo it is the `<picture>` block in
[`README.md`](/README.md) that has to be overridden: it selects on
`prefers-color-scheme`, which answers for the browser rather than for
the site, so on its own it contradicts the switch as soon as a reader
uses one.
For the package logo it is pkgdown, which knows one logo and no dark
variant, so the dark file is swapped in by the same rule.
Both dark files are vendored beside their light counterparts
([`vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
That file also restores the `height` the README asks for, against a
site stylesheet that would otherwise size the logo by its column.

*To deepen: state where the deploy branch is served from.*
