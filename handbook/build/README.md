# `build/`

Turning the tree into an installed package, at every speed.
There is one build; the rest of this area is ways of doing less of it,
and the knobs that steer both.

**What ships is the plain build.**
Every shortcut is a development and CI convenience,
never a second distribution model:
the package most users install always compiles the vendored sources.

**A shortcut fails loudly or not at all.**
Anything that skips work also proves it was entitled to skip it,
and stops the build where it was not —
the failure this area guards against is not a slow build
but a fast one that produced something other than the package.

* [`source-build/`](source-build/) — `configure`, Makevars, the tarball
* [`fast-paths/`](fast-paths/) — prebuilt libduckdb in seconds
* [`configuration/`](configuration/) — the build knobs
