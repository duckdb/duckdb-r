# Timeline of the SIGINT disposition across an `ATTACH 'md:'`.
#
#   Rscript -e 'source("md-probe.R")'   # or paste into an interactive R
#
# Needs a MotherDuck account and a route to it, which is why this is a
# script to hand someone rather than a case in run.sh. Build the probe
# first, with build-sigprobe.sh.
#
# Run it interactively, let the browser sign-in page open, and press
# Ctrl+C while it waits. Every `[sigprobe ...]` line on stderr names the
# library owning the SIGINT handler at that instant. The question is
# whether it is ever MotherDuck's -- and if it is, whether it still is
# when the wait starts.

here <- normalizePath(".")
dll <- file.path(here, paste0("sigprobe", .Platform$dynlib.ext))
stopifnot(file.exists(dll))
dyn.load(dll)

probe_now <- function() invisible(.C("sigprobe_now"))
probe_every <- function(seconds, times) {
  invisible(.C("sigprobe_start", as.double(seconds), as.integer(times)))
}

message("--- before loading duckdb")
probe_now()

library(duckdb)

# MD_PROBE_DUCKDB_API=cli tests whether the client's own name is what
# decides: the package announces `r-dbi` (src/database.cpp) where the
# shell announces `cli`, and user config is applied after that default,
# so this overrides it. An experiment, not a workaround -- claiming to be
# a client one is not has consequences beyond this question.
api <- Sys.getenv("MD_PROBE_DUCKDB_API", "")
con <- DBI::dbConnect(duckdb::duckdb(
  config = if (nzchar(api)) list(duckdb_api = api) else list()
))

message("--- connected as duckdb_api = ",
        DBI::dbGetQuery(con, "SELECT current_setting('duckdb_api') AS a")$a)
message("--- before ATTACH")
probe_now()

# Sample once a second for three minutes, so the timeline covers the
# extension load, the sign-in wait, and whatever Ctrl+C changes.
probe_every(1, 180)

message("--- ATTACH 'md:' -- press Ctrl+C once the browser page opens")
try(DBI::dbExecute(con, "ATTACH 'md:'"))

message("--- ATTACH returned")
probe_now()
