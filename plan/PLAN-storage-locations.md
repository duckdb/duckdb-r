# Plan: CRAN-safe storage-location policy

Implementation roadmap for the storage-location policy documented in
`?duckdb_storage` and `?duckdb_storage_config`. The design is settled in the
docs; this file tracks the work to implement it.

## Guiding principles

- **Start behavior-neutral.** The first step ships the documentation
  (`R/storage.R`, `R/storage-config.R`) and *behavior-neutral* helper
  scaffolding only. Anything that changes where files are actually written, or
  emits a new message, comes in a later step.
- **Everything is testable without touching the real filesystem or HOME.**
  Every dependency on the environment goes through a thin, package-local
  function that tests can replace with `testthat::local_mocked_bindings()`. No
  hard-coded `"~/.duckdb"`, no direct `tools::R_user_dir()` / `system.file()` /
  `file.access()` calls in the resolution logic.
- **Each implementation bullet carries its own test.** The end of this file
  keeps a flat checklist to re-confirm once everything is wired together.
- **Small, reviewable steps.** Land the seams first (no behavior change), then
  the resolver, then the user-facing functions, then the removal.

---

## Phase 0 — docs + behavior-neutral seams (done)

- [x] Documentation pages (`?duckdb_storage`, `?duckdb_storage_config`) are the
      spec. The new functions are not `@export`ed yet.
- [x] Behavior reverted to match `main` (extensions → package install dir,
      secrets → `R_user_dir`, no `home_directory`, no connect-time message), so
      the working tree is behavior-neutral.
- [x] Seam tests in `tests/testthat/test-storage-seams.R` pin current behavior
      and confirm each seam is mockable.
- [x] Unexported stubs for `duckdb_extension_storage()` /
      `duckdb_secret_storage()` / `duckdb_storage_status()` keep the documented
      `\usage` in sync with the code (so `codoc`/`R CMD check` is clean); they
      `stop()` until implemented.
- [x] pkgdown reference index lists `duckdb_storage` / `duckdb_storage_config`.

### Mockable seams (implemented in Phase 0)

Each is a thin wrapper so tests can stub it with `local_mocked_bindings()`;
resolution/marker logic calls these, never the underlying primitive.

- [x] `default_user_directory()` → wraps `tools::R_user_dir("duckdb", "data")`
      (pre-existing; the R-user-dir seam).
- [x] `duckdb_shared_home()` → wraps `path.expand("~/.duckdb")`; replaces the
      hard-coded literal in `common_secret_directory()`.
- [x] `system_file_path()` → the package-install-dir seam (pre-existing); tests
      stub it rather than resolving the real install path. (No separate
      `package_install_dir()` wrapper — `system_file_path()` is enough.)
- [x] `check_dots_empty(...)` → base fallback, swapped to
      `rlang::check_dots_empty0()` in `.onLoad()` when rlang is available (the
      same strategy as `is_interactive` / `rapi_error`; no rlang-availability
      cache).
- [x] `is_interactive()` — pre-existing; use it, never `interactive()`.
- [x] `session_temp_dir()` (wraps `tempdir()`) — implemented in Phase 1.
- [x] Options/env reads stay `getOption()` / `Sys.getenv()` (mockable via
      `withr`), but each kind reads them through one `resolve_*()` so precedence
      is tested in one place. (Phase 1.)

---

## Phase 1 — resolution layer (done)

- [x] `resolve_extension_directory()`: config (caller-supplied) →
      `options(duckdb.extension_directory)` → `DUCKDB_EXTENSION_DIRECTORY` →
      marker scan → `"library"` write-probe → `session_temp_dir()` default.
      → test: each precedence rung with mocked seams + `withr` options/env.
- [x] `resolve_secret_directory()`: option → env → marker scan →
      `session_temp_dir()` default (no `"library"` root).
      → test: precedence, and that the default is tempdir, not `R_user_dir`.
