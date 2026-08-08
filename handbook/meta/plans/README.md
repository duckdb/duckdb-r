# Plans and history

Intent lives outside the handbook, under [`plan/`](/plan/README.md):
the handbook describes how the system works today,
and a plan describes work proposed, in progress, or superseded —
filing proposals among descriptions would make the tree assert
things that are not so.

A plan sits in `plan/` as `PLAN-<topic>.md` while it is open.
What becomes of it decides which way it leaves:
one that came true moves to `plan/done/`,
one overtaken by events to `plan/superseded/`,
both kept for their reasoning rather than as descriptions
of the system.
Each opens by saying what it is
and which document owns its topic today —
and where a plan and the owner disagree, the owner is right.
[`plan/README.md`](/plan/README.md) is the directory's index and
names every document; a file it does not name is an orphan.
Each leaf whose topic a plan carries
links that plan from its own text.

Evidence lives outside the tree the same way,
in [`experiments/`](/experiments/README.md):
one directory per experiment,
holding what it measured and everything the run took.
A leaf states what is true;
an experiment records what was measured, when, and on what,
and the leaf that leans on it links it —
which is what lets a reader weigh a finding
without repeating the work.

Prefer durable storage for a result that is hard to reproduce —
one that needs an old package version, a long build,
a specific platform, or hours of compute:
commit the script *and* the recorded output under `experiments/`
while the result is fresh.
The output should be a Markdown file created with `reprex::reprex(si = TRUE)`.
Session scratch space, chat transcripts, and CI logs all expire,
and a finding that lived only there
is the same work waiting to be done again.
