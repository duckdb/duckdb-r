# The matrix

[`.github/versions-matrix.R`](/.github/versions-matrix.R) encodes
which platforms and R versions the `rcc` check covers,
and it is the ground truth this page maps.

The shape: current and recent R on Linux, macOS, and Windows,
extended by named special entries —

* **engine poisoning** —
  builds the engine with the `-DDUCKDB_R_POISON_ENGINE` tripwire
  and forces `DUCKDB_R_RUN_TESTS=false`,
  verifying that the CRAN guards keep the engine untouched
  ([`testing/guards/`](/handbook/testing/guards/README.md));
* **vendored builds** — one Linux and one macOS entry pin
  `DUCKDB_R_USE_SYSTEM_LIB=0`
  so the CRAN-shaped artifact still compiles,
  because regular Linux and macOS entries default to the fast path via
  `.github/workflows/custom/before-install/action.yml`
  ([`build/fast-paths/`](/handbook/build/fast-paths/README.md));
  Windows always builds from source.

Entries carry extra environment through the generic `env` field —
the mechanism by which one matrix row can flip any knob
([`build/configuration/`](/handbook/build/configuration/README.md)).
