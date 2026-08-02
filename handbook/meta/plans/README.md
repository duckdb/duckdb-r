# Plans and history

Intent lives outside the handbook,
as a document under [`plan/`](/plan/README.md),
and this leaf covers that directory:
what belongs there, how it is organized,
what adding or retiring a document takes,
and how a plan reaches the leaf whose topic it carries.
The documents that exist today are listed in
[`plan/README.md`](/plan/README.md), the directory's generated index —
a list this page points at rather than repeats.

## `plan/` stays outside the tree

This is decided, not incidental:
the plan documents live at `plan/`
and are not migrated under `handbook/`.
The handbook describes the package as it is today,
and a plan describes intent —
work proposed, in progress, or since overtaken.
Filing a proposal among the descriptions
would make the tree assert things that are not so,
and a leaf is only worth reading if it can be read as fact.

The consequence is a directory of documentation
outside the single source of truth,
which therefore needs a routing surface of its own.
That surface is `plan/README.md`:
generated in place, one row per document,
each grouped under the handbook leaf that owns its topic,
so someone who arrives at `plan/` without knowing the handbook exists
still finds the leaf that explains what they are looking at.

## Plans, and history

A plan is work proposed or in progress.
It sits directly in `plan/`, named `PLAN-<topic>.md`.

A design that has been superseded,
or a one-off review or measurement,
sits in `plan/history/` instead, named for what it is.
Such a document is kept for the reasoning and the numbers it records,
not for completeness:
the ccache measurements in the appendix of
[`plan/history/vendoring-loop.md`](/plan/history/vendoring-loop.md)
are still cited by the cost model
long after the design around them was superseded.

The two live in separate directories because the distinction is the
point — a plan may still come true, a history never will —
and every document says which it is in its own first lines,
together with the document that owns its topic today.
That last part matters because a plan is not a description of the
system and may have been overtaken by events:
where a document under `plan/` and the owner of the topic disagree,
the owner is right.
Which document owns a topic is what the tree answers;
walking down from [`handbook/`](/handbook/README.md) is how to ask.

## Adding, retiring, and orphans

A document is added by writing it under `plan/` or `plan/history/`,
opening it with the line that says what it is
and which document owns its topic today,
and then claiming it in the ownership map inside
[`.claude/skills/docs-consistency/docs-readme.R`](/.claude/skills/docs-consistency/docs-readme.R)
for the leaf whose topic it carries.
Regenerating is what puts the row in the index.
The rendered table is never edited by hand —
the generator overwrites it —
which is the shape every generated index in the repository has
([the forms](/handbook/meta/handbook/README.md)).

A document the map does not claim is an orphan,
and an orphan is the one thing this directory's structure exists to
prevent.
That is now mechanical rather than a matter of care:
an unclaimed file renders under an `Unowned` heading,
and the generator's `--check` mode fails until the map claims it.

Retiring a plan is a move, not a deletion:
the file into `history/`, its entry in the map along with it,
then regenerate.

## Where a plan meets its leaf

Every plan carries the intent for some topic,
and every topic has a leaf,
so the pointer runs both ways.
The index groups a document under the leaf that owns its topic,
and that leaf points at the document:
[`usage/storage/`](/handbook/usage/storage/README.md)
at the storage-location policy's plan,
[`usage/integrations/`](/handbook/usage/integrations/README.md)
at the DBI Arrow API's.
A reader who walks down to a topic then finds both
how it works today and what is meant to change.

The roadmap is not a separate document.
It is the set of plans that are live, read off that index.

A plan no leaf points at is unreachable by walking down from
`handbook/`, which is a gap in the tree rather than a defect of the
plan.

## Limits

This leaf tracks no individual plan.
It does not say what any plan proposes, how far along it is,
or when it will land;
the plan says that, and `plan/README.md` says where the plan is.
Nor does it hold the ownership map —
that lives with the generator,
and whether a given mapping is the right one
is judged by the `docs-consistency` skill
([`.claude/skills/docs-consistency/`](/.claude/skills/docs-consistency/SKILL.md)).
