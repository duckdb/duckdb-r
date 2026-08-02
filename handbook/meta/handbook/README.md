# The handbook's rules

The handbook is a strict topic hierarchy with full cover:
every aspect of this package that may need documentation
has exactly one place in this tree.

* **Internal nodes navigate, only.**
  An internal `README.md` is a scope sentence
  and a nested list of its subdirectories — nothing else.
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
  [`handbook/`](../../README.md);
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
  Free-floating `.md` files shrink as their content lands here;
  a fully absorbed file becomes a one-line tombstone.
* **Verify before you state.**
  Check every behavioral claim against the ground truth the stub
  names; check engine-configuration claims against a vendored
  build, never under `DUCKDB_R_USE_SYSTEM_LIB=1`.
* **Drain the issues.**
  An issue listed in the stub closes when its answer is written
  into the leaf; link the issue from the text that answers it.
* **Stay inside the scope line.**
  A fact beyond it belongs to another leaf — link, don't absorb.
* **Finish clean.**
  Delete the "To write this leaf" section and the stub notice;
  keep internal nodes navigation-only;
  leave no dangling links.
