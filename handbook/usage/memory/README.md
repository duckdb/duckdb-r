# `memory/`

What a query costs in memory on both sides of the R boundary,
what bounds each side,
and how far external storage extends what a session can process.
The routes into and out of the engine are
[`integrations/`](/handbook/usage/integrations/README.md)'s;
the leaves here are what each of them allocates, and for how long.

**Two allocators, one sum.**
The engine's memory is budgeted and backed by disk;
R's is neither, and no engine setting reaches it.
A session's footprint is the two together,
and each side is blind to the other's share.

**Below the buffer pool, data moves one way.**
Disk and the pool exchange data in both directions,
so anything the engine holds can be paged, spilled, or written out;
a result on its way to R only ever moves toward R,
and an R vector never moves back.
External storage therefore helps exactly as far as the engine reaches,
and processing more data than fits means keeping the large side
engine-side and letting only reductions or batches cross.

```text
 database file  ◄──► ┌───────────────────────────────┐
 spill files    ◄──► │ buffer pool — table blocks,   │  budgeted
 Parquet, CSV   ───► │ query state, temp tables      │
                     └──────────────┬────────────────┘
                                    │ execute
                     ┌──────────────▼────────────────┐
                     │ result copies in flight:      │  engine heap
                     │ a collection, or a stream     │
                     └──────────────┬────────────────┘
                                    │ convert — whole or batch
                     ┌──────────────▼────────────────┐
                     │ R vectors                     │  unbounded, freed
                     └───────────────────────────────┘  by R's collector
```

* [`budget/`](budget/) — what `memory_limit` bounds and what escapes it,
  the engine's ledger, spill, what external storage buys
* [`reading/`](reading/) — what a result costs on its way into R, per route,
  and which routes carry more than fits
* [`writing/`](writing/) — what writing into the engine costs,
  and what an open transaction holds
