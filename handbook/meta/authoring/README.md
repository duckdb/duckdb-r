# Authoring

How the prose of a handbook page is written —
the rules an author follows and a review enforces, owned here in full.
The tree's structure, its growth moves, and their enforcement are
[`meta/handbook/`](/handbook/meta/handbook/README.md)'s;
extending the tree means following this page —
absorption is rewriting, never blind copy-paste,
and a rewrite that loses a fact is a regression, not an edit.

* **Break lines at meaning boundaries**
  ([semantic line breaks](https://sembr.org)):
  widen a line rather than split a phrase;
  never leave a one-word line,
  and never break one word before a comma.
  A long link or code token may stand alone.
* **Default to a bullet list; make a table earn its columns.**
  A list extends one line at a time and diffs the same way,
  so an enumeration is bullets, each item led by its name.
  A table is for genuinely two-dimensional content,
  where the reader compares along both axes;
  a two-column table whose second column is prose
  is a list wearing borders.
* **State the rule, cut the war story:**
  failure narratives and history live in git and issues, not in leaves;
  hold a topic to one screen at core depth.
* **Guard a recurring failure; document only what a guard cannot catch.**
  A trap that keeps happening deserves a check that refuses it,
  not a paragraph asking readers to remember —
  and when a guard is out of reach,
  the leaf gets the trigger and the action, never the anatomy.
* **Describe by property and name the authoritative artifact:**
  never re-enumerate what a file already lists —
  the file is the list —
  and never exhaustively enumerate facts another leaf owns:
  state the principle that locates them, and stop.
* **Explain once:**
  when another leaf, a file header, or a reference page owns a fact,
  link it — never restate it.
* **Leave a breadcrumb where the reader stands.**
  When detail moves into a leaf,
  the source it came from — a document, a script header,
  an inline comment — keeps its essentials
  and links the leaf that now carries the rest,
  so a fact is edited in one place
  and found from the place it is about.
* **State what stays true as the code moves:**
  a number an ordinary commit invalidates is a hostage —
  name the mechanism instead:
  the file that lists the members is durable, the count is not.
  A list that names its members is safe where a tally is not.
  A measurement stays when the text says it is one, and against what;
  a count stays when it *is* the design,
  like the version counters or the release machine's states.
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
* **Write links that leave their directory from the repository root**,
  with a leading `/` —
  GitHub resolves them against the root on any branch or fork;
  same-directory and downward links stay relative.
  Such links do not resolve in a local preview;
  the handbook is read on GitHub, and that is the trade taken.
* **Verify before you state**,
  on a build that can show the claim:
  the fast path links a release library
  with its own extension set and defaults,
  so a claim those could distort needs a vendored build —
  for everything the two builds share, either will do.
* **When a claim is contested or surprising, check the ground truth**
  (run the diff, read the script) and discuss before editing.

*To deepen: add a rule when a review has enforced it twice.*
