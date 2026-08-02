# `build/`

Turning the tree into an installed package, at every speed.
There is one build; the rest of this area is ways of doing less of it,
and the knobs that steer both.

**What ships is the plain build.**
Every shortcut here is a development and CI convenience,
never a second distribution model:
the package a stranger installs always compiles the vendored sources.
A saving that would have to be reproduced on that stranger's machine
is not a shortcut but a change to what the package is,
and is decided outside this area.

**A shortcut fails loudly or not at all.**
Anything that skips work also proves it was entitled to skip it,
and stops the build where it was not.
The failure this area is built against is not a slow build
but a fast one that produced something other than the package —
which is dangerous precisely because it looks like success,
and which nothing downstream of the build is positioned to notice.

* [`source-build/`](source-build/) — `configure`, Makevars, the tarball
* [`fast-paths/`](fast-paths/) — prebuilt libduckdb in seconds
* [`configuration/`](configuration/) — the build knobs
