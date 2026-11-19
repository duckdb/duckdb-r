# data.checker (2.0.0)

* GitHub mirror: <https://github.com/cran/data.checker>

Run `revdepcheck::revdep_details(, "data.checker")` for more info

## Error before installation

### Devel

```
Dependencies not installed: tomledit





```
### CRAN

```
Dependencies not installed: tomledit





```
# freestiler (0.3.0)

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
[... 42 earlier lines omitted; the full 00install.out is in the check artifact ...]
   Compiling num-traits v0.2.19
   Compiling crossbeam-epoch v0.9.21
   Compiling shlex v2.0.1
   Compiling find-msvc-tools v0.1.14
   Compiling cc v1.5.1
   Compiling pkg-config v0.3.34
   Compiling crossbeam-deque v0.8.8
   Compiling zstd-sys v2.1.0+zstd.1.5.7
   Compiling ident_case v1.0.1
...
   8 | #[cfg(any(feature = "geoparquet", feature = "duckdb"))]
     |          -------------------------------------------- the item is gated here
   9 | pub mod file_input;
     |         ^^^^^^^^^^

For more information about this error, try `rustc --explain E0433`.
error: could not compile `freestiler` (lib) due to 7 previous errors
make: *** [Makevars:28: rust/target/release/libfreestiler.a] Error 101
ERROR: compilation failed for package ‘freestiler’
* removing ‘/revdepx/out/freestiler.Rcheck/freestiler’


```
### CRAN

```
[... 42 earlier lines omitted; the full 00install.out is in the check artifact ...]
   Compiling jobserver v0.1.32
   Compiling shlex v2.0.1
   Compiling crossbeam-epoch v0.9.21
   Compiling find-msvc-tools v0.1.14
   Compiling cc v1.5.1
   Compiling pkg-config v0.3.34
   Compiling crossbeam-deque v0.8.8
   Compiling zstd-sys v2.1.0+zstd.1.5.7
   Compiling ident_case v1.0.1
...
   8 | #[cfg(any(feature = "geoparquet", feature = "duckdb"))]
     |          -------------------------------------------- the item is gated here
   9 | pub mod file_input;
     |         ^^^^^^^^^^

For more information about this error, try `rustc --explain E0433`.
error: could not compile `freestiler` (lib) due to 7 previous errors
make: *** [Makevars:28: rust/target/release/libfreestiler.a] Error 101
ERROR: compilation failed for package ‘freestiler’
* removing ‘/revdepx/out/freestiler.Rcheck/freestiler’


```
# plumber2 (0.2.0)

* GitHub mirror: <https://github.com/cran/plumber2>

Run `revdepcheck::revdep_details(, "plumber2")` for more info

## Error before installation

### Devel

```
Dependencies not installed: fireproof, firesafety, routr, waysign





```
### CRAN

```
Dependencies not installed: fireproof, firesafety, routr, waysign





```
