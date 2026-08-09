# Telling a session its dbplyr is too old

*What it measures:* which R API reports the version of the dbplyr a
session has actually *loaded* rather than the one now sitting in the
library, when a `packageEvent()` hook fires, and what a condition raised
from inside one can and cannot do to the load it interrupts.

*When and on what:* 2026-08-09, Linux x86_64, R 4.5.3,
dbplyr 2.6.0 from the ordinary library and dbplyr 2.5.0 from the
Posit Package Manager snapshot `2025-06-02`.
Three scripts, each with its recorded output:
[`version-apis.R`](version-apis.R) / [`.out`](version-apis.out),
[`hook-mechanics.R`](hook-mechanics.R) / [`.out`](hook-mechanics.out),
[`orders.R`](orders.R) / [`.out`](orders.out).

*What it supports:* the dbplyr floor and its warning in
[`usage/integrations/`](/handbook/usage/integrations/README.md).

## Why a warning at all

[#1982](https://github.com/duckdb/duckdb-r/issues/1982) moved
`n_distinct()` off dbplyr's private `glue_sql2()` and onto the exported
`sql_glue()`, which dbplyr 2.6.0 is the first release to carry.
`Suggests` now floors dbplyr at 2.6.0, but a `Suggests` floor is
advisory: nothing stops an older dbplyr from being loaded next to this
package, and the failure it produces then — `could not find function
"sql_glue"`, from inside a translation — names neither package nor
remedy.

## `packageVersion()` answers a different question

Both APIs read the *loaded namespace's path*, so `pkgload::load_all()`
on a source tree is not where they part company: both report the tree's
version. They diverge when the library copy at that path is replaced
while the session runs, which is what `install.packages()` does:

```
loaded 1.0.0        packageVersion()=1.0.0  getNamespaceVersion()=1.0.0
library now 2.0.0   packageVersion()=2.0.0  getNamespaceVersion()=1.0.0
```

The session is still running 1.0.0 and will until R restarts.
`packageVersion()` re-reads the installed metadata each call and so
reports the upgrade immediately; `getNamespaceVersion()` returns the
`"spec"` recorded when the namespace loaded, which is the version whose
code is actually reachable.

That difference is the whole point here, not a technicality. Measured
end to end: a session holding dbplyr 2.5.0 that then installs 2.6.0
still has no `sql_glue()` in its namespace, so `n_distinct()` is still
broken — and a `packageVersion()` check would have gone quiet at exactly
the moment the warning is worth reading, since its remedy is *restart R*.

The package already reads its own version this way, through
`get_package_version()`; `loaded_dbplyr_version()` is the same move
pointed at a soft dependency.

## The hook catches a load, not an attach

`setHook(packageEvent("dbplyr", "onLoad"), …)` fires on
`loadNamespace()`, so it catches `dbplyr::x` and dbplyr arriving as
somebody else's dependency, not just `library(dbplyr)`. The version is
readable by the time it runs. It fires once per namespace load, which is
why `.onLoad()` arms it: `.onAttach()` runs again after every
`detach()`/`library()` cycle and would stack duplicates.

The hook can only ever catch dbplyr loading *after* this package. The
other order — dbplyr already loaded when this package is attached —
never fires it, and is covered by a check in `.onAttach()`.

## `warning()` is safe here, and harder to lose

Raised from inside a hook, a `warning()` cannot break the load it
interrupts: R calls hooks under `try()`, so even `options(warn = 2)`
turns it into a caught-and-printed error while `library(dbplyr)`
completes and attaches.

`suppressPackageStartupMessages()` does not muffle it, where it does
muffle `packageStartupMessage()`. For an incompatibility that will
produce a real failure later, surviving the suppression a user applies
out of habit is the property worth having.

One detail: without `call. = FALSE`, R attributes the warning to its own
hook caller — `In fun(pkgname, pkgpath) : …` — which tells a reader
nothing.

## As shipped

Against a real dbplyr 2.5.0, one warning arrives in each order that puts
both packages in a session, and nothing arrives when it should not:

* dbplyr loaded first, then this package attached — warns at attach.
* This package attached first, then dbplyr loaded — warns from the hook.
* This package loaded but never attached, then dbplyr — warns from the
  hook. The backend is reachable through `dplyr::tbl()` without ever
  attaching this package, so the check follows *loaded*, not *attached*.
* Current dbplyr, either order — silent.
* This package attached with dbplyr absent — silent, and dbplyr is not
  loaded to find out.
* dbplyr 2.5.0 loaded, then upgraded to 2.6.0 mid-session — still warns,
  because the session still has no `sql_glue()`.

The false positive this accepts: a session that loads both packages but
drives dbplyr against some other backend is warned about a translation
it will never call. It is warned anyway, because by then this package
has already registered its methods into dbplyr, and distinguishing the
two would mean waiting for a failure that the warning exists to
pre-empt.
