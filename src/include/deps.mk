# Dependencies
include $(GLUE:.o=.dd)

# Include only local dependencies for smaller footprint
# Add trailing backslash and sort
# Note: compiler .d files use 1-space indented continuation lines, so we use
# "^ *" (zero or more spaces) instead of "^  " (exactly two spaces) to match
# all absolute paths (/...), duckdb sub-paths (duckdb/...), and paths going
# up the directory tree (../...).
%.dd: %.d
	sed -r 's/([^ ]) ([^ \\])/\1 \\\n  \2/g' $< | sed -r '/^ +([/]|duckdb|[.][.])/D;$$s/([^\\])$$/\1 \\/' | { read -r header; printf '%s\n' "$$header"; LOCALE=C sort; } > $@
