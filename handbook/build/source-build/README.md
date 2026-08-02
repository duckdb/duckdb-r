# Source build

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](../../meta/handbook/);
the last section holds this leaf's parameters.*

Scope: `configure`, `src/Makevars.in` and the `.mk` includes,
`.dd` dependency files, and the tarball layout.

Today:

* [`AGENTS.md`](../../../AGENTS.md) — "Bootstrap, Build, and Test the Repository"

To write this leaf:

* absorb: `AGENTS.md` § "Bootstrap, Build, and Test the Repository",
  including the `UserNM` warning — never export it for `R CMD check`,
  it blinds the `nm` symbol scan;
  own `configure`, `src/Makevars.in`, the `.mk` includes,
  and the `.dd` dependency rules
* drain: #2234
