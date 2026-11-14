# Verdicts upstream

The per-commit verdicts shown in the canonical repository:
the `each-rcc (fork)` status on the commits of an open pull request from the fork,
and the workflow that copies it there.

`each.yaml` runs in `krlmlr/duckdb-r` alone ([`branches/model/`](/handbook/branches/model/README.md)),
so the `rcc` status its legs write lands on the fork's copy of a commit,
and a pull request in `duckdb/duckdb-r` that carries the same commit shows nothing.
[`each-mirror.yaml`](/.github/workflows/each-mirror.yaml) copies the verdicts across, hourly and on dispatch,
by running [`scripts/each-mirror.sh`](/scripts/each-mirror.sh) in the canonical repository.
The script's header holds the mechanism, with the watermark and every limit on a run;
this page holds why it is built that way.

**The canonical repository writes, with its own token.**
A workflow in the fork cannot write a status in `duckdb/duckdb-r`, because its token is scoped to the fork.
The canonical repository's token can, and the store it reads is a public branch of the fork
([`store/`](/handbook/operations/ci/per-commit/store/README.md)),
so no secret crosses between the two repositories.

**It covers what a reviewer reads, and nothing the fork has not judged.**
Every open pull request whose head is in the fork, with its commits read by git from its base,
because the API's list of a pull request's commits stops at 250 and a landing carries thousands.
Each commit the store holds a record for shows that record's state,
linked to the leg in the fork that decided it.

**Only the fork's maintainers spend a run.**
Anyone can open a pull request whose head is a branch of the public fork,
so a pull request is covered only when its author is an owner, member or collaborator of the canonical repository,
and a stranger's cannot spend the posts a run allows.
A status links only to a run in the fork, so a record cannot send a reviewer anywhere else.

**Nothing is posted twice, and a run's API use is bounded.**
A status already shown as the store has it is never posted again,
so a lost cache costs reads, never a duplicate status.
GitHub refuses content-creating requests past about 500 an hour with its secondary rate limit,
and the token's 1,000 REST requests an hour are shared with every other workflow of the repository
([rate limits for the REST API](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)),
so a run paces its posts, leaves part of that budget to the others,
and stops at the first refusal that says either limit was reached.
A refusal that concerns one commit skips that commit alone, so it cannot hold up the commits after it.
A run stops posting well inside the job's timeout, so the watermark it saves is never lost to a cancelled job.

**The status is a display surface, as the fork's `rcc` is.**
Nothing decides from it ([`contract/`](/handbook/operations/ci/per-commit/contract/README.md)),
and a commit judged again shows its new verdict after the next run.
