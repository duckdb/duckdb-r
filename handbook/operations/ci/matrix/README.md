# The matrix

Which platforms and R versions the `rcc` check covers
([`per-commit/`](/handbook/operations/ci/per-commit/README.md)),
and how an entry gets added.
The matrix is *derived, not listed*:
[`.github/workflows/versions-matrix/action.R`](/.github/workflows/versions-matrix/action.R)
reads the live R tag list and this package's `Depends: R` floor,
and builds the base entries from them —
so a new R release enters the matrix without a commit.

The base shape: R-devel and the recent releases on Linux amd64,
fewer of them on macOS, Windows, and Linux arm64,
plus a coverage entry.
Which versions land where is the action's,
and the reasoning is in its comments.

[`.github/versions-matrix.R`](/.github/versions-matrix.R) is this
repository's extension of that base — the named special entries:

* **older Windows** — extends the Windows sweep further back
  than the base shape carries it.
* **engine poisoning** —
  builds the engine with the `-DDUCKDB_R_POISON_ENGINE` tripwire
  and forces `DUCKDB_R_RUN_TESTS=false`,
  verifying that the CRAN guards keep the engine untouched
  ([`testing/guards/`](/handbook/testing/guards/README.md)).
* **vendored builds** — one Linux and one macOS entry pin
  `DUCKDB_R_USE_SYSTEM_LIB=0`
  so the CRAN-shaped artifact still compiles,
  because regular Linux and macOS entries default to the fast path
  ([`build/fast-paths/`](/handbook/build/fast-paths/README.md));
  Windows always builds from source, having no fast path to default to.

Entries carry extra environment through the generic `env` field —
the mechanism by which one matrix row can flip any knob
([`build/configuration/`](/handbook/build/configuration/README.md)).

## A dependency that will not build

An entry is only as useful as the dependency set it can install,
and the failure lands before the check begins:
one dependency that will not compile
takes the whole entry with it.
`windows-11-arm` is where this bites —
Posit Package Manager publishes no aarch64 Windows binaries,
so that runner builds every dependency from source.

The lever is `Config/gha/extra-packages` in `DESCRIPTION`,
which [`install/`](/.github/workflows/install/action.yml)
passes to pak as extra package references.
A reference carries pak parameters,
so `<package>=?ignore-build-errors` demotes a failed source build
of that one package to a warning
and drops it from the installation plan.
This package says that about `arrow`,
which does not compile against Rtools45;
the field's `Config/comment/…` twin records why.

That parameter reaches a build that fails, and only that.
`adbcdrivermanager` fails a step earlier since CRAN archived it
([apache/arrow-adbc#4638](https://github.com/apache/arrow-adbc/issues/4638)):
nothing resolves the name, so there is no build to demote,
and a dependency that resolves to nothing takes the whole entry with it —
`Can't find package called adbcdrivermanager`, before any check begins.
Declaring it an `Enhances` does not take it out of pak's way.
The action calls pak with `dependencies = "all"`,
which resolves `Enhances` alongside the rest,
so the package stays in the plan whichever optional field holds it.
Neither does `Additional_repositories`: pak reads `repos` and nothing else.

The parameter that does reach it is `=?ignore-unavailable`,
which drops a package no repository carries instead of failing the solve.
So the reference stays in the field and carries both —
`adbcdrivermanager=?ignore-unavailable&ignore-build-errors` —
the second half held for the day it returns to CRAN
and Rtools45 has to build it again.
Dropping it from the plan is only half the arrangement:
a step in [`custom/after-install/`](/.github/workflows/custom/after-install/action.yml)
then installs it from `Additional_repositories`,
which is what actually puts it back on the runners that can have it.
On the runner, though, is not the same as in the check:
`--as-cran` never lets an `Enhances` package reach the tests
([`usage/integrations/`](/handbook/usage/integrations/README.md)
carries why), so this restores the package, not the coverage.

The condition is the build, not the platform,
which is what makes this the right lever:
nothing is declared about *where* the package is expected to fail,
so every runner that has a binary still checks against it,
and the one that does not picks it back up
the day it builds again — with no commit here.

Dropping an optional dependency — `Suggests` or `Enhances` — is safe
because the check is written for it:
tests guard with `skip_if_not_installed()`,
examples with `requireNamespace()`,
and `rcc` downgrades `RCMDCHECK_ERROR_ON` to `warning`
when a declared dependency is missing,
so the entry reports a NOTE where it would otherwise error.

*To deepen: state how the base action derives its version window,
and what `Config/gha/filter` would remove from it —
this package sets no such field today.*
