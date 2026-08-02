# `releases/`

From a green branch to CRAN.
The area divides into the sequence, the destination's demands,
and the number the result carries.

**A release asserts what it is; it derives nothing.**
The commit that ships, the version it carries, the revision of the policy
that was read — each is named explicitly at the moment it is decided,
rather than computed from something adjacent
that would be right until it silently was not.
That is why so much of what follows is a value set once by a person,
with a record of its having been set,
and why automation here prepares and reports but never concludes.

**The rules are other people's.**
The cadence belongs to upstream, the acceptance criteria to CRAN,
and the tools that write the version and the changelog have behaviour
of their own.
So these leaves describe compliance rather than design,
and where they do record a decision it is a decision about how to comply.
It also means a fact here can stop being true
without anything in this repository changing,
which is why each leaf says where it read its constraint
rather than merely stating it.

* [`process/`](process/) — the release state machine
* [`cran/`](cran/) — submission and policy
* [`versioning/`](versioning/) — counters, fledge, NEWS
