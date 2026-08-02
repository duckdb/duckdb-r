# Plans and history

Intent lives outside the handbook,
as a document under [`plan/`](/plan/README.md),
and this leaf covers what belongs there —
active designs, superseded records, and the roadmap they add up to —
how such a document is written and retired,
and how it connects to the leaf whose topic it concerns.
Which documents exist is [`plan/README.md`](/plan/README.md)'s table;
it is not repeated here, because a second copy of a list would rot.

The handbook describes the package as it is today.
A plan describes work that is proposed or in progress,
so putting it in the tree would make the tree lie.
It goes under `plan/` instead, named `PLAN-<topic>.md`,
and opens with a line saying what it is
and which document owns the topic today.
A design that has been superseded,
or a one-off review or measurement,
belongs in `plan/history/` and says so in its own first lines.
The two directories are separate because the distinction is the point:
a plan may still come true, a history never will.
Retiring a plan is exactly that move —
the file into `history/`, its row in `plan/README.md` along with it.

A plan is not a description of the system,
so it may disagree with the document that owns its topic;
when it does, the owner is right.
A history is kept for the reasoning and the numbers it records,
not for completeness —
the ccache measurements in the appendix of
[`plan/history/vendoring-loop.md`](/plan/history/vendoring-loop.md)
are still cited by the cost model
long after the design around them was superseded.

The roadmap is not a separate document.
It is the set of plans that are live,
read off the table in `plan/README.md`.

Every plan concerns a topic, and every topic has a leaf,
so the leaf points at the plan that carries its intent:
[`usage/storage/`](/handbook/usage/storage/README.md)
at the storage-location policy's plan,
[`usage/integrations/`](/handbook/usage/integrations/README.md)
at the DBI Arrow API's.
A reader who walks down to a topic then finds both
how it works today and what is meant to change.
The pointer runs that way because the tree is what gets walked:
a plan no leaf points at is unreachable from
[`handbook/`](/handbook/README.md),
and that is a gap in the tree rather than a defect of the plan.
The other way round has its own name —
a file under `plan/` that `plan/README.md` does not name is an orphan,
which is the one thing that directory's structure exists to prevent.

This leaf tracks no individual plan.
It does not say what any plan proposes, how far along it is,
or when it will land;
the plan says that, and `plan/README.md` says where the plan is.
