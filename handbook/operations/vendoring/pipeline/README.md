# The pipeline

The machinery that turns one upstream commit into one vendor commit.
[`scripts/VENDORING.md`](/scripts/VENDORING.md) keeps what is not
yet absorbed: driving the scripts by hand, and creating a patch.

**Two scripts**, both regenerating `src/duckdb/` from scratch,
re-applying the patch stack, and committing:
[`scripts/vendor.sh`](/scripts/vendor.sh) takes the upstream
clone's `HEAD` as it stands (one-off runs, seeding a series);
[`scripts/vendor-one.sh`](/scripts/vendor-one.sh) walks to the
next unvendored upstream first-parent commit — one per invocation
unless `--commits` asks for more — bumps the fifth
version component, and syntax-checks the glue against the fresh
headers, the *glue gate*, stopping at the first break.
Both refuse a dirty tree,
and both recover the base by scanning recent `src/duckdb/` commits
for a `duckdb/duckdb@<sha>` subject —
refusing, rather than guessing, when the scan comes up empty.
A candidate is worth a commit when it is an exact tag or changes
more than one file under `src/duckdb/`
(one file, the version stamp, always changes).

**`rconfigure.py`** does the regeneration:
`src/duckdb/`, `src/include/sources.mk`, the Makevars files
(`src/Makevars` and `src/Makevars.win`) from `Makevars.in`,
and `R/version.R` — all committed, all corrected at the generator.
That set is the mechanical path set a vendor commit may touch,
and the generator is its list.

**The patch stack** under [`patch/`](/patch) applies R-specific
modifications to the vendored tree in place,
and patches are sent upstream as pull requests every once in a while.
A patch that stops applying forward is not one case but two,
and the run tells them apart:

* it **reverses** cleanly — its change is already in the regenerated
  tree, so the run deletes it and carries on.
  This is how a patch retires when upstream accepts it.
* it neither applies nor reverses — the code it patched moved,
  so the run **stops** with the regenerated sources uncommitted
  and the upstream clone kept, for a hand rebase.
  Nothing is dropped silently.

**The `DESCRIPTION` merge driver**
([`scripts/merge-version.sh`](/scripts/merge-version.sh),
registered by [`scripts/setup-git.sh`](/scripts/setup-git.sh))
keeps the two version counters mergeable across vendor commits by
resolving each component to the strand that owns it
([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).

*To deepen: absorb `scripts/VENDORING.md`'s remaining sections —
vendoring by hand, creating a patch, the two properties of the
regenerated tree, the fork-point rule for a new dev line, the vendor
commit format, and the badges.*
