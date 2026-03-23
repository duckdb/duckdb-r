# Dependencies
include $(GLUE:.o=.dd)

# Include only local dependencies for smaller footprint
# Add trailing backslash and sort
# Note: compiler .d files use 1-space indented continuation lines.
# We normalize those to 2-space indent before filtering, so that the output
# .dd files always use exactly two spaces for continuation lines.
# This avoids spurious diffs when rebuilding.
%.dd: %.d
	sed -r 's/([^ ]) ([^ \\])/\1 \\\n  \2/g' $< | sed -r 's/^ ([^ ])/  \1/' | sed -r '/^  ([/]|duckdb|[.][.])/D;$$s/([^\\])$$/\1 \\/' | { read -r header; printf '%s\n' "$$header"; LOCALE=C sort; } > $@
