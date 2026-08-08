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
  Everything else downloads at `INSTALL` time;
  there is no companion R package carrying extensions,
  and none is coming —
  upstream declined a second distribution channel
  ([#1582](https://github.com/duckdb/duckdb-r/issues/1582)).
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
* **What an extension's values become in R** —
  spatial's geometry, ICU's timestamps —
  is [`types/`](/handbook/usage/types/README.md)'s.
* **Community extensions come from a second repository:**
  `INSTALL <name> FROM community` fetches from
  `community-extensions.duckdb.org`,
  whose build matrix and platform coverage are its own —
  what one repository carries says nothing about the other.
* **Windows** fetches extensions for the `windows_amd64_mingw` platform,
  and that directory is a per-extension subset of the MSVC
  `windows_amd64` one beside it.
  An extension built in duckdb/duckdb's own tree opts out through the
  `NOT MINGW` guards in
  [`.github/config/extensions`](https://github.com/duckdb/duckdb/tree/main/.github/config/extensions);
  one built in a repository of its own decides there instead,
  so no single list covers both — the repository does.
  A `HEAD` request for
  `extensions.duckdb.org/<version>/<platform>/<name>.duckdb_extension.gz`
  answers for one name, on one platform, at one version,
  and is what the troubleshooting link in the download error looks up.
  Probe it rather than remember it:
  the answer moves in both directions,
  and `spatial` published for mingw at 1.3.2, not at 1.4.0,
  and again from 1.4.1 on
  ([#100](https://github.com/duckdb/duckdb-r/issues/100)).
* **Every mingw gap today is an extension built outside the engine's
  tree** — which on its own predicts nothing,
  because `spatial` and `sqlite_scanner` are built that way and publish.
  The 2026-08 probe at 1.5.5 finds `aws`, `azure`, `iceberg`,
  `motherduck`, `mysql_scanner` and `postgres_scanner` absent,
  and every other name probed present
  ([#100](https://github.com/duckdb/duckdb-r/issues/100)).
  A missing build is asked for at the extension's own repository —
  [`duckdb/duckdb-postgres`](https://github.com/duckdb/duckdb-postgres)
  for `postgres_scanner`
  ([#1581](https://github.com/duckdb/duckdb-r/issues/1581),
  [#2503](https://github.com/duckdb/duckdb-r/issues/2503)) —
  where such a pull request is
  [accepted](https://github.com/duckdb/duckdb-r/issues/2425#issuecomment-5182746870);
  `motherduck` has no public repository to ask at.
  The standing gaps are the toolchain epic
  ([#2234](https://github.com/duckdb/duckdb-r/issues/2234),
  upstream
  [duckdb/duckdb#24431](https://github.com/duckdb/duckdb/issues/24431)).
  Reaching one of these extensions from R meanwhile means leaving this
  package's engine for a DuckDB ADBC driver built with the toolchain the
  platform's own DuckDB uses
  ([`integrations/`](/handbook/usage/integrations/README.md)).
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
  `INSTALL` stays closed there —
  the community repository serves no arm64 Windows name at all —
  but hand-loading the MSVC `windows_arm64` artifact by path
  splits by extension class:
  a C++-ABI extension (`icu`) kills the R process at `LOAD`,
  platform metadata matching or not,
  while a C-API extension (`odbc_scanner`) loads and registers its
  functions, hatches open,
  on the strength of importing nothing from the host
  ([experiment](/experiments/2026-08-05-windows-extension-coverage/README.md)).
  The escape widens exactly as fast as upstream moves extensions
  to the C API.
* **Loading an extension file by path** —
  `LOAD '/path/to/name.duckdb_extension'` —
  is how an extension comes in that was built locally
  or for another toolchain — MSVC, where this package is mingw —
  and takes two driver settings when the file is unsigned
  or carries a foreign platform tag:
  `duckdb(config = list(allow_unsigned_extensions = "true",
  allow_extensions_metadata_mismatch = "true"))`.
  `INSTALL '/path/to/file.duckdb_extension.gz'` accepts the same
  file as downloaded — compression included —
  and keeps it in the store, so later sessions `LOAD` it by name;
  a foreign platform tag keeps needing the settings at every load.
  Driver config is the only door:
  the engine refuses to enable `allow_unsigned_extensions` once it is
  running, so `SET` is always too late.
  And the mismatch setting alone changes nothing,
  even for a signed file —
  the metadata error throws from the signed branch,
  so it is consulted only when unsigned loading is already allowed
  (`LoadExtensionInternal`,
  [`src/duckdb/src/main/extension/extension_load.cpp`](/src/duckdb/src/main/extension/extension_load.cpp)).
* **`INSTALL` can be pointed at another repository:**
  `SET custom_extension_repository = '<repo>'`
  redirects the download to a mirror or a local directory
  in the repository's layout —
  `<repo>/<duckdb-version>/<platform>/<name>.duckdb_extension.gz` —
  and `FORCE INSTALL <name>` re-fetches from it.
  This is the self-hosting path upstream prefers,
  and the escape when the network, not the platform,
  blocks the default repository.

Verify any claim about the shipped set on a **vendored build** —
the fast path answers for a different artifact
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).

*To deepen: drain
[#66](https://github.com/duckdb/duckdb-r/issues/66) (webR) into a
boundary once its flags land.
Facts land here to stay, not to wait for a reference page.*
