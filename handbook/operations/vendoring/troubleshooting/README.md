# Troubleshooting

*Stub apart from "A red vendor commit", below;
the rest still routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](/handbook/meta/handbook/);
the last section holds this leaf's parameters.*

Scope: when a run is red —
the glue gate, base scans, dropped patches,
stuck shards, stale snapshots.

## A red vendor commit

A vendor commit can be red for a reason that is not the R side's:
upstream did not build or pass at that commit,
and the vendored tree carries the defect.
There is nothing to adapt, and two ways to get the chain green.

**Fold it forward — the default.**
When the *next* upstream commit repairs the tree,
squash the failing vendor commit into it.
One commit remains, carrying the newer commit's tree
and its `vendor: … duckdb/duckdb@<sha>` subject,
because the subject is machine-readable state
and must name the tree the commit carries;
the folded commit's SHA and subject move into the body,
marked as not passing on their own.
`R-side fix` sections from both are kept.
Mirror the fold in `<S>-build`, which carries no CI and can be force-pushed.

The fifth version component gains a gap where the folded commit's bump went.
That is fine: the counter orders the series, it does not count it
([versioning](/handbook/operations/releases/versioning/)).
Gaps are legitimate; repeats are not.

The next commit is what makes this work, and the only thing that does.
Squashing a longer span would bury the commits between,
none of which ever stood on the chain as its own tree;
one adjacent pair is a fold, three or more is a rewrite of history
nobody can bisect afterwards.
Within that bound folding is cheap: no new file,
and nothing left behind to remember.

**Forward-port a patch — the escalation.**
Folding stops working the moment the next commit is red too:
the build stays red for at least one commit that has to remain,
and there is no adjacent green tree to squash into.

Then carry upstream's own fix backwards instead.
Take the fixing commit's diff, re-root it under `src/duckdb/`,
and add it to the patch stack as `patch/00NN-<name>.patch`
([patch stack](/BRANCHES.md#patch-stack)).
Fold the patch and its effect into the vendor commit that needs it,
amended with an `R-side fix` section
naming the upstream fix and why the tree cannot stand without it —
the same move as a glue fix, one directory over.
Verify the re-rooted files are byte-identical
to the fixing commit's versions;
if they are not, the patch is not a forward-port of it.

The patch is transient and retires itself.
Every vendor run re-applies the whole stack
and deletes a patch that no longer applies,
so the vendor commit that reaches upstream's own fix
drops the patch as part of itself —
no follow-up commit, nothing to clean up.
Say so in the commit message, so the next reader knows it is meant to go.

One arithmetic consequence, and it is the mechanism working:
with the patch applied, the fixing upstream commit may change nothing,
in which case `vendor-one.sh` skips it by its own
more-than-one-file rule and names it in the next vendor commit's body,
exactly as it treats any upstream commit that leaves the tree alone.

**Why the default is the fold.**
A forward-port keeps every upstream commit on the chain,
which a fold does not —
after folding, `-build` is no longer one-to-one with
upstream first-parent history at that point,
and a bisect cannot land on the commit that broke.
That is a real cost, and it is smaller than the alternative's:
a patch is a file someone has to review, carry, and trust to retire,
for a defect upstream already fixed in the very next commit.
Pay it only when that next commit is red as well.

The loop's own statement of the rule is in
[`.claude/skills/series-loop.md`](/.claude/skills/series-loop.md), stage 2.

## Everything else

Today:

* [`scripts/VENDORING.md`](/scripts/VENDORING.md)
* [`scripts/EACH.md`](/scripts/EACH.md)

To write this leaf:

* absorb: the troubleshooting section of `scripts/VENDORING.md`;
  glue gate, base scans, dropped patches;
  stuck shards belong to `ci/per-commit/` — link
