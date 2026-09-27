# Render an experiment script as a reprex into <stem>.md beside it.
# Handbook: handbook/meta/local/README.md
args <- commandArgs(trailingOnly = TRUE)
input <- normalizePath(args[[1]])
stem <- args[[2]]
reprex::reprex(input = input, si = TRUE, html_preview = FALSE, venue = "gh")
rendered <- sub("\\.R$", "_reprex.md", input)
stopifnot(file.exists(rendered))
file.rename(rendered, file.path(dirname(input), paste0(stem, ".md")))
unlink(sub("\\.R$", "_reprex.R", input))
