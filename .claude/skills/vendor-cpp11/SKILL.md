---
name: vendor-cpp11
description: Re-vendor cpp11 into `src/vendor/` from the krlmlr/cpp11 fork, and regenerate the binding. Use when the fork has moved — upstream released, or a patch was added, resolved or retired — or when `cpp11::cpp_register()` output needs rewriting. Covers installing the right generator, the two-commit split that keeps the version and date stamp out of the code diff, and compiling the glue to verify.
---

# Vendor cpp11

Refresh `src/vendor/cpp11/` and `src/vendor/cpp11.hpp`
from [`krlmlr/cpp11`](https://github.com/krlmlr/cpp11),
the patch stack this package compiles against
([`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md)).

Run it when the fork has moved —
upstream released, or a patch was added, resolved or retired.
Not on a schedule:
a vendoring commit that changes nothing but two header lines
is noise in the log.

## The generator is not the vendored copy

Two halves of cpp11 matter here, and they come from different places.

`src/vendor/cpp11/` is the vendored copy, pinned by this repository.
`cpp11::cpp_register()` and `cpp11::cpp_vendor()` are R functions,
resolved from whatever cpp11 the library holds,
and cannot be pinned here at all.
Both have to be the fork:
the flavor names `cpp_register()` derives the `.Call` prefix from
carry more dots than CRAN's cpp11 replaces,
and `cpp_vendor()`'s `date` and `overwrite` arguments are the fork's.

```r
install.packages("cpp11", repos = c("https://krlmlr.r-universe.dev", getOption("repos")))
```

Check what you got before vendoring with it —
a stale library silently produces a stale tree:

```r
packageVersion("cpp11")
```

## Two commits, not one

`cpp_vendor()` stamps `cpp11 version:` and `vendored on:` into every
file it writes.
Those two lines move on every run, in all two dozen files,
and a single commit buries the actual change under them.

Split them.
First commit: the new content, with the **old** header lines kept.
Second commit: the header lines alone.

```bash
old_version=$(sed -n '1p' src/vendor/cpp11.hpp)
old_date=$(sed -n '2p' src/vendor/cpp11.hpp)

R -q -e 'cpp11::cpp_vendor(".", subdir = file.path("src", "vendor"), overwrite = TRUE)'

# Put the old bookkeeping lines back, so commit one is the code alone.
for f in src/vendor/cpp11.hpp src/vendor/cpp11/*.hpp; do
  printf '%s\n%s\n' "$old_version" "$old_date" > "$f.new"
  tail -n +3 "$f" >> "$f.new"
  mv "$f.new" "$f"
done
```

Commit that, then write the real version and date
into the same files and commit again.
`cpp_vendor()`'s `date` argument pins the stamp
when a reproducible tree matters more than the current date.

`subdir` is the fork's too, and it is what keeps the headers out of
`inst/`: nothing of cpp11 is installed, and `-Ivendor` in
[`src/Makevars.in`](/src/Makevars.in) is the only thing that has to know
where they are. Pass it every time -- the default is `inst/include`, and
omitting it vendors a second copy into the installed tree.

Read the first commit before moving on.
It is the whole point of the split:
it says what actually changed in cpp11,
and it is where a surprise shows up.

## Regenerating the binding

`src/cpp11.cpp` and `R/cpp11.R` are generated,
and only need regenerating when the **generator** changed,
not when the vendored headers did:

```r
cpp11::cpp_register()
```

`scripts/flavor.sh` runs this too,
and refuses a binding whose entry points are not C identifiers —
which is what CRAN's cpp11 produces for a two-dot flavor.
If that check fires, the wrong cpp11 is installed.

## Verifying

The R test suite never compiles these headers,
so it proves nothing here.
Compile the glue instead —
fifteen translation units, seconds each:

```bash
cd src
flags=$(grep '^PKG_CPPFLAGS' Makevars | sed 's/^PKG_CPPFLAGS = //; s/\$(DUCKDB_RSTRTMGR)/0/')
rinc=$(R -q -s -e 'cat(R.home("include"))')
for f in *.cpp; do
  g++ -std=c++17 -fsyntax-only -Wall -I"$rinc" $flags "$f" || echo "FAILED $f"
done
```

`Makevars` exists only after `./configure`;
use `Makevars.in` as the reference if it does not.

Then the name guard, which is cheap and catches a wrong generator:

```bash
R -q -f scripts/flavor-package-name.R
```

A full build is the real proof,
but it is an hour cold,
and the syntax pass catches everything a header change plausibly breaks.

## What to write in the commit

Say what arrived and what left.

Arrivals are upstream's — read cpp11's `NEWS.md` between the old and new
version rather than guessing from the diff.
Departures are the fork's: a patch retired because upstream
superseded it changes the vendored tree just as much,
and is the part a reader will not reconstruct from the diff alone.
