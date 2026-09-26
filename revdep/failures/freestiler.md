# freestiler (0.2.0)

* GitHub mirror: <https://github.com/cran/freestiler>

Run `revdepcheck::revdep_details(, "freestiler")` for more info

## In both

*   checking whether package ‘freestiler’ can be installed ... ERROR
     ```
     Installation failed.
     See ‘<lib>/freestiler.Rcheck/00install.out’ for details.
     ```

## Installation

### Devel

```
* installing *source* package ‘freestiler’ ...
** this is package ‘freestiler’ version ‘0.2.0’
** package ‘freestiler’ successfully unpacked and MD5 sums checked
** using staged installation
Using cargo 1.98.1 (797e8a9bc 2026-08-05)
Using rustc 1.98.1 (48a229cea 2026-09-01)
Enabling GeoParquet feature.
Enabling DuckDB feature.
Writing `src/Makevars`.
`tools/config.R` has finished.
...
if [ -d ./vendor ]; then \
	find ./vendor -type f \( -name '._*' -o -name '.DS_Store' \) -delete; \
fi
export CARGO_HOME=/revdepx/out/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo && \
export PATH="/revdepx/out/freestiler.Rcheck/R_check_bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/revdepx/out/home/.cargo/bin" && \
RUSTFLAGS=" --print=native-static-libs" cargo build  --features geoparquet,duckdb --lib --release --manifest-path=./rust/Cargo.toml --target-dir ./rust/target 
error: the package 'freestiler' does not contain these features: duckdb, geoparquet
make: *** [Makevars:28: rust/target/release/libfreestiler.a] Error 101
ERROR: compilation failed for package ‘freestiler’
* removing ‘/revdepx/out/freestiler.Rcheck/freestiler’


```
### CRAN

```
* installing *source* package ‘freestiler’ ...
** this is package ‘freestiler’ version ‘0.2.0’
** package ‘freestiler’ successfully unpacked and MD5 sums checked
** using staged installation
Using cargo 1.98.1 (797e8a9bc 2026-08-05)
Using rustc 1.98.1 (48a229cea 2026-09-01)
Enabling GeoParquet feature.
Enabling DuckDB feature.
Writing `src/Makevars`.
`tools/config.R` has finished.
...
if [ -d ./vendor ]; then \
	find ./vendor -type f \( -name '._*' -o -name '.DS_Store' \) -delete; \
fi
export CARGO_HOME=/revdepx/out/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo && \
export PATH="/revdepx/out/freestiler.Rcheck/R_check_bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/revdepx/out/home/.cargo/bin" && \
RUSTFLAGS=" --print=native-static-libs" cargo build  --features geoparquet,duckdb --lib --release --manifest-path=./rust/Cargo.toml --target-dir ./rust/target 
error: the package 'freestiler' does not contain these features: duckdb, geoparquet
make: *** [Makevars:28: rust/target/release/libfreestiler.a] Error 101
ERROR: compilation failed for package ‘freestiler’
* removing ‘/revdepx/out/freestiler.Rcheck/freestiler’


```
