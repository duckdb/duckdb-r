# freestiler (0.1.6)

* GitHub: <https://github.com/walkerke/freestiler>
* Email: <mailto:kyle@walker-data.com>
* GitHub mirror: <https://github.com/cran/freestiler>

Run `revdepcheck::cloud_details(, "freestiler")` for more info

## In both

*   checking whether package ‘freestiler’ can be installed ... ERROR
     ```
     Installation failed.
     See ‘/tmp/workdir/freestiler/new/freestiler.Rcheck/00install.out’ for details.
     ```

## Installation

### Devel

```
* installing *source* package ‘freestiler’ ...
** this is package ‘freestiler’ version ‘0.1.6’
** package ‘freestiler’ successfully unpacked and MD5 sums checked
** using staged installation
Using cargo 1.75.0
Using rustc 1.75.0 (82e1608df 2023-12-21) (built from a source tarball)
Building for CRAN.
DuckDB feature disabled.
Writing `src/Makevars`.
`tools/config.R` has finished.
** libs
using C compiler: ‘gcc (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0’
gcc -std=gnu2x -I"/opt/R/4.5.1/lib/R/include" -DNDEBUG   -I/usr/local/include    -fpic  -g -O2  -c entrypoint.c -o entrypoint.o
if [ -d ./vendor ]; then \
	echo "=== Using offline vendor directory ==="; \
	mkdir -p /tmp/workdir/freestiler/new/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo && \
	cp rust/vendor-config.toml /tmp/workdir/freestiler/new/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo/config.toml; \
elif [ -f ./rust/vendor.tar.xz ]; then \
	echo "=== Using offline vendor tarball ==="; \
	tar xf rust/vendor.tar.xz && \
	mkdir -p /tmp/workdir/freestiler/new/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo && \
	cp rust/vendor-config.toml /tmp/workdir/freestiler/new/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo/config.toml; \
fi
=== Using offline vendor tarball ===
if [ -d ./vendor ]; then \
	find ./vendor -type f \( -name '._*' -o -name '.DS_Store' \) -delete; \
fi
export CARGO_HOME=/tmp/workdir/freestiler/new/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo && \
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.cargo/bin" && \
RUSTFLAGS=" --print=native-static-libs" cargo build -j 2 --offline  --lib --release --manifest-path=./rust/Cargo.toml --target-dir ./rust/target 
error: failed to parse lock file at: /tmp/workdir/freestiler/new/freestiler.Rcheck/00_pkg_src/freestiler/src/rust/Cargo.lock

Caused by:
  lock file version 4 requires `-Znext-lockfile-bump`
make: *** [Makevars:28: rust/target/release/libfreestiler.a] Error 101
ERROR: compilation failed for package ‘freestiler’
* removing ‘/tmp/workdir/freestiler/new/freestiler.Rcheck/freestiler’


```
### CRAN

```
* installing *source* package ‘freestiler’ ...
** this is package ‘freestiler’ version ‘0.1.6’
** package ‘freestiler’ successfully unpacked and MD5 sums checked
** using staged installation
Using cargo 1.75.0
Using rustc 1.75.0 (82e1608df 2023-12-21) (built from a source tarball)
Building for CRAN.
DuckDB feature disabled.
Writing `src/Makevars`.
`tools/config.R` has finished.
** libs
using C compiler: ‘gcc (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0’
gcc -std=gnu2x -I"/opt/R/4.5.1/lib/R/include" -DNDEBUG   -I/usr/local/include    -fpic  -g -O2  -c entrypoint.c -o entrypoint.o
if [ -d ./vendor ]; then \
	echo "=== Using offline vendor directory ==="; \
	mkdir -p /tmp/workdir/freestiler/old/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo && \
	cp rust/vendor-config.toml /tmp/workdir/freestiler/old/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo/config.toml; \
elif [ -f ./rust/vendor.tar.xz ]; then \
	echo "=== Using offline vendor tarball ==="; \
	tar xf rust/vendor.tar.xz && \
	mkdir -p /tmp/workdir/freestiler/old/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo && \
	cp rust/vendor-config.toml /tmp/workdir/freestiler/old/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo/config.toml; \
fi
=== Using offline vendor tarball ===
if [ -d ./vendor ]; then \
	find ./vendor -type f \( -name '._*' -o -name '.DS_Store' \) -delete; \
fi
export CARGO_HOME=/tmp/workdir/freestiler/old/freestiler.Rcheck/00_pkg_src/freestiler/src/.cargo && \
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.cargo/bin" && \
RUSTFLAGS=" --print=native-static-libs" cargo build -j 2 --offline  --lib --release --manifest-path=./rust/Cargo.toml --target-dir ./rust/target 
error: failed to parse lock file at: /tmp/workdir/freestiler/old/freestiler.Rcheck/00_pkg_src/freestiler/src/rust/Cargo.lock

Caused by:
  lock file version 4 requires `-Znext-lockfile-bump`
make: *** [Makevars:28: rust/target/release/libfreestiler.a] Error 101
ERROR: compilation failed for package ‘freestiler’
* removing ‘/tmp/workdir/freestiler/old/freestiler.Rcheck/freestiler’


```
