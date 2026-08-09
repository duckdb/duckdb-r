# When does a `packageEvent(pkg, "onLoad")` hook fire, and what can it emit?
#
# Two questions the design turns on: whether the hook catches a namespace that
# is loaded but never attached (`dbplyr::x`), and whether a condition raised
# from inside it reaches the user without breaking the load it interrupts.

cat("== when the hook fires ==\n")
arm <- function() {
  setHook(packageEvent("dbplyr", "onLoad"), function(...) {
    cat("  [onLoad hook] version readable here:",
        unname(getNamespaceVersion("dbplyr")), "\n")
  })
  setHook(packageEvent("dbplyr", "attach"), function(...) cat("  [attach hook]\n"))
}

arm()
cat("loadNamespace() -- what `dbplyr::x` does:\n")
invisible(loadNamespace("dbplyr"))
cat("  attached?", "package:dbplyr" %in% search(), "\n")

cat("library() on the already-loaded namespace:\n")
suppressMessages(library(dbplyr))

cat("library() after unloading:\n")
unloadNamespace("dbplyr")
suppressMessages(library(dbplyr))

cat("\n== how a condition from the hook is delivered ==\n")
case <- function(label, emit, wrap, warn_opt) {
  script <- sprintf('
    options(warn = %d)
    setHook(packageEvent("dbplyr", "onLoad"), function(...) %s(%s))
    ok <- tryCatch({ %s(library(dbplyr)); "load OK" },
                   error = function(e) paste("LOAD FAILED:", conditionMessage(e)))
    cat("<<", ok, "| attached:", "package:dbplyr" %%in%% search(), ">>\n")
  ', warn_opt, emit,
     if (emit == "warning") '"too old", call. = FALSE' else '"too old"', wrap)
  f <- tempfile(fileext = ".R")
  writeLines(script, f)
  out <- suppressWarnings(system2("Rscript", f, stdout = TRUE, stderr = TRUE))
  cat("--", label, "\n")
  cat(paste0("   ", out[nzchar(out)]), sep = "\n")
}

case("warning(), warn = 0", "warning", "identity", 0)
case("warning(), warn = 2", "warning", "identity", 2)
case("warning() under suppressPackageStartupMessages()",
     "warning", "suppressPackageStartupMessages", 0)
case("packageStartupMessage()", "packageStartupMessage", "identity", 0)
case("packageStartupMessage() under suppressPackageStartupMessages()",
     "packageStartupMessage", "suppressPackageStartupMessages", 0)

cat("\n-- and without call. = FALSE, R names its own hook caller:\n")
f <- tempfile(fileext = ".R")
writeLines('
  setHook(packageEvent("dbplyr", "onLoad"), function(...) warning("too old"))
  suppressMessages(library(dbplyr))
', f)
cat(paste0("   ", suppressWarnings(system2("Rscript", f, stdout = TRUE, stderr = TRUE))), sep = "\n")
