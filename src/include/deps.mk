# Dependencies
include $(GLUE:.o=.dd)

# Include only local dependencies for smaller footprint
# Add trailing backslash and sort
%.dd: %.d
	sed -r 's/([^ ]) ([^ \\])/\1 \\\n  \2/g' $< | sed -r '/^  ([/]|duckdb|[.][.])/D;$$s/([^\\])$$/\1 \\/' | { read -r header; printf '%s\n' "$$header"; LOCALE=C sort; } > $@
