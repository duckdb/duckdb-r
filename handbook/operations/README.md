# `operations/`

Running the repository.

**Automation prepares and reports; a person concludes.**
The routines vendor, build, verify, and draft,
and leave a record of what they did;
the irreversible moves — a cutover, a release, a close —
are a human's call, recorded where they were taken.

* [`vendoring/`](vendoring/) — how upstream becomes `src/duckdb/`, one commit at a time
* [`triage/`](triage/) — issue intake: verdicts, and where the knowledge routes
* [`review/`](review/) — pull-request flow and stewardship
* [`ci/`](ci/) — what runs on every push: workflows, per-commit builds, the matrix
* [`releases/`](releases/) — from a green branch to CRAN: process, policy, versioning
* [`site/`](site/) — the pkgdown site: what it publishes, and who publishes it
