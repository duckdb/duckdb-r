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

**Where the upstream repository is looked for.**
Both scripts `cd` to the package root before anything else,
and both default the upstream repository to `../../../duckdb`
resolved from there —
three levels above the package root,
so a package clone at `~/git/R/duckdb/duckdb-r`
finds an upstream clone at `~/git/duckdb`.
That default is the only thing that depends on how the two clones are
arranged: either script takes the path as a positional argument
instead, and a caller that passes one is free of the layout entirely.

**`rconfigure.py`** does the regeneration:
`src/duckdb/`, `src/include/sources.mk`, the Makevars files
(`src/Makevars` and `src/Makevars.win`) from `Makevars.in`,
`R/version.R`,
and the logos in `man/figures/`
copied from the upstream checkout's `logo/` —
all committed, all corrected at the generator.
That set is the mechanical path set a vendor commit may touch,
and the generator is its list.

The logos are the one thing in that set that is not a source,
and they are there because the package shows them:
the horizontal pair is the banner `.github/README.md` renders,
the stacked pair is the package logo the site puts in its header,
and carrying them on the vendor commit is what keeps either
from drifting away from the engine it documents.
The horizontal pair keeps its upstream name;
the stacked pair is renamed on the way in,
because pkgdown finds the package logo by the name
`man/figures/logo.svg` rather than by configuration.
The previous README hotlinked `duckdb.org` instead,
those URLs went away,
and GitHub — which proxies README images
and serves nothing for a URL it cannot fetch — showed no logo at all.
A checkout that cannot supply them stops the run before the
regeneration, rather than leaving the vendored copies stale:
upstream renaming a logo is a decision for a human,
since the new name has to reach `README.md` too.

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
