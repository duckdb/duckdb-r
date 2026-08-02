# CRAN

How a release reaches CRAN —
the checks that run before a submission, the submission itself,
and `cran-comments.md` —
together with the CRAN policy constraints
the source tree lives under year-round.
Only the current line ships to CRAN, as the `duckdb` package;
every other flavor publishes to r-universe and has no CRAN tail
([`branches/flavors/`](/handbook/branches/flavors/README.md)).
Where a submission sits in the release state machine belongs to
[`operations/releases/process/`](/handbook/operations/releases/process/README.md).

## The final checks

What goes to CRAN is a source tarball built from `duckdb/duckdb@main`
rather than from a fork,
so that the git revision ids the build embeds for fetching extensions
are correct.
Take it from the upstream R workflow's `r-package-source` artifact,
or from the post-CI GitHub release asset (`duckdb_<version>.tar.gz`);
this repository's own workflows do not produce a source tarball.

Upload that tarball to WinBuilder against R-devel
(<https://win-builder.r-project.org/upload.aspx>).
The bar there is the same as on the
[CRAN checks page](https://cran.r-project.org/web/checks/check_results_duckdb.html)
and in the upstream R workflow's `R CMD check`:
apart from the known package-size NOTE
and the "Note to CRAN Maintainers",
every error, warning, and note is a blocker.

A `cran-*` branch is the other pre-submission surface:
pushing one triggers [`.github/workflows/rhub.yaml`](/.github/workflows/rhub.yaml),
R-hub's own generic workflow, which checks the package on R-hub's
platforms.
It also runs on demand, taking the platform list as an input
(`linux,windows,macos` by default).
The workflow inventory itself belongs to
[`operations/ci/workflows/`](/handbook/operations/ci/workflows/README.md).

## Submitting

Upload the tarball at <https://cran.r-project.org/submit.html>.
The form carries four things:
the maintainer's name and address — the `cre` entry in `DESCRIPTION` —
the tarball, the text of `cran-comments.md`,
and an acknowledgement of the CRAN Repository Policy.
The maintainer then confirms the upload from a link CRAN mails to that
address, after which CRAN's automated incoming checks run.

Acceptance is asynchronous.
It can take days, and it overlaps the next development cycle,
so the release is tagged and published to r-universe
without waiting for it.
A rejection is not a rollback:
the fix lands on the release branch
and re-enters the release process as a follow-up patch.

## `cran-comments.md`

[`cran-comments.md`](/cran-comments.md) is the note that accompanies a
submission — the free-text comment field of the submission form,
kept in the repository so that it is reviewable and has a history.
It is `.Rbuildignore`d and never ships in the tarball.

It holds two things today:
the name and version being submitted (`duckdb 1.5.5`),
and a ticked checkbox recording that the CRAN Repository Policy
was reviewed at its stated last-edited date (`2026-05-31`).
Keeping it means updating both at each submission:
bump the version line to the version actually being uploaded,
and re-read the policy, replacing the date with the one the policy
currently carries.
The date is the point of the checkbox —
it records *which revision* of the policy was read,
not merely that some revision was.

The `CRAN-SUBMISSION` entry in `.Rbuildignore` anticipates the companion
file — version, timestamp, and commit SHA of a submitted release —
that `devtools` writes after a successful upload.
No such file is in the tree.

## Policy constraints

### No warning suppression

CRAN rejects packages that silence compiler warnings
instead of fixing what causes them,
and `R CMD check --as-cran` enforces it mechanically:
`tools:::.check_pragmas` scans `src/` and `inst/include/`
for lines matching `^\s*#pragma (GCC|clang) diagnostic ignored`,
reporting any hit and escalating a subset —
`-Wuninitialized`, `-Wfloat-equal`, `-Warray-bound`, `-Wformat`,
and a long list of GCC-only, non-portable warning names.

The rule reaches the vendored engine too, even though that code is not
ours: the fix goes into [`patch/`](/patch) and upstream as a pull request,
so the patch can eventually be retired.
Two examples in the current stack.
`patch/0008-Avoid-pragma-for-zstd.patch` deletes a
`-Wshorten-64-to-32` suppression outright, leaving a comment in its place.
`patch/0033-clang-macos.patch` fixes a root cause instead:
`-Wdeprecated-declarations` fired on `char_traits<T>` in libc++
for non-standard `T`,
so fmt's `std_string_view` alias became a struct that derives from
`std::basic_string_view<Char>` only for `char`, `wchar_t`, `char16_t`
and `char32_t`, and is empty otherwise —
the deprecated template is never instantiated.

Two patches fall short of the rule and are debt, not precedent.
`patch/0003-Try-to-ignore-clang-warnings.patch` adds
`-Wgnu-anonymous-struct`, `-Wnested-anon-types` and `-Wdtor-name`
suppressions to re2 headers written as `#  pragma`,
and `patch/0016-Avoid-mbedtls-diagnostic-pragmas.patch` respaces
mbedtls's existing `-Wredundant-decls` pragmas as
`#pragma  GCC  diagnostic  ignored`.
Both forms fall outside the single-space pattern the check greps for,
so the compiler still honours them while the check does not see them.

How the glue in `src/` honours the rule as a source convention is
[`architecture/glue/`](/handbook/architecture/glue/README.md)'s.

### Package size

The vendored engine is large — `src/duckdb/` alone is about 42 MB of C++
sources — and `R CMD check` notes an installed size above 5 Mb,
so the package-size NOTE is permanent.
It is the one note tolerated at every gate above.
CI does not even raise it:
[`.github/workflows/custom/before-install/action.yml`](/.github/workflows/custom/before-install/action.yml)
sets `_R_CHECK_PKG_SIZES_=FALSE`,
which switches the installed-size check off altogether
so that a size NOTE cannot fail a matrix run.

### What ships in the tarball

`R CMD check` notes non-standard files and directories at the top level,
so [`.Rbuildignore`](/.Rbuildignore) keeps the whole maintenance surface
out of the build.
What survives it at the top level is the standard set and nothing else:
`DESCRIPTION`, `NAMESPACE`, `LICENSE`, `NEWS.md`, `README.md`,
`configure` and `configure.win`, `cleanup` and `cleanup.win`,
the `R/`, `src/`, `man/`, `inst/` and `tests/` directories,
and the `.Rbuildignore` and `.gitignore` dotfiles.
Excluded are `AGENTS.md`, `BRANCHES.md`, `RELEASE.md`, `cran-comments.md`,
`Makefile`, `CMakeLists.txt`, `_pkgdown.yml`, `docker-compose.yml`,
the `.Rproj` file, and the `handbook/`, `plan/`, `scripts/`, `patch/`,
`revdep/`, `docker/`, `pkgdown/`, `.github/` and `.claude/` directories.

The practical consequence: a new top-level file needs its `.Rbuildignore`
entry in the same change, unless it is genuinely meant to ship.
That `handbook/` is among the exclusions is also why a source file's
backreference into the handbook is a plain `#` comment and never a
roxygen `#'` line — a generated `.Rd` cross-reference would dangle for
every installed user
([`meta/handbook/`](/handbook/meta/handbook/README.md)).

### What CRAN does not run, and what it may not touch

CRAN's check farm cannot carry the engine's test suite,
so the tests and the runnable examples are gated off there
and enabled automatically on GitHub Actions and r-universe instead;
that guard is [`testing/guards/`](/handbook/testing/guards/README.md)'s.
CRAN policy also constrains where an installed package may write —
which is what shapes the extension and secret storage locations;
[`usage/storage/`](/handbook/usage/storage/README.md) owns that,
with the intent in [`plan/PLAN-storage-locations.md`](/plan/PLAN-storage-locations.md).
And because policy requires contacting affected maintainers well before
a release, the reverse-dependency checks run ahead of the upstream tag,
not after it — see
[`testing/revdep/`](/handbook/testing/revdep/README.md).
