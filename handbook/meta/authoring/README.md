# Authoring

How prose is written here: the rules an author follows and a review enforces, owned on this page in full.
They cover every Markdown file this repository authors, the handbook included, and the comments and roxygen blocks under `R/` and `tests/`.
The tree's structure, its growth moves, and their enforcement are
[`meta/handbook/`](/handbook/meta/handbook/README.md)'s;
extending the tree means following this page,
and a rewrite that loses a fact is a regression, not an edit.

They stop in two places.
A GitHub issue or pull request body takes reflowed paragraphs instead, because a single newline renders there as a visible break.
Text this repository does not author is nobody's to reformat: the vendored engine under `src/duckdb/`, and anything generated.
Generated here is `man/*.Rd` and the two rendered `README.md` files whose source is [`README.Rmd`](/README.Rmd).

A rule joins this page once a review has enforced it twice, or once the repository adopts it outright;
until then it is a preference, and preferences are not enforced.

## Before writing a sentence

Walk these in order, and stop at the first that answers.
Only the two that ask whether it is a fact and whether it is true end in
nothing being written, and what they discard is not a fact;
the rest move the fact somewhere better than a paragraph.

1. **Is it a fact about how the system works today?**
   A failure narrative, before-and-after framing, a rejected
   alternative, where a file came from,
   or a design for work not done is none:
   all but the last are git's and the issues',
   and the last is [`plan/`](/plan/README.md)'s.
2. **Is it true?**
   Verify on a build that can show the claim:
   one the fast path's release library could distort needs a vendored
   build ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)),
   and for everything the two builds share, either will do.
   When a claim is contested or surprising, read the script or run the
   diff, and discuss before editing.
3. **Does another leaf, a file header, or a reference page own it?**
   Link it: never restate it, and never paraphrase it.
4. **Does an artifact already state it?**
   Never re-enumerate what a file lists (the file is the list),
   and never exhaustively enumerate facts another leaf owns:
   state the principle that locates them, and stop.
5. **Could a check state it instead?**
   A trap that keeps happening deserves a guard that refuses it,
   not a paragraph asking readers to remember;
   where a guard is out of reach, the leaf gets the trigger and the
   action, never the anatomy.
   A behavioural claim lands with the test that pins it,
   a repo-shape claim graduates into the consistency checks,
   and a finding too expensive to re-derive becomes an experiment
   ([`meta/experiments/`](/handbook/meta/experiments/README.md))
   that the leaf links.
   A one-off derivation stays in the pull request.
