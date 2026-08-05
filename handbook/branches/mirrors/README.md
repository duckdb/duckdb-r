# Mirrors

The branches the fork carries that are not its own —
copies of `duckdb/duckdb-r`'s branches, what they are for,
and what keeps each level with the branch it copies.
The series refs beside them are
[`model/`](/handbook/branches/model/README.md)'s.

A mirror exists because a comparison needs a base in the same repository.
The badges in the root [`README.md`](/README.md) count a series
*ahead* of the branch it releases from,
and shields.io compares two refs of one repository,
so the branch compared against has to be in the fork
and not only in the canonical repo.
`main` is carried for a second reason as well:
it is what every series seeds from and forward-ports from.

**A mirror has one motion — it takes the canonical tip.**
It is advanced by hard reset rather than by merge,
so a commit pushed onto one in the fork is discarded on the next sync,
and a mirror is never a branch to work on.
That is the property the badges rest on,
and nothing announces its loss:
a mirror left behind still renders, counting commits that have already
shipped.

**The mechanism is the fork's own, not a job of ours.**
Keeping a fork level with what it forked from is what the Pull app does,
and [`.github/pull.yml`](/.github/pull.yml) is where it is configured:
that file's rules are the list of mirrors,
and the fork's series refs match none of them.
It is authored here, in the canonical repository,
because CI/CD infrastructure has its source of truth on `main`,
and read from the fork's default branch, which is a mirror of that `main`.

**No mirror moves until the fork is a fork object.**
Pull requires the upstream to be in the same fork network,
and `krlmlr/duckdb-r` is still a standalone copy,
so every rule is skipped and every mirror stands where it was last pushed
([#2494](https://github.com/duckdb/duckdb-r/issues/2494)).
Until the move, a mirror an *ahead* badge reads from is refreshed by hand.
Afterwards Pull syncs a repository every six hours on a schedule it picks
itself, and a sync can be asked for at any moment
from the URL that config names.

**A mirror is created by pushing it, not by configuring it.**
Pull skips a rule whose base branch the fork does not have,
and says so only in its own logs,
so a branch that is about to be measured against is pushed once by hand
([`.claude/skills/series-open.md`](/.claude/skills/series-open.md));
the config keeps it fresh afterwards and never creates it.

*To deepen: drain [#2494](https://github.com/duckdb/duckdb-r/issues/2494),
after which this page states a mirror's cadence rather than its absence.*
