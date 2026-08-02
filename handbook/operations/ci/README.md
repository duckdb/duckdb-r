# `ci/`

What CI runs, what fires it, and what it gates.

**The unit is the commit, not the run.**
Verdicts attach to commits and outlive the runs that produced them,
so a lost or repeated run changes nothing that was already decided.

* [`workflows/`](workflows/) — the workflow inventory
* [`per-commit/`](per-commit/) — `each`, `rcc`, the verdict store
* [`matrix/`](matrix/) — platforms and R versions
