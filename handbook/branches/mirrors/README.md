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
and it reaches this fork at all because `krlmlr/duckdb-r` is a fork object
of the canonical repository rather than a copy of it:
Pull requires the upstream to be in the same fork network.
[`.github/pull.yml`](/.github/pull.yml) is where it is configured:
that file's rules are the list of mirrors,
and the fork's series refs match none of them.
That list is derived rather than remembered —
a mirror is carried because a badge measures against it,
so the badge table in the root [`README.md`](/README.md) says what the rules
must be, and [`scripts/pull-config.sh`](/scripts/pull-config.sh) holds the two
against each other.
It is authored here, in the canonical repository,
because CI/CD infrastructure has its source of truth on `main`,
and read from the fork's default branch, which is a mirror of that `main`.

**A mirror moves on the app's schedule, not on ours.**
Pull syncs a repository every six hours,
at a fixed offset it picks itself,
so a mirror is at most that far behind what it copies;
a sync can be asked for at any moment from the URL that config names —
which is what someone who needs a mirror at the canonical tip asks for,
rather than pushing the branch.

**A mirror is created by pushing it, not by configuring it.**
Pull skips a rule whose base branch the fork does not have,
and says so only in its own logs,
so a branch that is about to be measured against is pushed once by hand
([`.claude/skills/series-open/SKILL.md`](/.claude/skills/series-open/SKILL.md));
the config keeps it fresh afterwards and never creates it.

## The copy that goes the other way

One branch per series travels from the fork *to* the canonical repository:
`<S>-green`.
r-universe reads ownership from the URL of the branch it builds,
so a `duckdb.*` flavor built from `krlmlr/duckdb-r` is published as krlmlr's,
and the universe that ought to own the package carries an entry pointing out of it
([`branches/flavors/`](/handbook/branches/flavors/README.md)).
Mirroring green into the canonical repository is what lets
`duckdb.r-universe.dev` name its own repository for every base flavor
and the fork's universe name the fork's,
so no package is configured in two places.

Only `<S>-green`, and only for a base series.
The buffer and `-dev` are working branches nothing installs,
and a `-fwd-green` is a rebuild published from the fork's own universe
to verify a cutover before it happens —
duplicating either is the thing this avoids.

**It is a fast-forward, and a refusal is a finding.**
[`scripts/series-advance.sh`](/scripts/series-advance.sh) pushes it plainly
beside the fork's own green — to the remote `upstream` unless told otherwise,
which is what a `gh` clone of a fork calls what it was forked from —
so git rejects anything that is not a forward,
and the rejection stops the firing rather than being forced:
green is the verified frontier, and two repositories disagreeing about it
is something to read.
The exception is a cutover, which moves green onto the forward lineage
the old green is no ancestor of.
That is the one legitimate non-fast-forward,
so [`scripts/series-cutover.sh`](/scripts/series-cutover.sh) forces the copy itself,
under a lease and after the swap, rather than leaving the next firing to trip on it.

Unlike the mirrors above, this one is ours to push:
Pull carries branches from the canonical repository into the fork and never back.
