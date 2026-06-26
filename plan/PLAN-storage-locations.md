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
- [ ] `session_temp_dir()` (wraps `tempdir()`) — deferred to Phase 1.
- [ ] Options/env reads stay `getOption()` / `Sys.getenv()` (mockable via
      `withr`), but each kind reads them through one `resolve_*()` so precedence
      is tested in one place. (Phase 1.)

---

## Phase 1 — resolution layer (behavior change)

- [ ] `resolve_extension_directory()`: config (caller-supplied) →
      `options(duckdb.extension_directory)` → `DUCKDB_EXTENSION_DIRECTORY` →
      marker scan → `"library"` write-probe → `session_temp_dir()` default.
      → test: each precedence rung with mocked seams + `withr` options/env.
- [ ] `resolve_secret_directory()`: option → env → marker scan →
      `session_temp_dir()` default (no `"library"` root).
      → test: precedence, and that the default is tempdir, not `R_user_dir`.
- [ ] `resolve_temp_directory()`: `:memory:` → `session_temp_dir()` sub-dir
      (override DuckDB's cwd `.tmp`); on-disk → DuckDB's `<db>.tmp`. Option/env.
      → test: memory vs on-disk branch with a mocked `dbdir`.
- [ ] Wire into `R/Driver.R` (`duckdb()` config) — all three are database-global
      (C++: `extension_directory` is `GLOBAL_ONLY`; `secret_directory` /
      `temp_directory` are SetGlobal-only). Do **not** set `home_directory`.
      → test: connect and assert resolved settings; `home_directory` unset.
- [ ] Duplicate-marker startup message (a kind's marker in >1 root → message +
      tempdir fallback).
      → test: two markers present → message emitted, resolves to tempdir.

## Phase 2 — markers

- [ ] Marker filename constant `.duckdb-r-keep` (provisional); per kind, inside
      `<root>/extensions/` and `<root>/stored_secrets/`.
      → test: path construction per kind / root.
- [ ] Marker is a one-line descriptive text file; written, never read back
      (presence only). Define the wording.
      → test: presence drives selection; editing contents has no effect.
- [ ] `read_marker(kind)` / `write_marker(kind, root)` / `remove_marker(...)`.
      → test: round-trip create / read / remove with a mocked temp root.
- [ ] `"library"` probe = write the keep-marker into `<library>/extensions/`
      (creating it if needed) and leave it in place; the write doubles as the
      writability test. On success use the library; on failure fall back to
      tempdir. No throwaway probe file.
      → test: writable → library + marker left in place; not → tempdir, no write.
- [ ] Marker selects *location*; a cached binary under `v<version>/<platform>/`
      governs *validity* only.
      → test: a stale binary in an unmarked root does not select it.

## Phase 3 — user-facing functions

- [ ] `duckdb_extension_storage(location, ..., migrate = TRUE, conflict = "error")`.
- [ ] `duckdb_secret_storage(location, ..., migrate = TRUE, conflict = "error")`.
- [ ] `duckdb_storage_status()` → data frame, one row per kind (resolved dir +
      which tier chose it).
- [ ] `...` checked empty via `check_dots_empty()`.
- [ ] `location` roots `"session"` (also the opt-out) / `"user"` / `"shared"` /
      `"library"` (extensions only); plus an explicit path.
- [ ] `migrate` + `conflict` (`"error"` / `"ours"` / `"theirs"`); secret
      migration reuses the consolidation logic.
- [ ] `@export` + NAMESPACE; move `@name` / `@aliases` from the planning page
      onto the real functions; resolve the `[duckdb_storage_config()]` links.
      → test: create / relocate / unset (`"session"`); migrate per `conflict`;
      `check_dots_empty()` rejects stray args; `duckdb_storage_status()` shape.

## Phase 4 — removal & messaging

- [ ] Remove `duckdb_consolidate_secrets()` outright — no deprecation ceremony
      (it existed only briefly). Fold its logic into the `migrate` step of
      `duckdb_secret_storage()`.
      → test: the migrate step covers the cases the old function did.
- [ ] Ephemeral-storage message on connect when the resolved extension cache is
      under tempdir; throttled once / 8h / session, **including unattended runs**
      (no interactive gate). Re-add `maybe_ephemeral_state_message()` +
      `inform_once_every()` (removed in Phase 0) and wire in.
      → test: fires once then throttled (mocked clock); fires non-interactively.

---

## Tests to confirm after implementing (full checklist)

- [ ] Each `resolve_*()` precedence chain via mocked seams + `withr`.
- [ ] `"library"` probe both ways (writable → library + marker; not → tempdir).
- [ ] Marker discovery, duplicate-marker ambiguity, contents-never-read.
- [ ] The three user functions: create / relocate / unset, migrate per
      `conflict`, status output.
- [ ] 8h throttle via a mocked clock (inject time; do not call `Sys.time()`).
- [ ] `check_dots_empty()` with and without rlang (`has_rlang()` mocked).
- [ ] `skip_on_cran()` on anything touching the C++ engine; seam tests are pure
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
- [ ] Reconcile with the existing `maybe_secret_directory_message()` and
      `cleanup_user_directory()` (legacy `R_user_dir/extensions` sweep).
- [ ] Windows path handling (`normalizePath(winslash=)`, `%LOCALAPPDATA%`).
- [ ] `.Rbuildignore` / `.gitignore` already ignore `/extensions/`; re-check
      once the default location moves.
- [ ] pkgdown reference index: add the new topics.
