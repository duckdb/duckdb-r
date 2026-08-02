# The pipeline

The machinery that turns one upstream commit into one vendor commit.
[`scripts/VENDORING.md`](/scripts/VENDORING.md) is the detailed
mechanics record (scripts, local walkthroughs, the fork-point rule
for new dev lines), being absorbed here leaf by leaf.

**Two scripts**, both regenerating `src/duckdb/` from scratch,
re-applying the patch stack, and committing:
[`scripts/vendor.sh`](/scripts/vendor.sh) takes the upstream
clone's `HEAD` as it stands (one-off runs, seeding a series);
[`scripts/vendor-one.sh`](/scripts/vendor-one.sh) walks to the
next unvendored upstream first-parent commit, bumps the fifth
version component, and syntax-checks the glue against the fresh
headers — the *glue gate* — stopping at the first break.
Both refuse a dirty tree,
and both recover the base by scanning recent `src/duckdb/` commits
for a `duckdb/duckdb@<sha>` subject —
refusing, rather than guessing, when the scan comes up empty.
A candidate is worth a commit when it is an exact tag or changes
more than one file under `src/duckdb/`
(one file, the version stamp, always changes).

**`rconfigure.py`** does the regeneration:
`src/duckdb/`, `src/include/sources.mk`, `src/Makevars` from
`Makevars.in`, and `R/version.R` — all committed, all corrected at
the generator.

**The patch stack** under [`patch/`](/patch) applies R-specific
modifications to the vendored tree in place.
A patch that no longer applies is dropped by the next run — loudly,
as a classified failure, not silently —
and patches are sent upstream as pull requests every once in a while.

**The `DESCRIPTION` merge driver**
([`scripts/merge-version.sh`](/scripts/merge-version.sh),
registered by [`scripts/setup-git.sh`](/scripts/setup-git.sh))
keeps the two version counters mergeable across vendor commits by
resolving each component to the strand that owns it
([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).

*To deepen: absorb `scripts/VENDORING.md` §§ scripts,
fork-point rule, and monitoring.*
