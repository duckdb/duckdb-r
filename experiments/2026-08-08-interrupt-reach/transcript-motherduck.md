# `ATTACH 'md:'`, both hosts, sampled once a second

Recorded 2026-08-08 by the maintainer on macOS aarch64 (Apple silicon),
R 4.5.3, DuckDB CLI v1.5.5 from Homebrew, MotherDuck implementation
`motherduck_impl.v1.5.5-2026-08-22`.
Method: [`sigprobe.c`](sigprobe.c), driven by [`md-probe.R`](md-probe.R)
in R and by `DUCKDB_SIGPROBE`/`DYLD_INSERT_LIBRARIES` in the CLI.

Trimmed to the disposition lines and the messages that place them.
Home directories are abbreviated and the one-time device codes redacted;
nothing else is altered.
The sign-in page was opened and then dismissed in both runs, which is
the `User did not confirm their request` line.

## R — MotherDuck's handler never appears

```
--- before loading duckdb
[sigprobe now]   sym=handleInterrupt   lib=…/R.framework/…/libR.dylib     SA_RESTART=1
--- connected, before ATTACH
[sigprobe now]   sym=handleInterrupt   lib=…/R.framework/…/libR.dylib     SA_RESTART=1
--- ATTACH 'md:' -- press Ctrl+C once the browser page opens
Attempting to automatically open the SSO authorization page in your default browser.
Please open this link to login into your account: https://auth.motherduck.com/activate?user_code=…

[sigprobe t+1s]  sym=duckdb::ScopedInterruptHandler::signal_handler
                 lib=…/library/duckdb/libs/duckdb.so                      SA_RESTART=1
[sigprobe t+2s]  … same …
[sigprobe t+3s]  … same …
^C
[sigprobe t+4s]  … same …
^C
[sigprobe t+5s]  … same …
^C
[sigprobe t+6s]  … same …
[sigprobe t+7s]  … same …            (through t+12s, unchanged)
User did not confirm their request
⚠️ Token not found, please use the SET command: …

[sigprobe t+13s] sym=handleSelectInterrupt  lib=…/libR.dylib             SA_RESTART=1
```

Three Ctrl+C during the wait, and the disposition never changes: the
package's handler owns SIGINT for the whole sign-in, and the statement
ends only when the browser page is dismissed.

## CLI — MotherDuck installs its own, and takes it back

```
memory D ATTACH 'md:';
[sigprobe t+22s] sym=InterruptHandler  lib=…/bin/duckdb                   SA_RESTART=1  flags=0x2
Attempting to automatically open the SSO authorization page in your default browser.
Please open this link to login into your account: https://auth.motherduck.com/activate?user_code=…

[sigprobe t+23s] sym=md::login::detail::sighandler(int, __siginfo *, void *)
                 lib=…/.duckdb/extensions/v1.5.5/osx_arm64/motherduck_impl.….duckdb_extension
                 SA_RESTART=0  flags=0x40
[sigprobe t+24s] … same …            (through t+45s, unchanged)
User did not confirm their request
⚠️ Token not found, please use the SET command: …
Invalid Input Error:
Cannot connect to MotherDuck server: no token provided. …

[sigprobe t+46s] sym=InterruptHandler  lib=…/bin/duckdb                   SA_RESTART=1  flags=0x2
```

The handler changes exactly at the sign-in prompt and changes back when
the statement ends: MotherDuck installs `md::login::detail::sighandler`
around the wait and restores the shell's afterwards.
`flags=0x40` is `SA_SIGINFO` on macOS, and `SA_RESTART` is clear —
without it a blocking call returns `EINTR` rather than resuming, which
is how a handler ends a wait it is sitting in.

## What the pair shows

MotherDuck's sign-in wait is cancellable because MotherDuck makes it
cancellable, with a handler of its own, for the duration of the wait.
Under the R client it installs nothing, so Ctrl+C reaches the package's
handler, which sets `ClientContext::interrupted` — a flag the sign-in
wait does not read.

It is not a handler the package displaced: there is none to displace,
and the CLI run shows MotherDuck installing over the shell's handler
without difficulty, so an installed handler is no obstacle to it.
