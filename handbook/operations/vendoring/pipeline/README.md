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

**A remote is not a clone, and `gh` names both.**
A package clone made with `gh` carries two remotes —
`origin` and `upstream` —
and the upstream `duckdb/duckdb` checkout is neither of them:
it is a separate directory on disk, with no remote in this repository
pointing at it.
`scripts/series-cutover.sh` takes one of each,
which is where the two used to get swapped.
Passing a remote name where the path belonged reported
`coverage would regress`:
`git -C` failed because the directory was not there,
and the gate read that failure as a negative ancestry answer.
The script now checks that the path is a checkout first,
so the message names the argument rather than the refs —
and the two are named rather than positional,
`--remote <name>` and `--upstream <path>`,
which is what makes the swap unsayable instead of merely diagnosable.
That spelling is the one every `scripts/series-*.sh` shares
([`series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).

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

**The regenerated tree is byte-reproducible, and cheap to re-hash**, and neither was
always true — both are properties the pipeline now enforces rather than caveats a reader carries.
`pragma_version.cpp` records `DUCKDB_SOURCE_ID` as an *abbreviated* upstream commit id,
and git sizes that abbreviation from the number of objects in the clone it runs in,
so the same upstream commit once vendored differently from two clones;
[`vendor.sh`](/scripts/vendor.sh) pins `core.abbrev` to 10 in the upstream clone,
which is the width DuckDB's own CMake truncates to.
And `rconfigure.py` used to rewrite all ~3550 files whether or not their content changed,
which invalidated git's stat cache and made every `git status` over the tree re-hash it;
it now restores a file that comes out byte-identical to its predecessor,
keeping the inode and the stat cache, and reports `N files changed, M unchanged`.

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

**A vendor commit's subject is machine-readable state**, and the shape is fixed:

```text
vendor: Update vendored sources to duckdb/duckdb@<commit_hash>

Date: <author date of the upstream commit>

<subjects of the upstream first-parent commits since the previously vendored commit>
```

A tagged release says so in the subject,
`vendor: Update vendored sources (tag v1.x.x) to duckdb/duckdb@<commit_hash>`,
and [`vendor-one.sh`](/scripts/vendor-one.sh) ends its run there.

[`vendor-one.sh`](/scripts/vendor-one.sh), [`series-advance.sh`](/scripts/series-advance.sh),
[`series-port.sh`](/scripts/series-port.sh) and the repair skills
all recover *where is this branch in upstream history* by parsing `duckdb/duckdb@<sha>` out of that line.
So it is not prose: do not reword it,
and do not squash vendor commits without keeping the newest SHA in the subject.

*To deepen: absorb `scripts/VENDORING.md`'s remaining sections —
vendoring by hand, creating a patch, the two properties of the
regenerated tree, and the fork-point rule for a new dev line.*
