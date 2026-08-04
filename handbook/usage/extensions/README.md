# Extensions

Which DuckDB extensions the package ships,
what loads and installs by itself,
and how to get more.

* **Bundled: `parquet` and `core_functions`, nothing else.**
  The authoritative list is the set of
  `-DDUCKDB_EXTENSION_*_LINKED` defines in the committed
  [`src/Makevars`](/src/Makevars);
  changing it is a vendoring-time decision
  ([`build/configuration/`](/handbook/build/configuration/README.md)).
* **Autoload is on, autoinstall is off.**
  The build flips `autoload_known_extensions`
  (`-DDUCKDB_EXTENSION_AUTOLOAD_DEFAULT`)
  but leaves `autoinstall_known_extensions` false:
  an *installed* extension loads on first use,
  but nothing is downloaded without being asked
  ([#2306](https://github.com/duckdb/duckdb-r/issues/2306)) —
  the CLI behaves differently because it flips both.
  `INSTALL icu` once per DuckDB version and platform,
  and ICU autoloads everywhere from then on;
  `SET autoinstall_known_extensions = true` restores CLI behavior.
* **Where installed extensions live**, and how to move or share
  the store, is [`storage/`](/handbook/usage/storage/README.md).
* **Whether loading is allowed at all** is decided per driver:
  the `allow_extensions` argument, option, and environment variable,
  with automatic detection of the libc++ ABI mismatch on Linux
  that would otherwise crash R —
  `?duckdb`, section "DuckDB extensions on Linux",
  owns that decision tree
  ([#1107](https://github.com/duckdb/duckdb-r/issues/1107)).
* **Windows** fetches extensions for the `windows_amd64_mingw` platform,
  which DuckDB has distributed since 1.4.1;
  gaps for out-of-tree extensions are tracked as the toolchain epic
  ([#2234](https://github.com/duckdb/duckdb-r/issues/2234)).
* **Some platforms are not covered**, and which ones is DuckDB's to say
  and does change:
  [Extension Distribution](https://duckdb.org/docs/stable/extensions/extension_distribution)
  is the current list,
  and `PRAGMA platform` is the name to look this build up under.
  Off the list, `INSTALL` is an HTTP 404 —
  a gap to wait out, not a fault to fix here.
  As of 2026-08 that is R's Windows/arm64 build:
  DuckDB publishes `windows_arm64`, built with MSVC,
  but no `windows_arm64_mingw`, which is what R's toolchain produces
  ([#2425](https://github.com/duckdb/duckdb-r/issues/2425)).

Verify any claim about the shipped set on a **vendored build** —
the fast path answers for a different artifact
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).

*To deepen: drain
[#66](https://github.com/duckdb/duckdb-r/issues/66) (webR) into a
boundary once its flags land.
Facts land here to stay, not to wait for a reference page.*
