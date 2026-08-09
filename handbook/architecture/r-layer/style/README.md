# Style

How the R in this package is written —
names, signatures, messages, reference prose —
and the deviations from the guides that decide it.
Where that code lives and what generates it is
[`conventions/`](/handbook/architecture/r-layer/conventions/README.md).

Two guides decide this, and neither is restated here:
the [tidyverse style guide](https://style.tidyverse.org/)
for how code reads,
and [tidy design principles](https://design.tidyverse.org/)
for what an interface promises.
Follow them by default, in `R/` and in the tests alike.
What this page adds is the handful of rules a change here
is most often caught on,
and the deviations — which are the reason the page exists,
since everything else is a link.

## The rules worth spelling out

**Layout is the formatter's, not the reviewer's.**
Indentation, line breaks, spacing and call wrapping are
[air](https://posit-dev.github.io/air/)'s output,
and no review argues them.
Nothing runs air over this repository today:
the pull-request formatter
([`.github/workflows/style/action.yml`](/.github/workflows/style/action.yml))
reformats R only when the repository carries an `air.toml`,
and this one carries only `.clang-format`,
so that job formats the C++ and leaves the R alone.
`R/` and `tests/` have drifted from what air prints as a result,
which makes reformatting-in-passing expensive:
until the config lands
([#2614](https://github.com/duckdb/duckdb-r/issues/2614)),
a change matches the file it is editing
and leaves the lines it did not come for alone.

**An error message is a contract, not a sentence.**
The guide's [error chapter](https://style.tidyverse.org/errors.html)
assumes `cli::cli_abort()`, which this package cannot call
([below](#where-this-package-deviates));
its wording rules survive the downgrade to `stop()` intact,
and they are what a review checks.
A problem statement first, in sentence case, ending in a full stop;
**must** where the expectation can be stated
("`n` must have length 1, not length 2")
and **can't** where it cannot;
the offending argument in backticks,
and what the caller actually passed rather than only what was wanted.
It is raised with `call. = FALSE`, and through rlang where that is
installed, as the `rethrow_` wrappers do — so the message points at the
user's call and not at the internal check that noticed
([#2615](https://github.com/duckdb/duckdb-r/issues/2615),
which both spellings in the tree are still being converted to).

**`...` goes after the required arguments**
([design guide](https://design.tidyverse.org/dots-after-required.html)),
which forces every optional argument to be named at the call site
and lets a later one be added without breaking a positional call.
Required arguments take
[no default](https://design.tidyverse.org/required-no-defaults.html),
so the signature alone says what is optional.
An argument whose values are a small set of strings
[enumerates them](https://design.tidyverse.org/enumerate-options.html)
as its default and resolves it with `match.arg()`,
putting the allowed values where autocomplete and tooltips show them —
`tz_out_convert = c("with", "force")` is the form to copy.
A `...` that exists only to force naming is checked to be empty
rather than quietly ignored, and never also forwarded.

**snake_case for everything this package names**,
and `TRUE`/`FALSE` never abbreviated to `T`/`F`,
which are ordinary variables and can be reassigned.
The camelCase in `R/` is DBI's, and it stops at the generic:
a helper, an argument, a local, or a test file this package invents
is snake_case whatever the generic above it is called.

**Reference pages are markdown roxygen.**
`Roxygen: list(markdown = TRUE)` is set in
[`DESCRIPTION`](/DESCRIPTION), so a cross-reference is `[dbConnect()]`
and code is backticked;
a few pages still carry the older `\code{\link{}}` spelling
([#2616](https://github.com/duckdb/duckdb-r/issues/2616)),
and converting one is an ordinary edit.
Each `@param` is a sentence — capitalised, ending in a full stop.

## Where this package deviates

* **DBI names the generics, and the method files follow.**
  `dbConnect()`, `dbWriteTable()`, and the `<generic>__<signature>.R`
  files are the standard's spelling and the dispatch's, not a house style.
* **DBI names some arguments too**, in base R's dot.case —
  `row.names`, `field.types`.
  A method implements its generic's signature exactly,
  so these are copied rather than chosen.
  `duckdb_read_csv()` is dot.case throughout for the same reason
  one level down — it forwards to `utils::read.csv()` — and it is
  published, so it keeps the spelling it shipped with.
* **`duckdb()` and `dbConnect()` carry optional arguments before `...`.**
  The design guide would put them after.
  Both signatures are published and called positionally in the wild,
  so moving one is a breaking change and they stay as they are;
  an argument added to either goes after the `...`,
  and a new function has nothing before it that is not required.
* **cli and rlang are not dependencies.**
  Both are `Suggests`, so the guide's `cli_abort()` examples
  become `stop()` here, and its bulleted structure and inline markup
  are not available — the wording rules above are all a message has.
  [`R/rlang.R`](/R/rlang.R) holds base fallbacks for the few rlang
  functions the package uses, swapped for the real ones at load
  when rlang is installed.

*To deepen: state the rules once the three sweeps that make the code
match them have run — `air.toml`
([#2614](https://github.com/duckdb/duckdb-r/issues/2614)),
the error-raising spelling
([#2615](https://github.com/duckdb/duckdb-r/issues/2615)),
and the roxygen conversion
([#2616](https://github.com/duckdb/duckdb-r/issues/2616)) —
and add the rules a review has enforced twice since.*
