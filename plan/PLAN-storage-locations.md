# Plan: CRAN-safe storage-location policy

Implementation roadmap for the storage-location policy documented in
`?duckdb_storage` and `?duckdb_storage_config` (see PR #2372). The design is
settled in the docs; this file tracks the work to implement it.

## Guiding principles

- **No behavior change in this PR.** This PR ships the documentation
  (`R/storage.R`, `R/storage-config.R`) and *behavior-neutral* helper
  scaffolding only. Anything that changes where files are actually written, or
  emits a new message, is deferred to a follow-up PR.
- **Everything is testable without touching the real filesystem or HOME.**
  Every dependency on the environment goes through a thin, package-local
  function that tests can replace with `testthat::local_mocked_bindings()`. No
  hard-coded `"~/.duckdb"`, no direct `tools::R_user_dir()` / `system.file()` /
  `file.access()` calls in the resolution logic.
- **Small, reviewable steps.** Land the seams first (no behavior change), then
  the resolver, then the user-facing functions, then the deprecation.

---

## Phase 0 — this PR (docs + behavior-neutral seams)

- [ ] Keep the documentation pages (`?duckdb_storage`, `?duckdb_storage_config`)
      as the spec. No `@export` of the new functions yet.
- [ ] **Revert the behavior changes currently on this branch** so the PR is
      behavior-neutral relative to `main`, or gate them so they are inert:
  - [ ] `R/Driver.R`: restore the previous `extension_directory` /
        `secret_directory` defaults; do not set `home_directory`; do not call
        the ephemeral-storage message on connect.
  - [ ] `R/extensions.R`: keep the new helpers but route them so the resolved
        locations match the released (pre-PR) behavior until the follow-up PR
        flips the default.
  - [ ] Confirm `R CMD check` / the test suite show no behavioral diff vs `main`
        (same resolved directories, no new messages).
- [ ] Introduce the **mockable seams** below as plain local functions, used by
      the existing code paths (light refactor, identical behavior).

### Mockable seams to introduce (no behavior change)

Each is a one-line wrapper so tests can stub it. Replace every direct call in
the resolution/marker logic with these.

- [ ] `r_user_data_dir()` → wraps `tools::R_user_dir("duckdb", "data")`.
- [ ] `duckdb_shared_home()` → wraps `path.expand("~/.duckdb")` (the CLI/Python
      location); remove the hard-coded `"~/.duckdb"` literal in
      `common_secret_directory()`.
- [ ] `package_install_dir()` → wraps `system.file(package = ...)`; the
      `"library"` root and the existing `system_file_path()` build on this.
- [ ] `session_temp_dir()` → wraps `tempdir()` (so tests can point it anywhere
      and assert paths deterministically).
- [ ] `dir_is_writable(path)` → the writability check used by the `"library"`
      probe; implemented by attempting to create+remove the marker (not
      `file.access`, which is unreliable on Windows). Mockable so tests can
      simulate a read-only library without a read-only filesystem.
- [ ] `is_interactive()` — already exists; keep using it (do not call
      `interactive()` directly).
- [ ] Options/env reads stay as `getOption()` / `Sys.getenv()` (already
      mockable via `withr::local_options()` / `withr::local_envvar()`); no
      wrapper needed, but resolution must read them through a single
      `resolve_*` function per kind so precedence is tested in one place.

---

## Phase 1 — resolution layer (behavior change; follow-up PR)

- [ ] `resolve_extension_directory()`: precedence config? (caller-supplied) →
      `options(duckdb.extension_directory)` → `DUCKDB_EXTENSION_DIRECTORY` →
      marker scan → `"library"` write-probe → `session_temp_dir()` default.
- [ ] `resolve_secret_directory()`: option → env → marker scan →
      `session_temp_dir()` default. (No `"library"` root for secrets.)
- [ ] `resolve_temp_directory()`: for `:memory:` databases default to a
      `session_temp_dir()` sub-directory (override DuckDB's cwd `.tmp`); leave
      on-disk databases on DuckDB's `<db>.tmp`. Option/env override.
- [ ] Wire these into `R/Driver.R` (`duckdb()` config), since all three are
      database-global settings (verified in the C++: `extension_directory` is
      `GLOBAL_ONLY`; `secret_directory` / `temp_directory` are SetGlobal-only).
      Do **not** set `home_directory`.
- [ ] Decide & implement the duplicate-marker startup message (a kind's marker
      in more than one root → message + fall back to tempdir).

## Phase 2 — markers

- [ ] Marker filename constant: `.duckdb-r-keep` (provisional). One per kind,
      inside the kind's sub-directory (`<root>/extensions/`,
      `<root>/stored_secrets/`).
- [ ] Marker is a one-line descriptive text file; write the text, never read it
      back (only presence matters). Define the exact wording.
- [ ] `read_marker(kind)` → which root (if any) is selected; mockable file reads.
- [ ] `write_marker(kind, root)` / `remove_marker(kind, root)`.
- [ ] `"library"` write-probe: on connect, if no marker selects a root, try
      `write_marker("extensions", "library")` via `dir_is_writable()`; on
      success use the library, else fall back to tempdir. Never attempt a write
      where it would fail (keeps CRAN checks safe).
- [ ] Marker selects *location* only; a cached binary under
      `v<version>/<platform>/` governs *validity* (re-download), never location.

## Phase 3 — user-facing functions

- [ ] `duckdb_extension_storage(location, migrate = TRUE, conflict = "error")`.
- [ ] `duckdb_secret_storage(location, migrate = TRUE, conflict = "error")`.
- [ ] `duckdb_storage_status()` → data frame, one row per kind (resolved dir +
      which tier chose it).
- [ ] `location` roots: `"session"` (tempdir, also the opt-out), `"user"`,
      `"shared"`, and `"library"` (extensions only); plus an explicit path.
- [ ] `migrate` + `conflict` (`"error"` / `"ours"` / `"theirs"`); secret
      migration reuses the consolidation logic.
- [ ] `@export` + NAMESPACE; move the `@name`/`@aliases` from the planning page
      onto the real functions; resolve the `[duckdb_storage_config()]` links.

## Phase 4 — deprecation & messaging

- [ ] Hard-deprecate `duckdb_consolidate_secrets()` in favor of
      `duckdb_secret_storage()` (lifecycle: `deprecate_warn(always = TRUE)` or
      `deprecate_stop`); keep its logic reachable internally for the migrate
      step.
- [ ] Ephemeral-storage message: fires on connect when the resolved extension
      cache is under tempdir, throttled once / 8h / session, **including
      unattended runs**. `maybe_ephemeral_state_message()` + `inform_once_every()`
      already drafted — finalize and wire in during Phase 1.

---

## Testing strategy

- [ ] Unit-test each `resolve_*()` precedence chain by mocking the seams
      (`r_user_data_dir`, `duckdb_shared_home`, `package_install_dir`,
      `session_temp_dir`, `dir_is_writable`) with `local_mocked_bindings()` and
      `withr::local_options()` / `local_envvar()`. No real HOME / library writes.
- [ ] Test the `"library"` probe both ways: `dir_is_writable() == TRUE` → library
      used and marker written; `== FALSE` → tempdir fallback, no write attempted.
- [ ] Test marker discovery, duplicate-marker ambiguity (→ message + tempdir),
      and that contents are never read back.
- [ ] Test the three user functions: create / relocate / unset (`"session"`),
      migrate with each `conflict` value, and `duckdb_storage_status()` output.
- [ ] Test the 8h throttle (`inform_once_every`) with a mocked clock — pass time
      in rather than calling `Sys.time()` directly, or make the clock a seam.
- [ ] Keep `skip_on_cran()` on anything that touches the C++ engine; the seam
      tests are pure R and run everywhere.

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

- [ ] `NEWS.md` entry (via fledge) for the new functions + deprecation.
- [ ] Reconcile with the existing `maybe_secret_directory_message()` and
      `cleanup_user_directory()` (legacy `R_user_dir/extensions` sweep).
- [ ] Windows path handling (`normalizePath(winslash=)`, `%LOCALAPPDATA%`).
- [ ] `.Rbuildignore` / `.gitignore` already ignore `/extensions/`; re-check
      once the default location moves.
- [ ] pkgdown reference index: add the new topics.
