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
