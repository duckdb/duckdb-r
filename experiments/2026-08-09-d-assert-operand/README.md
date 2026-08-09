# What a release-build `D_ASSERT` could say about its operand

*What it measures:* whether `D_ASSERT` can be made to keep its condition
named in a release build — so a binding or helper that exists only for an
assert is still "used" — what that costs, and what it would retire.

*When and on what:* 2026-08-09, against the engine vendored that day,
on Linux x86_64 with GCC 13.3 and Clang 18.1, R 4.5.3.
Two runs: [`forms.cpp`](forms.cpp) over four spellings of the macro
([`forms.out`](forms.out)), and the whole tree compiled with the winning
one and the two patches it would replace reverted
([`tree.out`](tree.out), via
[`scripts/warnings.sh`](/scripts/warnings.sh)).

*What it supports:* why
[`patch/0036`](/patch/0036-Mark-two-assert-only-bindings-used.patch) and
[`patch/0037`](/patch/0037-Compile-an-assert-only-helper-only-when-asserts-are-on.patch)
fix their two sites locally instead of fixing the class at the macro,
and what an upstream proposal would have to carry
([`build/warnings/`](/handbook/build/warnings/README.md)).

## Why the question comes up

Outside a debug build `D_ASSERT` **is** `assert`, and with `NDEBUG` the C
standard requires `assert(x)` to expand to `((void)0)`.
The operand is discarded without being parsed,
so nothing in it is used — or even type-checked.
A binding that appears only inside a `D_ASSERT` is therefore genuinely
unused in a release build, which is what `-Wunused-variable` reports and
what those two patches answer, one site at a time.

A macro that named the operand without evaluating it would answer the
whole class at once, including the sites a future vendor bump brings in.

## The spelling matters more than it looks

Four candidates, in `forms.cpp`, against four shapes: a binding used only
by an assert, a static function called only from one, a bit-field
condition, and a condition with no conversion to `bool`.

* `((void)(sizeof(condition), 0))` is the most faithful to `((void)0)` —
  the expansion's *value* is literally `0` — and it fails twice.
  GCC reports **every** expansion under `-Wall`
  ("left operand of comma operator has no effect", `-Wunused-value`),
  which floods the build the macro exists to keep clean;
  and `sizeof` applied directly to a bit-field is ill-formed, so
  `D_ASSERT(bits.flag)` stops compiling on both compilers.
* `((void)sizeof((condition) ? 1 : 0))` is quiet on both.
  The `? 1 : 0` is load-bearing twice over: it makes a bit-field operand
  an rvalue, and it keeps the comma out of the expansion.
* `((void)sizeof((condition) ? 1 : 0), (void)0)` buys back the literal
  `(void)0` ending — casting the left operand to void is what silences
  GCC — and behaves identically to the previous one in every case here.
  The faithfulness is free but also worth nothing measurable.

**The winning form checks more than it silences.** It requires the
condition to be contextually convertible to `bool`, so a nonsensical
assert becomes an error in release too — matching what a debug build
already enforces. Today `D_ASSERT(some_struct)` compiles in release and
breaks only under `-DDEBUG`.

**It does not cover assert-only *functions* on Clang.** A static function
referenced only from an unevaluated operand draws
`-Wunneeded-internal-declaration` ("is not needed and will not be
emitted"), which Clang's `-Wall` enables. GCC is quiet. So `0037`'s
`#ifdef` would survive the macro; only `0036` is retired.

## Whole-tree: it compiles, and it finds three dead asserts

All 341 vendored translation units compile with the macro in place —
every `D_ASSERT` in the engine does type-check as a condition, which is
the question that decides whether the macro is available at all.

It is not free, though. Three assert operands that were never parsed turn
out to be vacuous, all of them `>= 0` on an unsigned value:

* `lru_cache.hpp:151` — `current_total_weight -= …;` immediately followed
  by `D_ASSERT(current_total_weight >= 0);`. The assert is plainly there
  to catch the subtraction underflowing, and on an unsigned type it can
  never fire. This one is a real broken invariant check, not a tidiness
  finding.
* `iterator.hpp:74` and `:108` — `size() >= 0` and `count >= 0`,
  harmlessly always true.

So adopting the macro trades two patches for one patch plus three sites,
and the fix for a vacuous assert is to correct or delete it, which is
upstream's call. That is the argument for proposing the macro to
`duckdb/duckdb` rather than carrying it here: its value is engine-wide,
and so is the cleanup it demands.
