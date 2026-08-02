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
  and an internal node never repeats it —
  the shape a principle takes, and the tests that keep it
  from becoming a summary, are among [the forms](#the-forms).
  An area whose leaves share no such constraint gets no principle;
  a node reaching for one is navigating, which was always enough.
  The root additionally sketches each area's contents,
  naming the next level in prose —
  names, not links, so the sketch cannot rot.
* **Leaves explain, once.**
  A leaf page owns its topic;
  other pages link to it and never paraphrase it.
* **Leaves own their boundaries.**
  A leaf states not only how its topic works
  but also its limits, its declined requests with their reasons,
  and — where intent exists — a pointer to the plan that carries it.
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
* **Stubs are visible debt.**
  A leaf that is not yet written says so in its first line
  and routes to where the knowledge lives today.

## Writing a leaf

Every stub ends with a "To write this leaf" section:
that leaf's parameters — sources to absorb, issues to drain,
facts to verify.
The protocol is the same for every leaf,
and it is written for an agent starting with clean context:

* **Move, don't copy.**
  Absorbed text leaves its old home in the same change,
  replaced by a pointer to the leaf.
  Every secondary surface the leaf serves —
  a root `README.md` section, a reference page,
  a directory index — gains a backreference to the leaf.
  Free-floating `.md` files shrink as their content lands here;
  a fully absorbed file goes away, and its directory's in-place
  `README.md` — the index GitHub renders there — routes on in its place.
* **Verify before you state.**
  Check every behavioral claim against the ground truth the stub
  names; check engine-configuration claims against a vendored
  build, never under `DUCKDB_R_USE_SYSTEM_LIB=1`.
* **Drain the issues.**
  An issue listed in the stub closes when its answer is written
  into the leaf; link the issue from the text that answers it.
  Start from the triage (`operations/triage/` names the source):
  for many listed issues the answer is already drafted there —
  consume it, don't re-derive it.
  An issue whose verdict is a fix stays open;
  the leaf states today's behavior and links it as a boundary.
* **Stay inside the scope line.**
  A fact beyond it belongs to another leaf — link, don't absorb.
* **Finish clean.**
  Delete the "To write this leaf" section and the stub notice;
  keep internal nodes navigation-only;
  leave no dangling links.

## The forms

The rules above say what a page must do;
these are the shapes the tree has settled on for doing it.
They exist so that leaves written independently read as one document.

**A written leaf** opens with its H1
and then a scope sentence in ordinary prose —
no `Scope:` label, that scaffolding belongs to stubs —
and continues with the content.
The scope sentence survives the stub because the tree's shape
depends on every leaf declaring its boundary.
A one-screen leaf needs no headings; a longer one uses `##`.

**A principle on an internal node** is a short paragraph, or a few of them,
between the scope sentence and the list of children.
It survives three tests,
and a sentence that fails any one of them belongs to a leaf instead:

* **It cannot be checked by reading one leaf.**
  A statement a single child settles is that child's.
  A principle is confirmed only by reading the children together,
  or by looking at how the area is divided at all.
* **It has the lifetime of the child list.**
  An internal node may go stale only when its children change,
  which is when the node is being edited anyway.
  A sentence an ordinary commit to the package could falsify
  is a fact, and every fact has a leaf.
* **It names no particulars.**
  No paths, script names, environment variables, versions, counts,
  commands, or tables — that is the vocabulary of facts.
  A principle that needs one of them to be understood
  is a summary of the leaf that owns it.

Where a node's links may go follows from the same tests.
An internal node links to its own children,
and to another area's node where it draws a boundary against it;
a link *into* a leaf is the node reaching for that leaf's evidence,
which means the sentence was the leaf's all along.
This is what preserves the guarantee that navigation-only bought:
a paraphrase of the leaves below fails all three tests at once,
so the rule that admits principles still excludes summaries.

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

**A link that leaves its own directory is written from the repository
root**, with a leading `/` — `/handbook/usage/types/`, not
`../../usage/types/`. GitHub resolves such a link against the
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
The cost is that such a link does not resolve in a local Markdown
preview, which has no notion of a repository root;
the handbook is read on GitHub, and that is the trade taken.

Prose absorbed into a leaf may be rewritten —
the handbook's voice is tighter than its sources' —
but a rewrite that loses a fact is a regression, not an edit.
All prose in the tree uses [semantic line breaks](https://sembr.org).

## Enforcement

Consistency is agent work.
The checks — every source path maps to a leaf,
every secondary document backreferences its node,
every link resolves, generated indexes are fresh,
stubs carry their work orders —
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
