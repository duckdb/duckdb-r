# Where to help

Finding something worth doing in this repository:
the label vocabulary on the issue tracker,
how to turn that vocabulary into a live list of entry points,
and where longer-range intent is written down.

## The invitation

One label invites outside work: `help wanted ❤️`,
whose description on the tracker is the whole of its definition —
"we'd love your help!".
It marks work the maintainers would welcome from someone else;
whether a given issue earns it is a triage verdict, not a rule
([`operations/triage/`](/handbook/operations/triage/README.md)).
Start from the query, not from a list:

* [open issues labelled `help wanted ❤️`](https://github.com/duckdb/duckdb-r/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted+%3Aheart%3A%22)

The tracker is the list.
No curated selection of starter issues is kept here,
because such a selection is wrong within a week
and nothing forces it to be corrected —
a saved query is never wrong.
There is no `good first issue` label either:
the tracker does not grade issues by difficulty.

The emoji in a label name is not always the character it looks like.
GitHub renders the shortcode `:heart:` in a label name as ❤️,
so this label reads `help wanted ❤️` on screen
but has to be typed as `label:"help wanted :heart:"` in a search box
or on a command line.
`upstream 🐟` and `duckplyr 🗜️` carry the emoji character itself
and can be pasted verbatim.

## The vocabulary

The authoritative set is the tracker's own
[label index](https://github.com/duckdb/duckdb-r/labels);
what each label says:

| Label | What it says |
|---|---|
| `help wanted ❤️` | we'd love your help! |
| `bug` | an unexpected problem or unintended behavior |
| `feature` | a feature request or enhancement |
| `documentation` | the answer is a documentation change |
| `upkeep` | maintenance, infrastructure, and similar |
| `reprex` | needs a minimal reproducible example |
| `reproduced` | the report has been reproduced |
| `upstream 🐟` | the cause is in the DuckDB engine, not in the R glue |
| `duckplyr 🗜️` | support for the duckplyr R package |

Six of these carry that wording as their own description on GitHub;
`documentation`, `reproduced` and `upstream 🐟` carry none,
and the table records how they are used.
`reproduced` is rare in practice.
The labels are an issue vocabulary:
open pull requests carry none.

`upstream 🐟` is the boundary that matters most when choosing work.
It says the cause lies in the vendored DuckDB C++ engine
rather than in this package's R and C++ glue,
so the fix belongs in
[`duckdb/duckdb`](https://github.com/duckdb/duckdb)
and reaches this package only when the vendoring pipeline
picks up the commit that carries it —
see [`operations/vendoring/`](/handbook/operations/vendoring/README.md)
and [`architecture/engine/`](/handbook/architecture/engine/README.md).
A window-function binder failure closed this way
([#2357](https://github.com/duckdb/duckdb-r/issues/2357))
is the shape to expect.
`src/duckdb/` is never edited here.

`reprex` marks a report that is not yet actionable.
Producing the missing reproducible example
is help in its own right, and needs no build of the package.

## Narrowing the search

Combine a label with the ordinary GitHub qualifiers.
Each of these is a query to paste into the tracker's search box:

```
is:issue is:open label:"help wanted :heart:" label:bug
is:issue is:open label:"help wanted :heart:" -label:"upstream 🐟"
is:issue is:open label:documentation
is:issue is:open label:reprex
is:issue is:open no:label
```

The first narrows to bugs;
the second drops what will be fixed upstream.
The third finds issues whose answer is a page of this handbook,
which is the cheapest kind of contribution to finish.
The last finds issues nobody has classified yet;
reproducing one on a current build and saying so in a comment is useful,
but the verdict that follows is the maintainer's —
[`operations/triage/`](/handbook/operations/triage/README.md)
owns what a label means to apply and what closing an issue requires.

Nothing in the vocabulary records who is working on what,
so comment on the issue before you start.
A working development environment is
[`contributors/setup/`](/handbook/contributors/setup/README.md);
branching, testing and opening the pull request are
[`contributors/workflow/`](/handbook/contributors/workflow/README.md);
what a maintainer then checks is
[`operations/review/`](/handbook/operations/review/README.md).

## Reporting instead of fixing

A report that can be reproduced is worth more than one that cannot,
and there is no template to fill in:
this repository has no `.github/ISSUE_TEMPLATE/`,
so the form is yours to choose.
A report that does not attract the `reprex` label carries
a self-contained example that fails,
the `sessionInfo()` it fails under,
which flavor and version of the package was installed
([`branches/flavors/`](/handbook/branches/flavors/README.md)),
and — when the behavior changed — the last version that worked.

## The roadmap

There is no dated roadmap.
Intent lives as a plan document under `plan/`,
and what is live, in which order, is that directory's table;
[`meta/plans/`](/handbook/meta/plans/README.md) owns it.
An issue covered by a plan is one to read the plan for first:
the design decision is already made there,
and the remaining work is to implement it.
