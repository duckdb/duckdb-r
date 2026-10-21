# `branches/`

What a ref in either repository means, and what holds it there.

**The refs are the interface.**
Every ref has one meaning and one allowed motion,
so a reader — human or automation — acts on a ref
without having to read the full history behind it.

* [`model/`](model/) — series and their refs
* [`mirrors/`](mirrors/) — the canonical branches the fork also carries
* [`flavors/`](flavors/) — one source, many package names
* [`invariants/`](invariants/) — what every series guarantees
