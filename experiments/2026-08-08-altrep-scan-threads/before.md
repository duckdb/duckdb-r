# Before: the scan reaches into the column itself

`run.sh` on duckdb 1.5.5.9012 at 027c467, the tree before
`TouchColumn()`, where `GetColDataPtr()` hands a struct column back
unread and `AppendStructColumnSegment()` takes its children's pointers
on the scan thread.

```
$ ulimit -c 0
$ N_ROWS=3000000 experiments/2026-08-08-altrep-scan-threads/run.sh 10
attempts per cell: 10
rows: 3000000
R: R version 4.5.3 (2026-03-11)
duckdb: 1.5.5.9012
cores: 4

field=int threads=1  match=10 mismatch=0 error=0 killed=0
field=int threads=2  match=0 mismatch=10 error=0 killed=0
field=int threads=4  match=0 mismatch=10 error=0 killed=0
field=str threads=1  match=10 mismatch=0 error=0 killed=0
field=str threads=2  match=0 mismatch=0 error=10 killed=0
field=str threads=4  match=0 mismatch=2 error=0 killed=8
```

A `match` at `threads=1` is the control: the same code path, one task,
no second thread on the column.

The numeric field is silent. One attempt, verbatim:

```
n=3000000 threads=4 field=int expected=4499998500000 actual=1997948903872 MISMATCH
```

The character field is not. Every failing attempt fills the terminal
with

```
*** recursive gc invocation
```

— R's own guard against a collection starting inside a collection — and
then ends one of two ways. Ten of them stopped R:

```
Error in trace_back() : cannot get ALTVEC DATAPTR during GC
Execution halted
```

and eight died on a signal, `killed` counting exit status 134, SIGABRT:

```
*** stack smashing detected ***: terminated
```

## Two million rows

Three attempts per field at the size the regression test uses, where the
split gives the scan two tasks rather than three. Both fields answer
wrongly, every time, and nothing dies — which is why the test asserts a
sum rather than a survival, and runs in a subprocess anyway.

```
$ for f in int str; do for i in 1 2 3; do
    N_ROWS=2000000 THREADS=4 FIELD=$f Rscript experiments/2026-08-08-altrep-scan-threads/scan.R
  done; done
n=2000000 threads=4 field=int expected=1999999000000 actual=1997948903872 MISMATCH
n=2000000 threads=4 field=int expected=1999999000000 actual=1997948903872 MISMATCH
n=2000000 threads=4 field=int expected=1999999000000 actual=1997948903872 MISMATCH
n=2000000 threads=4 field=str expected=20888890 actual=11253805 MISMATCH
n=2000000 threads=4 field=str expected=20888890 actual=11235904 MISMATCH
n=2000000 threads=4 field=str expected=20888890 actual=11186053 MISMATCH
```
