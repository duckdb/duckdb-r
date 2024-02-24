installed <- rownames(installed.packages())
installed

pkgs <-
  read.dcf("DESCRIPTION", c("Imports", "Suggests")) |>
  gsub(" +[(][^)]+[)]", "", x = _) |> strsplit(",\n") |>
  unlist() |>
  setdiff(installed)

pkgs

install.packages(pkgs)

r_exec <- R.home("bin") |> file.path("R")

system2(r_exec, c("CMD", "INSTALL", "--preclean", "."), wait = TRUE)