- [x] `resolve_temp_directory()`: `:memory:` → `session_temp_dir()` sub-dir
      (override DuckDB's cwd `.tmp`); on-disk → DuckDB's `<db>.tmp`. Option/env.
      → test: memory vs on-disk branch with a mocked `dbdir`.
- [x] Wire into `R/Driver.R` (`duckdb()` config) — all three are database-global
      (C++: `extension_directory` is `GLOBAL_ONLY`; `secret_directory` /
      `temp_directory` are SetGlobal-only). Do **not** set `home_directory`.
      → test: connect and assert resolved settings; `home_directory` unset.
- [x] Duplicate-marker startup message (a kind's marker in >1 root → message +
      tempdir fallback).
      → test: two markers present → message emitted, resolves to tempdir.

## Phase 2 — markers (done)

- [x] Marker filename constant `.duckdb-r-keep` (provisional); per kind, inside
      `<root>/extensions/` and `<root>/stored_secrets/`.
      → test: path construction per kind / root.
- [x] Marker is a one-line descriptive text file; written, never read back
      (presence only). Define the wording.
      → test: presence drives selection; editing contents has no effect.
- [x] `read_marker(kind)` / `write_marker(kind, root)` / `remove_marker(...)`.
      → test: round-trip create / read / remove with a mocked temp root.
- [x] `"library"` probe = write the keep-marker into `<library>/extensions/`
      (creating it if needed) and leave it in place; the write doubles as the
      writability test. On success use the library; on failure fall back to
      tempdir. No throwaway probe file.
      → test: writable → library + marker left in place; not → tempdir, no write.
- [x] Marker selects *location*; a cached binary under `v<version>/<platform>/`
      governs *validity* only.
      → test: a stale binary in an unmarked root does not select it.

## Phase 3 — user-facing functions (done)

- [x] Flesh out the Phase 0 stubs (replace the `stop()` bodies) and `@export`
      them.
- [x] `duckdb_extension_storage(location, ..., migrate = TRUE, conflict = "error")`.
- [x] `duckdb_secret_storage(location, ..., migrate = TRUE, conflict = "error")`.
- [x] `duckdb_storage_status()` → data frame, one row per kind (resolved dir +
      which tier chose it).
- [x] `...` checked empty via `check_dots_empty()`.
- [x] `location` roots `"session"` (also the opt-out) / `"user"` / `"shared"` /
      `"library"` (extensions only); plus an explicit path.
- [x] `migrate` + `conflict` (`"error"` / `"ours"` / `"theirs"`); secret
      migration reuses the consolidation logic.
- [x] `@export` + NAMESPACE; move `@name` / `@aliases` from the planning page
      onto the real functions; resolve the `[duckdb_storage_config()]` links.
      → test: create / relocate / unset (`"session"`); migrate per `conflict`;
      `check_dots_empty()` rejects stray args; `duckdb_storage_status()` shape.

## Phase 4 — removal & messaging (done)

- [x] Remove `duckdb_consolidate_secrets()` outright — no deprecation ceremony
      (it existed only briefly). Fold its logic into the `migrate` step of
      `duckdb_secret_storage()`, and remove its `_pkgdown.yml` "Secrets" entry.
      → test: the migrate step covers the cases the old function did.
- [x] Startup message on connect when the resolved extension cache is under
      tempdir; throttled once / 8h / session, including unattended runs. Shown
      only when the package chose the location itself (no config/option/env), so
      setting the directory both opts in and silences it. `?duckdb_storage`
      documents how to silence it.
      → test: fires once then throttled (mocked clock); silent for a persistent
      cache.
- [ ] Reactive ephemeral *warning* (warn only when the session actually wrote
      something, on disconnect/at-exit): **deferred to a separate change.** A
      reactive design proved too complex to land here -- detecting the write,
      picking a reliable trigger, and avoiding lost output during shutdown all
      need more thought -- so the connect-time message above stays for now.
- [x] Library-cache notice: announce once (on first marker write, i.e. once per
      install) when the extension cache initializes in the package library.
      → test: fires when the marker is freshly written, not when it pre-exists.

---

## Tests to confirm after implementing (full checklist)

- [x] Each `resolve_*()` precedence chain via mocked seams + `withr`.
- [x] `"library"` probe both ways (writable → library + marker; not → tempdir).
- [x] Marker discovery, duplicate-marker ambiguity, contents-never-read.
- [x] The three user functions: create / relocate / unset, migrate per
      `conflict`, status output.
- [x] 8h throttle via a mocked clock (inject time; do not call `Sys.time()`).
- [x] `check_dots_empty()` with and without rlang (`has_rlang()` mocked).
- [x] `skip_on_cran()` on anything touching the C++ engine; seam tests are pure
      R and run everywhere.

## Open questions / decisions to confirm

- [ ] Final names: `location` vs `where`/`root`; values `"session"`/`"library"`
      vs `"temporary"`/`"package"`; marker filename `.duckdb-r-keep`.
- [ ] `temp_directory`: override only for `:memory:`, or always? (Large on-disk
      spills could fill `/tmp` if always.)
- [ ] Is the ephemeral message acceptable during CRAN revdep checks (it is an
      `inform`, not a warning), or should it be suppressed there specifically?
- [ ] `inform_once_every` clock: inject a time seam vs. read `Sys.time()`
      (the latter is disallowed in some headless contexts).

## Things not to forget

- [ ] `NEWS.md` entry (via fledge) for the new functions + removal.
- [x] Reconcile with the existing `maybe_secret_directory_message()` and
      `cleanup_user_directory()` (legacy `R_user_dir/extensions` sweep).
- [ ] Windows path handling (`normalizePath(winslash=)`, `%LOCALAPPDATA%`).
- [ ] `.Rbuildignore` / `.gitignore` already ignore `/extensions/`; re-check
      once the default location moves.
- [x] pkgdown reference index: add the new topics.
