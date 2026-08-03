# Authoring

How the prose of a handbook page is written —
the rules an author follows and a review enforces, owned here in full.
The tree's structure, its growth moves, and their enforcement are
[`meta/handbook/`](/handbook/meta/handbook/README.md)'s;
extending the tree means following this page,
and a rewrite that loses a fact is a regression, not an edit.
A rule joins this page once a review has enforced it twice;
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
   Verify on a build that can show the claim —
   one the fast path's release library could distort needs a vendored
   build ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)),
   and for everything the two builds share, either will do.
   When a claim is contested or surprising, read the script or run the
   diff, and discuss before editing.
3. **Does another leaf, a file header, or a reference page own it?**
   Link it — never restate it, and never paraphrase it.
4. **Does an artifact already state it?**
   Never re-enumerate what a file lists — the file is the list —
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
   ([`experiments/`](/experiments/README.md)) that the leaf links.
   A one-off derivation stays in the pull request.
6. **Then write it, and leave a breadcrumb where the reader stands.**
   When detail moves into a leaf,
   the source it came from — a document, a script header,
   an inline comment — keeps its essentials
   and links the leaf that now carries the rest,
   so a fact is edited in one place
   and found from the place it is about.

## Where the handbook stops

Rungs 3 to 5 all ask the same question — is something else a better
home for this? — and the answer generalises.
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

Which artifact that is differs by area, and the leaf is what says which —
a script or workflow under `operations/`,
a reference page under `usage/`, itself prose and shipped to readers
who do not have this tree,
the generator rather than its output under `architecture/`.
Where an area has none, prose carries the weight alone:
the series invariants are enforced by nothing
([`branches/invariants/`](/handbook/branches/invariants/README.md)),
which is why they are written out in full, in one place, and cited from
everywhere that depends on them.

## Writing the sentence

* **Break lines at meaning boundaries**
  ([semantic line breaks](https://sembr.org)):
  widen a line rather than split a phrase;
  never leave a one-word line,
  and never start a line with one word and a comma.
  Aim under 80 characters, but meaning wins over length,
  and a long link or code token may stand alone.
* **Default to a bullet list; make a table earn its columns.**
  A list extends one line at a time and diffs the same way,
  so an enumeration is bullets, each item led by its name.
  A table is for genuinely two-dimensional content,
  where the reader compares along both axes;
  a two-column table whose second column is prose
  is a list wearing borders.
* **State what stays true as the code moves:**
  a number an ordinary commit invalidates is a hostage —
  name the mechanism instead:
  the file that lists the members is durable, the count is not.
  A list that names its members is safe where a tally is not.
  A measurement stays when the text says it is one, and against what;
  a count stays when it *is* the design, like the version counters
  ([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
* **Treat a default as a fact:**
  a default governs behaviour, so name the value *and* where it is set —
  the page stays useful when the two drift apart.
* **Link a provisional fact to the issue or plan that will change it:**
  without the link a reader cannot tell
  "how it works" from "how it works for now";
  a behaviour that survives only because nobody has fixed it yet
  is documented as such, and stops being when the issue closes.
* **Never refer by position — name the thing.**
  "The first two" breaks silently when the list above is reordered.
* **Illustrate with a placeholder or a named example — and label which.**
  A placeholder never goes stale but makes every reader substitute;
  a named example reads fluently but ages into a snapshot.
  Both are legitimate, and the guardrails are the same either way.
  Declare a placeholder scheme once, where it starts,
  and keep to one notation — a page running three is worse than either
  choice made badly.
  Say what a named example is a snapshot *of*,
  so a later reader treats it as history rather than as status;
  refreshing it is then an ordinary edit, not a correction.
  A live inventory is neither: it *is* the fact, so it must be current,
  and a dated snapshot is exactly wrong for it.
* **Cite the claim, not its label.**
  An identifier from another page's numbering — an invariant number,
  a state number — means nothing where it is read,
  and resolves only for someone holding that table:
  say what the invariant says, in the clause that depends on it.
* **Write links that leave their directory from the repository root**,
  with a leading `/` —
  GitHub resolves them against the root on any branch or fork;
  same-directory and downward links stay relative.
  Such links do not resolve in a local preview;
  the handbook is read on GitHub, and that is the trade taken.

## Linking between leaves

A link from one leaf to another is how the tree stays free of repetition,
and it is also the tree's only maintenance cost that grows with its size.
Both halves of that matter.

**Link a boundary once per page, and link the owner.**
The load-bearing form is a page naming the boundary it does not own —
"the engine underneath is `engine/`" — stated once, where the reader
first needs it.
A second link to the same target on the same page adds no reachability
and costs another edit when the target moves;
if a reader can enter mid-page and need it again, the page is too long,
and splitting it is the fix.
Never link an internal node where one of its leaves owns the fact:
the node will look like an owner and collect citations its children
deserve.

**A fact that moves takes its inbound links with it.**
Before changing where a fact lives — renaming a leaf, splitting one in
two, moving a section — search the tree for what points at it and update
those pages in the same change.
The links are one-directional, so nothing else will catch a stale one;
a leaf that has quietly become the wrong destination still resolves, and
reads as if it were right, which is worse than a broken link.
The same search settles the cheaper question: if nothing points at a
leaf, its scope sentence is probably claiming a boundary no other page
recognises.
