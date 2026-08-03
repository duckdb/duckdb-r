# The handbook's rules

The handbook is a strict topic hierarchy with full cover:
every aspect of this package that may need documentation
has exactly one place in this tree.

* **Internal nodes navigate, and may govern.**
  An internal `README.md` is a scope sentence,
  optionally the principles that govern its area,
  and a nested list of its subdirectories —
  and, except at the root below, nothing else.
  A principle is why the area is divided as it is,
  or a constraint every leaf under it obeys;
  it belongs to the node because no single leaf could state it
  without reaching past its own scope.
  Anything one leaf could state is that leaf's,
  and an internal node never repeats it
  (the tests are among [the forms](#the-forms)).
  The root additionally sketches each area's contents,
  naming the next level in prose — names, not links,
  so the sketch cannot rot.
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
  Nothing announces such a defect — a homeless topic raises no error,
  it is simply absent — so full cover is a claim the tree has to be
  audited against, not one its shape can enforce.
* **A scope sentence states a boundary, not a child list.**
  A node that describes itself by naming what is under it
  cannot admit the topic it did not foresee:
  the wording excludes it, and no one notices, because the child list
  below says the same thing and agrees.
  So when a topic turns out to have no home,
  ask first whether a node's *wording* excluded it rather than its
  design — that is the cheaper defect, and the commoner one.
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
  [`meta/plans/`](/handbook/meta/plans/README.md) explains that directory
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

The tree deepens one leaf per change, by four moves.
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
   The fine print moves to the leaf in the same change;
   what stays behind is cut to what a reader standing there needs,
   and backreferences the leaf that now carries the detail.
   A source with nothing left worth keeping goes away entirely,
   and anything that linked to it is updated.
   The breadcrumb is the point:
   a fact that changes is edited in one place,
   and the reader who never heard of the handbook still finds it.
3. **Deepen from the ground truth.**
   Write what the code, scripts, and workflows actually do,
   and cite the file that proves it.
4. **Give a homeless topic a home.**
   Something tracked in this repository that no leaf covers gets one,
   born at reference depth: a scope sentence, where the knowledge lives
   today, and a deepen line naming the rest.
   The node above it gains a child-list entry, and a scope sentence too
   narrow to admit the new leaf is widened in the same change —
   otherwise the next topic of that kind falls out again.

Whichever move, the same protocol:

* **Register a term the tree reuses.**
  A term of art gets a glossary line linking its owning leaf,
  added by the change that coins it
  ([`meta/glossary/`](/handbook/meta/glossary/README.md)).
* **Follow [`meta/authoring/`](/handbook/meta/authoring/README.md).**
  Every sentence, new or absorbed, is walked down the ladder there
  before it is written — absorption is rewriting, never blind
  copy-paste.
* **Stay inside the scope line.**
  A fact beyond it belongs to another leaf — link, don't absorb.
* **Finish clean.**
  Update the leaf's closing deepen line — or delete it
  when nothing remains — and leave no dangling links.

## The forms

The rules above say what a page must do;
these are the shapes the tree has settled on for doing it.
They exist so that leaves written independently read as one document.
How the prose itself is written is `meta/authoring/`'s.

**A written leaf** opens with its H1
and then a scope sentence in ordinary prose,
and continues with the content.
The scope sentence is load-bearing at every depth:
the tree's shape depends on every leaf declaring its boundary.
A one-screen leaf needs no headings; a longer one uses `##`.

**A named part of a one-screen leaf** opens with a bold run-in phrase
rather than a heading;
headings start where a page is long enough to navigate.

**A link to a handbook page** names the directory in backticks
and targets its `README.md`.
An internal node's child list is the exception:
there the link text is the directory and so is the target,
because the list is the tree, not a citation.

**A deepen line** is the last line of a leaf
that is not yet comprehensive:
one italic sentence naming what deepening absorbs, verifies, or drains —
`*To deepen: absorb `BRANCHES.md` § …; drain #….*` —
kept current by every change to the leaf,
and deleted by the change that completes it.
A leaf with no deepen line asserts it is comprehensive.

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

**A link that leaves its own directory is written from the repository
root**, with a leading `/`;
same-directory and downward links stay relative,
and an upward `../` chain is never written —
it breaks the moment a page moves, and a page in a settling tree moves.
GitHub resolves a root-relative link on any branch or fork;
a local Markdown preview does not, and that is the trade taken.

**An absorbed file keeps its essentials, or goes away.**
A `.md` whose detail has landed in a leaf shrinks to the part
its own readers need and backreferences the leaf;
what it must not become is a one-line redirect.
A file with nothing left to keep is deleted, and its place is taken
by the **in-place `README.md`** —
the index GitHub renders when someone browses to that directory.
The index is generated, one row per file,
grouped by the handbook leaf that owns each file's topic
([`scripts/README.md`](/scripts/README.md) is the worked example);
regenerating it is how it stays true,
and the generator's file-to-leaf mapping is what a change edits,
never the rendered table.
A file only partly absorbed keeps its remaining sections,
and each absorbed heading becomes a one-line pointer to the leaf.
One directory never gets an in-place index:
a `.github/README.md` would be surfaced as the repository front page
(precedence `.github/` → root → `docs/`).

**A backreference is how a leaf is discovered from the source tree.**
Someone standing in `scripts/` finds the leaf that explains what they
are looking at without knowing the handbook exists.
The generated index carries the backreference for every file it covers.
Where no index covers a document, it carries its own:

* *Markdown* — a visible italic line directly under the H1,
  linking the leaf by repo-relative path.
  Several leaves serving one file share the one line.
  The root `README.md` is the exception:
  most of its readers arrive from CRAN, which renders it from a tarball
  `.Rbuildignore` has removed `handbook/` from,
  so its pointer lives in a Documentation section
  rather than above the first sentence about the package.
* *Source files* — a plain source comment,
  above the roxygen block or below the script's one-line header.
  Never a roxygen `#'` line:
  `handbook/` is `.Rbuildignore`d,
  so a reference page linking into it would be broken for users.
* *Generated files* — the backreference belongs in the **generator**,
  in the template the generated file is rendered from,
  so that it survives the next regeneration.
  Editing the generated file to add one is writing in sand.

A generated file that is already auto-linked to the source it derives from
takes no backreference; `man/*.Rd` is the only such case here.

## Enforcement

Consistency is agent work.
The checks — mechanical on shape, links and index freshness,
judgment on mapping and headers —
are the `docs-consistency` skill's
(`.claude/skills/docs-consistency/`), which is the list;
it runs when documentation is touched
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

*To deepen: the generated index covers `scripts/` alone;
extending it to the other directories that hold documentation
is open work this page will state once it is settled.*
