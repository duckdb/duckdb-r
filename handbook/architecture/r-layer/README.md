# The R layer

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](../../meta/handbook/);
the last section holds this leaf's parameters.*

Scope: the file-per-method layout, generated files,
the `get_package_name()` flavor seam, S4 classes,
and deferred S3 registration.

Today:

* [`AGENTS.md`](../../../AGENTS.md) — "Never Hard-Code the Package Name"

To write this leaf:

* absorb: `AGENTS.md` § "Never Hard-Code the Package Name"
  (the `get_package_name()` seam table) and the one-file-per-method
  layout; document the generated files (`R/cpp11.R`,
  `R/rethrow-gen.R` from `scripts/rethrow.R`) and their regenerators
* drain: #98, #1052
