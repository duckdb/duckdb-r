# What the package remembers between calls in one R session, one field per
# fact, each reached through the function beside the code that owns it.
# Explained in handbook/architecture/r-layer/conventions/README.md.
the <- new.env(parent = emptyenv())
