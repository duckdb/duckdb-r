installed <- rownames(installed.packages())
installed

pkgs <-
  read.dcf("DESCRIPTION", c("Imports", "Suggests")) |>
  gsub(" +[(][^)]+[)]", "", x = _) |> strsplit(",\n") |>
  unlist() |>
  setdiff(installed)

pkgs

install.packages(pkgs)

# Can't install packager from here, so we'll have to do it manually
