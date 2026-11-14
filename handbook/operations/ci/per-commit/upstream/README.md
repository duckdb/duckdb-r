# Verdicts upstream

The per-commit verdicts shown in the canonical repository:
the `each-rcc (fork)` status on the commits of an open pull request from the fork,
and the workflow that copies it there.

`each.yaml` runs in `krlmlr/duckdb-r` alone ([`branches/model/`](/handbook/branches/model/README.md)),
so the `rcc` status its legs write lands on the fork's copy of a commit,
and a pull request in `duckdb/duckdb-r` that carries the same commit shows nothing.
[`each-mirror.yaml`](/.github/workflows/each-mirror.yaml) copies the verdicts across, hourly and on dispatch,
by running [`scripts/each-mirror.sh`](/scripts/each-mirror.sh) in the canonical repository;
the script's header holds the mechanism.

**The canonical repository writes, with its own token.**
A workflow in the fork cannot write a status in `duckdb/duckdb-r`, because its token is scoped to the fork.
The canonical repository's token can, and the store it reads is a public branch of the fork
([`store/`](/handbook/operations/ci/per-commit/store/README.md)),
so no secret crosses between the two repositories.
The workflow declares the `statuses: write` and `pull-requests: read` it needs, and nothing else.

**It covers what a reviewer reads, and nothing the fork has not judged.**
Every open pull request whose head is in the fork, with its commits read by git from its base,
because the API's list of a pull request's commits stops at 250 and a landing carries thousands.
Each commit the store holds a record for shows that record's state,
linked to the leg in the fork that decided it.

**Nothing is posted twice, and a run's API use is bounded.**
A watermark in the Actions cache holds every record already confirmed on its commit,
so a run considers only records new to a pull request or changed since.
It reads what those commits show before it writes, a hundred commits to one GraphQL query,
and it posts at most `MAX_WRITES` statuses, 300 in [`each-mirror.yaml`](/.github/workflows/each-mirror.yaml), 7.5 seconds apart,
against GitHub's limit of about 500 content-creating requests an hour.
A lost cache costs reads, never a duplicate status.

**The status is a display surface, as the fork's `rcc` is.**
Nothing decides from it ([`contract/`](/handbook/operations/ci/per-commit/contract/README.md)),
and a commit judged again shows its new verdict after the next run.
