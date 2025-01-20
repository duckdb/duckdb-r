# This file is used from Makevars if $DUCKDB_R_PREBUILT_ARCHIVE points
# to an existing file.
# We print details on the object files already extracted in the configure script
# for diagnostic purposes.
all: duckdb.tar
duckdb.tar: $(DUCKDB_R_PREBUILT_ARCHIVE)
	ls -lR
	# Ensure the file is recreated in the next run
	rm -f Makevars.duckdb