6. **Then write it, as short as it can be and stay correct
   ([below](#how-long-an-entry-is)),
   and leave a breadcrumb where the reader stands.**
   When detail moves into a leaf,
   the source it came from (a document, a script header,
   an inline comment) keeps its essentials
   and links the leaf that now carries the rest,
   so a fact is edited in one place
   and found from the place it is about.

**A behaviour that looks wrong rather than chosen is settled before the
ladder, not on it.**
A fact can be true and still be one nobody should have to read,
and no rung can tell which:
nothing mechanical distinguishes a deliberate limitation from an unfixed
one, because both are only what the code does.
So it is a discussion, not a test:
is the behaviour *desirable*, or is it a mere *limitation*?
Desirable, and it is an ordinary fact, taking the ladder like any other.
A limitation, and the two costs are weighed against each other.
A fix of one to three lines, with consequences obvious enough to approve
at a glance, is cheaper than the paragraph and every later edit of it:
make it, and write nothing.
Anything larger is work carrying its own risk, review and timeline,
so the limitation is real for as long as that takes.
The tree requires the leaf to state its limits,
with the issue that will remove it, so the fact reads as provisional.
Silence is the one answer never available:
a limitation nobody wrote down is one the next reader rediscovers,
and pays for twice.

## Where the handbook stops

The rungs asking after another owner, an artifact, and a check
all ask the same question (is something else a better home for this?),
and the answer generalises.
**The tree owns what the code cannot say about itself**, which is three
things:

* **Why.**
  No file records why the engine is vendored rather than carried as a
  submodule, or why linearity is worth the rebases it costs.
* **Across.**
  A relationship spanning files that no single one of them contains:
  an invariant, or the direction R-side work is allowed to travel.
* **Not.**
  A limit, a declined request, an absence.
  Nothing in `R/` can say that an argument is accepted and ignored,
  because the fact *is* the missing method.

Everything else the artifact owns, and owns better: what exists, how
many, what the values are now, and what a mechanism does step by step.
Prose that enumerates goes stale without anyone noticing,
because nothing fails when it does.

Which artifact that is differs by area, and the leaf is what says which:
a script or workflow under `operations/`,
a reference page under `usage/`, itself prose and shipped to readers
who do not have this tree,
the generator rather than its output under `architecture/`.
Where an area has none, prose carries the weight alone:
the series invariants are enforced by nothing
([`branches/invariants/`](/handbook/branches/invariants/README.md)),
which is why they are written out in full, in one place, and cited from
everywhere that depends on them.

## How long an entry is

An **entry** (what one change lands on a page)
is the shortest statement of its fact that is still correct.
Length is not thoroughness:
three sentences where one would do
leave the reader to find the one,
and every later edit carries the other two.
Write the fact, what it means for the reader,
and the link that supports it; then stop.
Short is not less true:
what the entry leaves out stays reachable,
in the source it links or the leaf it splits into,
and an edit that loses a fact is a regression however short it reads.

**What supports a fact is not part of the fact,**
and the pull to write the support out is strongest
where the work was hardest.
Each source keeps what it is for:

* An **experiment** keeps the method, the full grid,
  and the day it was true of;
  the entry takes the finding and links the directory.
  A grid copied out of one is a second copy of a record that ages,
  and the leaf is the copy nobody re-runs.
* An **issue** keeps the report, the reproduction, and the discussion;
  the entry takes the answer.
  How the answer was reached is not part of it,
  and a limitation is one sentence
  and the issue that will remove it.
* A **plan** keeps the design, its alternatives, and its sequencing;
  the entry takes what is true today,
  and links the plan for the rest.

**Detail that survives all of that is a leaf, not a longer section.**
A fact needing more than a paragraph or two
has outgrown the page that cites it,
and splitting it out is a growth move of its own
([`meta/handbook/`](/handbook/meta/handbook/README.md)).
The page that keeps the sentence and the link stays about one thing,
which is what its scope sentence claims;
a page that absorbed three such facts instead
can no longer say what it is about,
and that, not the length, is the defect.

**A leaf past 120 lines owes an answer to why it is still one topic.**
Semantic line breaks put a sentence on a line, so 120 of them is a long stretch on one subject.
A leaf that long has usually grown a section a reader would look for under its own name.
The number asks the question rather than settling it.
A leaf that is genuinely one topic stays whole however long it runs.
One that is not splits at the heading that could stand alone, which is the growth move rather than an edit.
Compressing to get under the number is the wrong move in both cases, because sentences cut to fit lose facts that a split keeps.

## Writing the sentence

* **Break lines at meaning boundaries**
  ([semantic line breaks](https://sembr.org)):
  widen a line rather than split a phrase;
  never leave a one-word line,
  and never start a line with one word and a comma.
* **Prose aims for 140 characters**, because a line much longer than that hides its own edits in a diff.
  Meaning wins where it will not fit, so a longer line is tolerated rather than corrected.
  A break moved to save characters is a break in the wrong place.
  A URL too long to break stands alone.
* **A comment takes the code's budget, not the prose budget.**
  A comment and a roxygen line aim for the `line-width` that [`air.toml`](/air.toml) sets, which is air's default of 80 characters today.
  A comment shares its file with code held to that width, and a reader who sized a window for the code reads the comment in the same one.
  The number is a soft aim in exactly the way 140 is, and every other rule here holds there unchanged, the semantic break first of all.
  Holding it is the author's job, because air formats the code around a comment and leaves the prose inside it alone.
* **A line ends with a full stop**, and anything else wants a very good reason.
  A heading, a bold run-in, a list marker, and a colon introducing a list are the reasons, and there are few others.
  A line ending in a comma is the one to look at twice.
  It says the sentence outran the line, and two sentences almost always beat one clause break.
* **No em dashes**, here or in code, commit messages, or pull requests.
  A comma, a colon, a semicolon, or a parenthesis says the same thing.
* **Default to a bullet list; make a table earn its columns.**
  A list extends one line at a time and diffs the same way,
  so an enumeration is bullets, each item led by its name.
  A table is for genuinely two-dimensional content,
  where the reader compares along both axes;
  a two-column table whose second column is prose
  is a list wearing borders.
* **State what stays true as the code moves:**
  a number an ordinary commit invalidates is a hostage.
  Name the mechanism instead:
  the file that lists the members is durable, the count is not.
  A list that names its members is safe where a tally is not.
  A measurement stays when the text says it is one, and against what;
  a count stays when it *is* the design, like the version counters
  ([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
* **Treat a default as a fact:**
  a default governs behaviour, so name the value *and* where it is set;
  the page stays useful when the two drift apart.
* **Link a provisional fact to the issue or plan that will change it:**
  without the link a reader cannot tell
  "how it works" from "how it works for now";
  a behaviour that survives only because nobody has fixed it yet
  is documented as such, and stops being when the issue closes.
* **Never refer by position: name the thing.**
  "The first two" breaks silently when the list above is reordered.
* **Illustrate with a placeholder or a named example, and label which.**
  A placeholder never goes stale but makes every reader substitute;
  a named example reads fluently but ages into a snapshot.
  Both are legitimate, and the guardrails are the same either way.
  Declare a placeholder scheme once, where it starts,
  and keep to one notation:
  a page running three is worse than either choice made badly.
  Say what a named example is a snapshot *of*,
  so a later reader treats it as history rather than as status;
  refreshing it is then an ordinary edit, not a correction.
  A live inventory is neither: it *is* the fact, so it must be current,
  and a dated snapshot is exactly wrong for it.
* **Cite the claim, not its label.**
  An identifier from another page's numbering
  (an invariant number, a state number) means nothing where it is read,
  and resolves only for someone holding that table:
  say what the invariant says, in the clause that depends on it.

## Linking between leaves

A link from one leaf to another is how the tree stays free of repetition,
and it is also the tree's only maintenance cost that grows with its size.
Both halves of that matter.

**Link a boundary once per page, and link the owner.**
The load-bearing form is a page naming the boundary it does not own
("the engine underneath is `engine/`"), stated once, where the reader
first needs it.
A second link to the same target on the same page adds no reachability
and costs another edit when the target moves;
if a reader can enter mid-page and need it again, the page is too long,
and splitting it is the fix.
Never link an internal node where one of its leaves owns the fact:
the node will look like an owner and collect citations its children
deserve.

**A fact that moves takes its inbound links with it.**
Before changing where a fact lives
(renaming a leaf, splitting one in two, moving a section),
search the tree for what points at it and update those pages in the same change.
The links are one-directional, so nothing else will catch a stale one;
a leaf that has quietly become the wrong destination still resolves, and
reads as if it were right, which is worse than a broken link.
The same search settles the cheaper question: if nothing points at a
leaf, its scope sentence is probably claiming a boundary no other page
recognises.
