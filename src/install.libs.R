files <- Sys.glob(paste0("*", SHLIB_EXT))
dest <- file.path(R_PACKAGE_DIR, paste0('libs', R_ARCH))
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
file.copy(files, dest, overwrite = TRUE)

if (Sys.which("strip") != "" && Sys.info()["sysname"] == "Linux" && isTRUE(as.logical(Sys.getenv("_R_SHLIB_STRIP_"))) && Sys.getenv("R_STRIP_SHARED_LIB") != "") {
  dest_files <- file.path(dest, files)
  for (file in dest_files) {
    message("Stripping: ", file)
    system(paste0(Sys.getenv("R_STRIP_SHARED_LIB"), " ", shQuote(file)))
  }
}

if (file.exists("symbols.rds")) {
  file.copy("symbols.rds", dest, overwrite = TRUE)
}
