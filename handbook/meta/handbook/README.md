# The handbook's rules

The handbook is a strict topic hierarchy with full cover:
every aspect of this package that may need documentation
has exactly one place in this tree.

* **Internal nodes navigate, and may govern.**
  An internal `README.md` is a scope sentence,
  optionally the principles that govern its area,
  and a nested list of its subdirectories — nothing else.
  A principle is why the area is divided as it is,
  or a constraint every leaf under it obeys;
  it belongs to the node because no single leaf could state it
  without reaching past its own scope.
  Anything one leaf could state is that leaf's,
  and an internal node never repeats it
  (the tests are among [the forms](#the-forms)).
  The root additionally sketches each area's contents,
  naming the next level in prose —
  names, not links, so the sketch cannot rot.
* **Leaves explain, once.**
  A leaf page owns its topic;
  other pages link to it and never paraphrase it.
* **Leaves own their boundaries.**
  A leaf states not only how its topic works
  but also its limits, its declined requests with their reasons,
  and — where intent exists — a pointer to the plan or issue that carries it.
  "Can it do X?" is answered at X's leaf, whichever way it goes.
* **Full cover.**
  Every fact is reachable by walking down from
  [`handbook/`](/handbook/README.md);
  a topic with no place in the tree is a defect of the tree,
  not of the topic.
* **Pointer leaves are legitimate.**
  Where the canonical home is elsewhere —
  R reference pages (`?topic`) shipped in the tarball,
  machine-loaded playbooks under `.claude/skills/`,
  or truly external documentation
  such as the upstream DuckDB docs —
  the leaf states the fact's home and links to it,
  so a traversal still finds it.
  The tree needs no separate map of what lives outside;
  the leaves are the map.
* **Intent lives outside the tree.**
  A plan describes work that is not done;
  the handbook describes how the system works today.
  So plans stay in [`plan/`](/plan/), outside `handbook/` —
  a decision taken, not a leftover.
  [`meta/plans/`](/handbook/meta/plans/) explains that directory
  and the conventions that govern it,
  and each affected leaf links the plan that carries its intent.
  A plan that has become fact is documented as fact,
  in the leaf, with no trace of its having once been a proposal.
* **The tree is the single source of truth.**
  Everything outside it is secondary —
  user-facing surfaces (the root `README.md`, reference pages),
  per-directory indexes in the source tree, convenience copies —
  and every secondary document carries a backreference
  to the handbook node it serves.
  Where a pointer leaf names a fixed medium as a fact's home,
  the links are bidirectional:
  the leaf points at the medium,
  the medium backreferences the leaf.
  For reference pages the backreference lives
  in the roxygen source under `R/` —
  `man/*.Rd` is generated and never edited.
  A secondary document without a backreference is an orphan.
* **A leaf is born small and grows in place.**
  Three depths are legitimate published states.
  A **reference** leaf states its scope
  and where the knowledge lives today.
  A **core** leaf additionally states the load-bearing facts —
  defaults, boundaries, the answers issues keep asking for —
  and still points elsewhere for the rest.
  A **comprehensive** leaf answers its topic in full,
  so a reader never has to leave the tree for it.
  Comprehensive is the end state, not the entry bar;
  a leaf below it says what remains in a single closing line
  ([the forms](#the-forms)),
  which is this tree's only form of visible debt.

## Growing a leaf

The tree deepens one leaf per change, by three moves.
Any of them is a complete, mergeable pull request:

1. **Close an issue into its leaf.**
   An issue closed without a code change is closed
   *with* a documentation change:
   the answer, workaround, or limitation lands in the leaf
   that owns the topic, the closing comment links it,
   and the leaf links the issue from the text that answers it.
   The verdicts, and where each routes the knowledge,
   are [`operations/triage/`](/handbook/operations/triage/README.md)'s.
2. **Absorb a document, or one section of one.**
   Absorbed text leaves its old home in the same change,
   replaced by a one-line pointer to the leaf;
   a fully absorbed file is deleted, not left as a redirect,
   and anything that linked to it is updated.
   Prose may be rewritten — the handbook's voice is tighter
   than its sources' —
   but a rewrite that loses a fact is a regression, not an edit.
3. **Deepen from the ground truth.**
   Write what the code, scripts, and workflows actually do,
   and cite the file that proves it.

Whichever move, the same protocol:

* **Verify before you state.**
  Check every behavioral claim against the ground truth;
  check engine-configuration claims against a vendored build,
  never under `DUCKDB_R_USE_SYSTEM_LIB=1`.
* **Stay inside the scope line.**
  A fact beyond it belongs to another leaf — link, don't absorb.
* **Finish clean.**
  Update the leaf's closing deepen line — or delete it
  when nothing remains — and leave no dangling links.

## The forms

The rules above say what a page must do;
these are the shapes the tree has settled on for doing it.
They exist so that leaves written independently read as one document.

**A written leaf** opens with its H1
and then a scope sentence in ordinary prose,
and continues with the content.
The scope sentence is load-bearing at every depth:
the tree's shape depends on every leaf declaring its boundary.
A one-screen leaf needs no headings; a longer one uses `##`.

**A deepen line** is the last line of a leaf
that is not yet comprehensive:
one italic sentence naming what deepening absorbs, verifies, or drains —
`*To deepen: absorb `BRANCHES.md` § …; drain #….*` —
kept current by every change to the leaf,
and deleted by the change that completes it.
A leaf with no deepen line asserts it is comprehensive.

**A bullet list is the default; a table must earn its columns.**
A list extends one line at a time and diffs the same way,
so an enumeration — files and their producers,
knobs and their effects, verdicts and their meanings —
is bullets, each item led by its name.
A table is for genuinely two-dimensional content,
where the reader compares along both axes
and the aligned columns carry the comparison;
a two-column table whose second column is prose
is a list wearing borders.

**A principle on an internal node** is a short paragraph, or a few,
between the scope sentence and the list of children.
It survives three tests,
and a sentence that fails any of them belongs to a leaf instead:
a leaf yet to be written could falsify it
(a generalisation over the children, not a summary of one);
it has the lifetime of the child list
(a fact an ordinary commit could falsify has a leaf);
and it names no particulars —
no paths, scripts, variables, versions, counts, or commands.
A node whose leaves share no such constraint gets no principle;
where an area has a leaf whose topic is the area's own rules,
the principles are that leaf's, and the node stays navigation-only.

**No page writes `duckdb` as though it were the package's name.**
One source tree is published under several names
([`branches/flavors/`](/handbook/branches/flavors/README.md)),
so prose that calls the package `duckdb` is wrong under every
other flavor: write "the package", or say how to ask for the name.
The repository (`duckdb-r`), the engine and upstream project
(DuckDB), and a flavor named as a flavor (`duckdb` among them)
are not violations.

**An absorbed file goes away.**
There are no tombstones:
a `.md` whose content has landed in a leaf is deleted,
not left behind as a one-line redirect.
What replaces it is the **in-place `README.md`** —
the index GitHub renders when someone browses to that directory.
The index is generated, one row per file,
grouped by the handbook leaf that owns each file's topic
([`scripts/README.md`](/scripts/README.md) is the worked example);
regenerating it is how it stays true,
and the generator's file-to-leaf mapping is what a change edits,
never the rendered table.
A file only partly absorbed keeps its remaining sections,
and each absorbed heading becomes a one-line pointer to the leaf.

**A backreference is how a leaf is discovered from the source tree.**
Someone standing in `scripts/` finds the leaf that explains what they
are looking at without knowing the handbook exists —
which is the whole point, and the reason absorbing content
never strands the reader who goes looking at the old address.
The generated index carries the backreference for every file it covers —
today that is `scripts/` alone,
and extending the generator to the other directories that hold
documentation is open work, not a settled shape.
Where no index covers a document, it carries its own:

* *Markdown* — a visible italic line directly under the H1,
  linking the leaf by repo-relative path.
  Several leaves serving one file share the one line.
  This holds for the root `README.md` too,
  which already links `AGENTS.md` and `plan/README.md` the same way
  even though CRAN renders it from a tarball
  where `.Rbuildignore` has removed them.
* *Source files* — a plain source comment,
  above the roxygen block or below the script's one-line header.
  Never a roxygen `#'` line:
  `handbook/` is `.Rbuildignore`d,
  so a reference page linking into it would be broken for users.
* *Generated files* — the backreference belongs in the **generator**,
  in the template the generated file is rendered from,
  so that it survives the next regeneration.
  Editing the generated file to add one is writing in sand.

Two kinds of file take no backreference at all.
A file covered by a generated index is already carried by it.
And **outbound correspondence takes none** —
`cran-comments.md` is not documentation of a topic
but a letter whose whole text reaches a CRAN maintainer verbatim,
so the link to it is one-way,
and that asymmetry is correct rather than an orphan.

**A link that leaves its own directory
is written from the repository root**,
with a leading `/` — `/handbook/usage/types/`, not `../../usage/types/`. GitHub resolves such a link against the
repository root and rewrites it for whatever branch the reader is on,
so it works unchanged on `main`, on a pull request head, and in a fork.
Same-directory and downward links stay relative, as they are already
correct and already short.
The tree is four levels deep in places,
and a `../../../../` chain is both unreadable and wrong the moment a
page moves — which, in a hierarchy that is still settling, it will.
This follows the
[Google Markdown style guide](https://google.github.io/styleguide/docguide/style.html#links),
which discourages exactly the upward form and nothing else.
The cost is that such a link does not resolve
in a local Markdown preview, which has no notion of a repository root;
the handbook is read on GitHub, and that is the trade taken.

**A leaf states what stays true as the code moves.**
A number that a normal commit invalidates —
how many translation units, how many test files,
how many seconds a build takes —
is not a fact worth stating but a hostage to the next contributor,
and a reader who trusts it is worse off than one who looked.
Name the mechanism instead:
the file that lists the translation units is durable,
the count is not.
Where the count carries no argument, cut it;
where a qualitative statement will do, prefer it.
Two things survive this rule.
A measurement stays if the text says it is a measurement
and against what — a measurement with provenance ages honestly,
where a bare number pretends to be current.
And a count stays when it *is* the design:
the two version counters, the states of the release machine.
Changing a load-bearing number means changing the design,
which is exactly why stating it is safe.

The working test is whether the prose names its members.
"Two identifiers travel with the vendored copy" is durable
when the next clause names both,
because the set cannot change without the sentence changing with it;
"forty-four files register S4 methods this way" is a hostage,
because nothing in the sentence breaks when the forty-fifth lands.
A list is safe, a tally is not,
and the same number can be either depending on what surrounds it.

**A fact known to be provisional carries the link to what will change it.**
The rules already say a leaf points at the plan
that carries its intent;
intent also lives as an issue, ours or upstream,
and those count the same.
Without the link a reader cannot tell
"this is how it works" from "this is how it works for now",
and the two call for different decisions.
With it, the leaf records that we already know —
so the next reader does not re-derive the finding,
and the acknowledgement is not lost
the way it is when it lives only in a code comment
or a pull-request thread.
A behaviour that survives only because nobody has fixed it yet
is documented as such, with its issue,
and stops being documented that way when the issue closes.

A **default is a fact**, and belongs in the prose with its value.
How many commits a pass consumes,
how large a chunk the planner cuts,
what a knob does when nobody sets it —
these govern behaviour,
and a reader who has to open the script to learn them
has been sent away for the thing they came for.
Name the value *and* where it is set,
so the leaf stays useful when the two drift apart —
and when a document has long claimed the wrong default,
say so, or the wrong number comes back.

Positional reference fails the same way.
"Neither of the first two is in force"
and "the first two, as `$pkg` and `$env`"
break silently when a list above them is reordered,
which is not even a change to the subject matter.
Name the thing.

All prose in the tree uses [semantic line breaks](https://sembr.org).

## Enforcement

Consistency is agent work.
The checks — every source path maps to a leaf,
every secondary document backreferences its node,
every link resolves, generated indexes are fresh,
every leaf's depth matches its deepen line —
run as the `docs-consistency` skill
(`.claude/skills/docs-consistency/`),
invoked when documentation is touched
and periodically as a routine.
Helper scripts do the mechanical parts
(extraction, rendering, link walking, diffing);
the skill owns the judgment —
whether a mapping is right,
whether a header says what its file does.
Helpers are not entry points of their own:
every check that matters is reachable through the skill,
and the skill covers the whole source tree,
not one directory at a time.
