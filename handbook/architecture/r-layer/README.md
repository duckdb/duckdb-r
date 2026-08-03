# The R layer

Everything under `R/`:
where a method lives, which files are generated and by what,
and how the package refers to itself without writing its own name.
The C++ half of the interface is
[`glue/`](/handbook/architecture/glue/README.md).

**One file per method.**
`R/` is flat, and every S4 method lives in a file named
`<generic>__<signature>.R` —
the naming convention is the index.
Closely-paired signatures may share a file;
unrelated methods never do.
Constructors, helpers, and non-S4 interfaces group by topic
(`Driver.R`, `Connection.R`, `relational.R`, `storage.R`, …).

**Generated files are edited at their producer.**
Each opens with a header saying so:

* `R/cpp11.R` — by `cpp11::cpp_register()`,
  after a change to the `[[cpp11::register]]` surface in `src/`
* `R/rethrow-gen.R` — by `scripts/rethrow.R`,
  run by `.Rprofile` on every R start in the repo
* `R/version.R` — by `scripts/rconfigure.py`, during vendoring

R code calls the `rethrow_rapi_*()` wrappers, not `rapi_*()` directly —
the wrapper re-raises C++ errors pointing at the user's call.

**Never hard-code the package name.**
The package publishes under several names
([`branches/flavors/`](/handbook/branches/flavors/README.md)),
so a literal `duckdb` works on `main` and breaks everywhere else.
[`R/package.R`](/R/package.R) is the seam —
its accessors are the only supported way to spell the name.
`simulate_duckdb()` exposes `get_package_name()` and
`get_package_env()` as `$pkg` and `$env`, which is what
`@examplesIf simulate_duckdb()$env$examples_enabled()` relies on.
The same rule holds in roxygen prose:
inline chunks go through the seam, never a `:::` qualifier.
The guard that scans for offenders is
[`testing/guards/`](/handbook/testing/guards/README.md)'s.

*To deepen: state the S4 class inventory and the deferred S3
registration for Suggests packages; drain
[#98](https://github.com/duckdb/duckdb-r/issues/98),
[#1052](https://github.com/duckdb/duckdb-r/issues/1052).*
