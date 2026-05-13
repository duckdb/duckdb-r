# Dependencies
include $(GLUE:.o=.dd)

# Include only local dependencies for smaller footprint
# Add trailing backslash and sort
# Note: compiler .d files use 1-space indented continuation lines, so we use
# "^ +" (one or more spaces) instead of "^  " (exactly two spaces) to match
# all absolute paths (/...), duckdb sub-paths (duckdb/...), and paths going
# up the directory tree (../...).
# After filtering, normalize all continuation lines to 2-space indentation
# to avoid spurious sort-order changes caused by mixing 1-space (compiler) and
# 2-space (first sed) indented lines.
%.dd: %.d
	cp $< $<.bak
	sed -r 's/([^ ]) ([^ \\])/\1 \\\n  \2/g' $< | sed -r '/^ +([/]|duckdb|[.][.])/D;s/^ +/  /;$$s/([^\\])$$/\1 \\/' | { read -r header; printf '%s\n' "$$header"; LOCALE=C sort; } > $@
