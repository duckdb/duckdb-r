# After: bind walks into the column first

`run.sh` on the same machine and the same day, with `TouchColumn()` in
`DataFrameScanBind()`.

```
$ ulimit -c 0
$ N_ROWS=3000000 experiments/2026-08-08-altrep-scan-threads/run.sh 10
attempts per cell: 10
rows: 3000000
R: R version 4.5.3 (2026-03-11)
duckdb: 1.5.5.9012
cores: 4

field=int threads=1  match=10 mismatch=0 error=0 killed=0
field=int threads=2  match=10 mismatch=0 error=0 killed=0
field=int threads=4  match=10 mismatch=0 error=0 killed=0
field=str threads=1  match=10 mismatch=0 error=0 killed=0
field=str threads=2  match=10 mismatch=0 error=0 killed=0
field=str threads=4  match=10 mismatch=0 error=0 killed=0
```

Sixty attempts, sixty right answers, and no `recursive gc invocation`
line in any of them.
