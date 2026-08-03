# `releases/`

From a green branch to CRAN.

**A release asserts what it is; it derives nothing.**
The commit that ships, the version it carries, the policy revision
that was read — each is named explicitly when it is decided,
never computed from something adjacent
that would be right until it silently was not.

**The rules are other people's.**
The cadence is upstream's, the acceptance criteria CRAN's,
and the tools that write the version and the changelog
have behaviour of their own —
so these leaves describe compliance rather than design,
and each says where it read its constraint.

* [`process/`](process/) — the release state machine
* [`cran/`](cran/) — submission and policy
* [`versioning/`](versioning/) — counters, fledge, NEWS
