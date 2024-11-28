<!-- NEWS.md is maintained by https://fledge.cynkra.com, contributors should not edit this file -->

# duckdb 1.1.3.9007

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Ignore errors when removing pkg-config on macOS (#614).

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9006

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Explicit permissions (#611).

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9005

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Use styler from main branch (#609).

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9004

## Features

- Throw exception when non-utf8 characters are in a data.frame (@Tmonster, #12, #16).

## Continuous integration

- Need to install R on Ubuntu 24.04 (#607).

- Use Ubuntu 24.04 and styler PR (#605).

## fledge

- Bump version to 1.1.3.9003 (#604).


# duckdb 1.1.3.9003

## fledge

  - Bump version to 1.1.3.9002 (#602).


# duckdb 1.1.3.9002

## fledge

  - Bump version to 1.1.3.9001 (#599).


# duckdb 1.1.3.9001

## Continuous integration

  - Add fledge workflow.


# duckdb 1.1.3.9000

- Internal changes only.


# duckdb 1.1.3

## Features

- Update to duckdb v1.1.3, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.3> for details.

- New `duckdb.materialize_callback` option, supersedes `get_last_rel()` (#589).

- New `rel_explain_df()` and `rel_tostring()` (#587).

- Handle empty child values for list constants (#186, @romainfrancois).

## Chore

- Undef `TRUE` and `FALSE` (#595).

- Remove `enable_materialization` argument to `rel_from_altrep_df()` in favor of creating a new data frame when needed (#588).

- Flip argument order for `expr_comparison()` (#585).

- Keep `cleanup` files to accommodate different build scenarios (#536).


# duckdb 1.1.2

## Features

- Update to duckdb v1.1.2, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.2> for details.

## Features

- Long-running queries can now be canceled immediately with Ctrl + C (terminal) or Escape (RStudio IDE and Workbench) (#514, #515).

- Add `col.types` argument to `duckdb_read_csv()` (#445, @eli-daniels).

- Rethrow errors with rlang if installed (#522).

- Improve error message for parsing erros during statement extraction (tidyverse/duckplyr#219, #521).

## Bug fixes

- Avoid RStudio IDE crashes when ending session with open objects (#520).

- `rfuns` extension: `%in%` works correctly as part of a `&` conjunction (#528).

## Internal

- New interal APIs: `rapi_get_last_rel_mat()`, `rapi_rel_to_altrep(allow_materialization = TRUE)`, `rapi_rel_from_altrep_df(enable_materialization)` (#526).

- xz-compress duckdb sources in the tarball (#530).

- `rfuns` extension: Fix signedness.


# duckdb 1.1.1

## Features

- Update to duckdb v1.1.1, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.1> for details.

- Add comparison expression to relational API (@toppyy, #457).

- Temporarily change `max_expression_depth` during ALTREP evaluation (#101, #460).

- Add `temporary` argument to `duckdb_read_csv()` (@ThomasSoeiro, #223).

## Chore

- Update vendored extension sources to hannes/duckdb-rfuns@20cde009b51b9355e6041b72b87105c6b45793fe.

- Remove warnings for uninitialized variables.


# duckdb 1.1.0

## Features

- Update to duckdb v1.1.0, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.0> for details.

- Upgrade vendored cpp11 to 0.5.0.


# duckdb 1.0.0-2

## Features

- Reduce the package installation size on macOS (#185).


# duckdb 1.0.0-1

## Bug fixes

- Upgrade vendored cpp11 to 0.4.7 to fix compilation with R-devel.

- Support `dplyr::tbl(conn, I(...))`.


# duckdb 1.0.0

## Bug fixes

- Update to duckdb v1.0.0, see <https://github.com/duckdb/duckdb/releases/tag/v1.0.0> for details.


# duckdb 0.10.3

## Features

- Update to duckdb v0.10.3, see <https://github.com/duckdb/duckdb/releases/tag/v0.10.3> for details.
- Support fetching `MAP` type (#61, #165).
- Add dbplyr translations for `clock::date_count_between()` (@edward-burn, #163, #166).
- `round()` duckdb translation uses `ROUND_EVEN()` instead of `ROUND()` (@lschneiderbauer, #146, #157).
- New `sort` argument to `rel_order()` (@toppyy, #168).
- Add dbplyr translations for `clock::add_days()`, `clock::add_years()`, `clock::get_day()`, `clock::get_month()`, and `clock::get_year()` (@edward-burn, #153).

## Bug fixes

- Correct usage of `win_current_group()` instead of `win_current_order()` in SQL translation (@lschneiderbauer, #173, #175).


# duckdb 0.10.2

## Features

- Update to duckdb v0.10.2, see <https://github.com/duckdb/duckdb/releases/tag/v0.10.2> for details.
- The `"difftime"` class is now mapped to the `INTERVAL` data type (#151).
- Use latest tests from DBItest (#148).
- Implement `n_distinct()` for multiple arguments using duckdb structs (@lschneiderbauer, #110, #122).
- Include rfuns extension (hannes/duckdb-rfuns#78, #144).
- Map `NA` to `SQLNULL` (#143).

## Bug fixes

- `rel_sql(rel, "{{sql}}")` works even on a read-only database (@Tmonster, #138).
- Avoid `R CMD check` warning regarding `SETLENGTH()` and `SET_TRUELENGTH()` (#145).


# duckdb 0.10.1

## Features

- Update to duckdb v0.10.1, see <https://github.com/duckdb/duckdb/releases/tag/v0.10.1> for details.
- Fix shutdown semantics for the driver object created by `duckdb()`. A database file is closed (and available to be opened from another session) after the last connection that uses this file calls `dbDisconnect()` . The `shutdown` argument to `dbDisconnect()` or the `duckdb_shutdown()` functions are no longer necessary. Two database connections from the same R session can access the same file concurrently in read-write mode (#124).

## Bug fixes

- Don't run tests that invoke re2 by default (#121, #127).

- Fix compilation for R 4.0 and R 4.1, regression introduced in v0.10.0. Using `librstrtmgr.a` from UCRT build of rtools40 (#130).

## Internal

- The C++ core is now vendored commit by commit, once every five minutes. Vendoring stops if `R CMD check` fails or if a previously unreleased tag is reached.

- New maintainer: Kirill Müller.

## Continuous integration

- Add rhub2 workflow.


# duckdb 0.10.0

## Bug fixes

- `dplyr::tbl()` works again when a Parquet or CSV file is passed instead of a table name (#38, #91).

- `DBI::dbQuoteIdentifier()` correctly quotes identifiers that start with a digit (#67, #92).

- Align the argument order of `dbWriteTable()` with the DBI specs (@eitsupi, #43, #49).

## Features

- New `tbl_file()` and `tbl_query()` to explicitly access tables and queries as dbplyr lazy tables (#96). The `cache` argument to `tbl()` and to the new functions must be named.

- Initial ALTREP support for `LIST` logical type (@romainfrancois, #77).

- Update core to duckdb v0.10.0 (#90).

- New private `rel_to_parquet()` to write a relation to parquet (@Tmonster, #46).

## Chore

- Change directory location for extensions and secrets for v.0.10.0 release (@Tmonster, #73).

- Remove last instance of `default_connection()` (#50).

## Documentation

- Add list of contributors (#2, #94).

- Use pkgdown BS5 (@maelle, #31, #70) with DuckDB logo (#76, @romainfrancois).

- Link to R documentation page.

- Include `NEWS.md` on CRAN (#48, @olivroy).

## Testing

- Add csv reading test for `duckdb_read_csv(na.strings = )` (@Tmonster, #10).

- Fix snapshot tests.

- Tweak tests for compatibility with v0.10.0 (#84).

# duckdb 0.9.2-1

- Fix compiler warning on R-devel (#45).


# duckdb 0.9.2

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.9.2>.

- Add dbplyr translation for `prod()` (#40, @m-muecke).


# duckdb 0.9.1-1

- Fix LTO checks on CRAN.


# duckdb 0.9.1

- See blog post at <https://duckdb.org/2023/09/26/announcing-duckdb-090.html>.

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.9.1>.

- Move sources to <https://github.com/duckdb/duckdb-r> (@krlmlr).

- Add ADBC integration with the adbcdrivermanager package (duckdb/duckdb#8172, @paleolimbot).

- Full support of lists and structs in R (duckdb/duckdb#8503, @krlmlr).

# duckdb 0.8.1-3

- Internal changes to support the duckplyr package.

# duckdb 0.8.1-2

- Compatibility with dbplyr.

- Internal changes to support the duckplyr package.

# duckdb 0.8.1-1

- Fix CRAN checks.

# duckdb 0.8.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.8.1>.

# duckdb 0.8.0

- See blog post at <https://duckdb.org/2023/05/17/announcing-duckdb-080.html>.

# duckdb 0.7.1-1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.7.1>.

# duckdb 0.7.0

- See blog post at <https://duckdb.org/2023/02/13/announcing-duckdb-070.html>.

# duckdb 0.6.2

- New `duckdb_prepare_substrait_json()`.

# duckdb 0.6.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.6.1>.

# duckdb 0.6.0

- See blog post at <https://duckdb.org/2022/11/14/announcing-duckdb-060.html>.

# duckdb 0.5.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.5.1>.

# duckdb 0.5.0

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.5.0>.

# duckdb 0.4.0

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.4.0>.

# duckdb 0.3.4-1

- Minor changes for CRAN compatibility.

# duckdb 0.3.4

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.4>.

# duckdb 0.3.3

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.3>.

# duckdb 0.3.2

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.2>.

# duckdb 0.3.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.1>.

# duckdb 0.3.0

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.0>.

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.2.9>.

# duckdb 0.2.8

This preview release of DuckDB is named "Ceruttii" after a [long-extinct relative of the present-day Harleqin Duck](https://en.wikipedia.org/wiki/Harlequin_duck#Taxonomy) (Histrionicus Ceruttii).
Binary builds are listed below. Feedback is very welcome.

Note: Again, this release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the [documentation](https://duckdb.org/docs/sql/statements/export) for details.

### SQL

 - #2064: `RANGE`/`GENERATE_SERIES` for timestamp + interval
 - #1905: Add `PARQUET_METADATA` and `PARQUET_SCHEMA` functions
 - #2059, #1995, #2020 & #1960: Window `RANGE` framing, `NTH_VALUE` and other improvements

### APIs

 - Many Arrow integration improvements
 - Many ODBC driver improvements
 - #1815: Initial version: SQLite UDF API
 - #2001: Support DBConfig in C API

### Engine

 - #1975, #1876 & #2009: Unified row layout for sorting, aggregate & joins
 - #1930 & #1904: List Storage
 - #2050: CSV Reader/Casting Framework Refactor & add support for `TRY_CAST`
 - #1950: Add Constant Segment Compression to Storage
 - #1957: Add pipe/stream file system





# duckdb 0.2.7

This preview release of DuckDB is named "Mollissima" after the Common Eider (Somateria mollissima).
 Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major changes:

SQL
 - #1847: Unify catalog access functions, and provide views for common PostgreSQL catalog functions
 - #1822: Python/JSON-Style Struct & List Syntax
 - #1862: #1584 Implementing `NEXTAFTER` for float and double
 - #1860: `FIRST` implementation for nested types
 - #1858: `UNNEST` table function & array syntax in parser
 - #1761: Issue #1746: Moving `QUANTILE`

APIs

 - #1852, #1840, #1831, #1819 and #1779: Improvements to Arrow Integration
 - #1843: First iteration of ODBC driver
 - #1832: Add visualizer extension
 - #1803: Converting Nested Types to native python
 - #1773: Add support for key/value style configuration, and expose this in the Python API

Engine
 - #1808: Row-Group Based Storage
 - #1842: Add (Persistent) Struct Storage Support
 - #1859: Read and write atomically with offsets
 - #1851: Internal Type Rework
 - #1845: Nested join payloads
 - #1813: Aggregate Row Layout
 - #1836: Join Row Layout
 - #1804: Use Allocator class in buffer manager and add a test for a custom allocator usage





# duckdb 0.2.6

This preview release of DuckDB is named "Jamaicensis" after the [blue-billed Ruddy Duck (Oxyura jamaicensis)](https://en.wikipedia.org/wiki/Ruddy_duck). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Also note: Due to changes in the internal storage (#1530), databases created with this release wil require somewhat more disk space. This is transient as we are working hard to finalise the on-disk storage format.

Major changes:

Engine
 - #1666: External merge sort, #1580: Parallel scan of ordered result and #1561: Rework physical ORDER BY
 - #1520 & #1574: Window function computation parallelism
 - #1540: Add table functions that take a subquery parameter
 - #1533: Using vectors, instead of column chunks as lists
 - #1530: Store null values separate from main data in a Validity Segment

SQL
 - #1568: Positional Reference Operator `#1` etc.
 - #1671: `QUANTILE` variants and #1685: Temporal quantiles
 - #1695: New Timestamp Types `TIMESTAMP_NS`, `TIMESTAMP_MS` and `TIMESTAMP_NS`
 - #1647: Add support for UTC offset timestamp parsing to regular timestamp conversion
 - #1659: Add support for `USING` keyword in `DELETE` statement
 - #1638, #1663, #1621 & #1484: Many changes arount `ARRAY` syntax
 - #1610: Add support for `CURRVAL`
 - #1544: Add `SKIP` as an option to `READ_CSV` and `COPY`

APIs
 - #1525: Add loadable extensions support
 - #1711: Parallel Arrow Scans
 - #1569: Map-style UDFs for Python API
 - #1534: Extensible Replacement Scans & Automatic Pandas Scans and #1487: Automatically use parquet or CSV scan when using a table name that ends in `.parquet` or `.csv`
 - #1649: Add a QueryRelation object that can be used to convert a query directly into a relation object, #1665: Adding from_query to python api
 - #1550: Shell: Add support for Ctrl + arrow keys to linenoise, and make Ctrl+C terminate the current query instead of the process
 - #1514: Using `ALTREP` to speed up string column transfer to R
 - #1502: R: implementation of Rstudio connection-contract tab





# duckdb 0.2.5

This preview release of DuckDB is named "Falcata" after the Falcated Duck (Mareca falcata). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major Changes:

Engine
 - #1356: **Incremental Checkpointing**
 - #1422: Optimize Top N Implementation

SQL
 - #1406, #1372, #1387: Many, many new aggregate functions
 - #1460: `QUANTILE` aggregate variant that takes a list of quantiles &  #1346: Approximate Quantiles
 - #1461: `JACCARD`, #1441 `LEVENSHTEIN` & `HAMMING` distance  scalar function
 - #1370: `FACTORIAL` scalar function and ! postfix operator
 - #1363: `IS (NOT) DISTINCT FROM`
 - #1385: `LIST_EXTRACT` to get a single element from a list
 - #1361: Aliases in the `HAVING` clause (fixes issue #1358)
 - #1355: Limit clause with non constant values

APIs:
 - #1430 & #1424: **DuckDB WASM builds**
 - #1419: Exporting the appender api to C
 - #1408: Add blob support to C API
 - #1432,  #1459 & #1456: Progress Bar
 - #1440: Detailed profiler.






# duckdb 0.2.4

This preview release of DuckDB is named "Jubata" after the [Australian Wood Duck](https://en.wikipedia.org/wiki/Australian_wood_duck) (Chenonetta jubata). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major changes:
SQL
 - #1231: Full Text Search extension
 - #1309: Filter Clause for Aggregates
 - #1195: `SAMPLE` Operator
 - #1244: `SHOW` select queries
 - #1301: `CHR` and `ASCII` functions & #1252: Add `GAMMA` and `LGAMMA` functions

Engine
 - #1211: (Mostly) Lock-Free Buffer Manager
 - #1325: Unsigned Integer Types Support
 - #1229: Filter Pull Up Optimizer
 - #1296: Optimizer that removes redundant `DELIM_GET` and `DELIM_JOIN` operators
 - #1219: `DATE`, `TIME` and `TIMESTAMP` rework: move to epoch format & microsecond support

Clients
 - #1287 and #1275: Improving JDBC compatibility
 - #1260: Rework client API and prepared statements, and improve DuckDB -> Pandas conversion
 - #1230: Add support for parallel scanning of pandas data frames
 - #1256: JNI appender
 - #1209: Write shell history to file when added to allow crash recovery, and fix crash when .importing file with invalid
 - #1204: Add support for blobs to the R API and #1202: Add blob support to the python api

Parquet
 - #1314: Refactor and nested types support for Parquet Reader



# duckdb 0.2.3

This preview release of DuckDB is named "Serrator" after the Red-breasted merganser (Mergus serrator). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major changes:

SQL:
 - #1179: Interval Cleanup & Extended `INTERVAL` Syntax
 - #1147: Add exact `MEDIAN` and `QUANTILE` functions
 - #1129: Support scalar functions with `CREATE FUNCTION`
 - #1137: Add support for (`NOT`) `ILIKE`, and optimize certain types of `LIKE` expressions

Engine
 - #1160: Perfect Aggregate Hash Tables
 - #1133: Statistics Rework & Statistics Propagation
 - #1144: Common Aggregate Optimizer, #1143: CSE Optimizer and #1135: Optimizing expressions in grouping keys
 - #1138: Use predication in filters
 - #1071: Removing string null termination requirement

Clients
 - #1112: Add DuckDB node.js API
 - #1168: Add support for Pandas category types
 - #1181: Extend DuckDB::LibraryVersion() to output dev version in format `0.2.3-devXXX` & #1176: Python binding: Add module attributes for introspecting DuckDB version

Parquet Reader:
 - #1183: Filter pushdown for Parquet reader
 - #1167: Exporting Parquet statistics to DuckDB
 - #1162: Add support for compression codec in Parquet writer &  #1163: Add ZSTD Compression Code and add ZSTD codec as option for Parquet export
 - #1103: Add object cache and Parquet metadata cache











# duckdb 0.2.2

This is a preview release of DuckDB.
Starting from this release, releases get named as well. Names are chosen from species of ducks (of course). We start with "Clypeata".

*Note*: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the `EXPORT DATABASE` command with the old version followed by `IMPORT DATABASE` with the new version to migrate your data. See the [documentation](https://duckdb.org/docs/sql/statements/export) for details.

Binary builds are listed below. Feedback is very welcome. Major changes:

SQL
 - #1057: Add PRAGMA for enabling/disabling optimizer & extend output for query graph
 - #1048: Allow CTEs in subqueries (including CTEs themselves) and #987: Allow CTEs in CREATE VIEW statements
 - #1046: Prettify Explain/Query Profiler output
 - #1037: Support FROM clauses in UPDATE statements
 - #1006: STRING_SPLIT and STRING_SPLIT_REGEX SQL functions
 - #1000: Implement MD5 function
 - #936: Add GLOB support to Parquet & CSV readers
 - #899: Table functions information_schema_schemata() and information_schema_tables() and #903: Add table function information_schema_columns()

Engine
 - #984: Parallel grouped aggregations and #1045: Some performance fixes for aggregate hash table
 - #1008: Index Join
 - #991: Local Storage Rework: Per-morsel version info and flush intermediate chunks to the base tables
 - #906: Parallel scanning of single Parquet files and #982: ZSTD Support in Parquet library
 - #883: Unify Table Scans with Table Functions
 - #873: TPC-H Extension
 - #884: Remove NFC-normalization requirement for all data and add COLLATE NFC

Client
 - #1001: Dynamic Syntax Highlighting in Shell
 - #933: Upgrade shell.c to 3330000
 - #918: Add in support for Python datetime types in bindings
 - #950: Support dates and times output into arrow
 - #893: Support for Arrow NULL columns


# duckdb 0.2.1

This is a preview release of DuckDB. Binary builds are listed below. Feedback is very welcome. Major changes:

Engine
 - #770: Enable Inter-Pipeline Parallelism
 - #835: Type system updates with #779: `INTERVAL` Type,  #858: Fixed-precision `DECIMAL` types & #819: `HUGEINT` type
 - #790: Parquet write support

API
 - #866: Initial Arrow support
 - #809: Aggregate UDF support with #843: Generic `CreateAggregateFunction()` & #752: `CreateVectorizedFunction()` using only template parameters

SQL
 - #824: `strftime` and `strptime`
 - #858: `EXPORT DATABASE` and `IMPORT DATABASE`
 - #832: read_csv(_auto) improvements: optional parameters, configurable sample size, line number info



# duckdb 0.2.0

This is a preview release of DuckDB. Binary builds are listed below. Feedback is very welcome.

SQL:
 - #730: `FULL OUTER JOIN` Support
 - #732: Support for `NULLS FIRST`/`NULLS LAST`
 - #698: Add implementation of the `LEAST`/`GREATEST` functions
 - #772: Implement `TRIM` function and add optional second parameter to `RTRIM`/`LTRIM`/`TRIM`
 - #771: Extended Regex Options

Clients:
 - Python: #720: Making Pandas optional and add support for PyPy
 - C++: #712: C++ UDF API





# duckdb 0.1.9

This is a preview release of DuckDB. Binary are listed below. Feedback is very welcome. Major changes:
New [website](http://duckdb.org/) [woo-ho](https://www.youtube.com/watch?v=H9cmPE88a_0)!

Engine
 - #653: Parquet reader integration

SQL
 - #685: Case insensitive binding of column names
 - #662: add `EPOCH_MS` function and test cases

Clients
 - #681: JDBC Read-only mode for and #677 duplicate()` method to allow multiple connections to same database



# duckdb 0.1.8

This is a preview release of DuckDB. Feedback is very welcome.

SQL
 - SQL functions `IF` and `IFNULL` #644
 - SQL string functions `LEFT` #620 and `RIGHT` #631
 - #641: `BLOB` type support
 - #640: `LIKE` escape support

Clients
 - #627: Insertion support for Python relation API



# duckdb 0.1.7

This is the sixth preview release of DuckDB. Feedback is very welcome.
Binary builds are available as well.

SQL
- [Add / remove columns, change default values & column type](https://duckdb.org/docs/sql/statements/alter_table) #612
- [Collation support](https://duckdb.org/docs/sql/expressions/collations)
- CSV sniffer `READ_CSV_AUTO` for dialect, data type and header detection #582
- `SHOW` & `DESCRIBE` Tables #501
- String function `CONTAINS`  #488
- String functions `LPAD` / `RPAD`, `LTRIM` / `RTRIM`, `REPEAT`, `REPLACE` & `UNICODE` #597
- Bit functions `BIT_LENGTH`, `BIT_COUNT`, `BIT_AND`, `BIT_OR`, `BIT_XOR` & `BIT_AGG` #608

Engine
- `LIKE` optimization rules #559
- Adaptive filters in table scans #574
- ICU Extension for extended Collations & Extension Support #594
- Extended zone map support in scans #551
- Disallow NaN/INF in the system #541
- Use UTF Grapheme Cluster Breakers in Reverse and Shell #570

Clients
- Relation API for C++ #509 and Python #598
 - Java (TM) JDBC (R) Client for DuckDB #492 #520 #550



# duckdb 0.1.6

This is the fifth preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here: http://download.duckdb.org/alias/v0.1.6/

SQL
- #455 Table renames `ALTER TABLE tbl RENAME TO tbl2`
- #457 Nested list type can be created using `LIST` aggregation and unpacked with the new `UNNEST` operator
- #463 `INSTR` string function, #477 `PREFIX` string function, #480 `SUFFIX` string function

Engine
- #442 Optimized casting performance to strings
- #444 Variable return types for table-producing functions
- #453 Rework aggregate function interface
- #474 Selection vector rework
- #478 UTF8 NFC normalization of all incoming strings
- #482 Skipping table segments during scan based on min/max indices

Python client
- #451 `date` / `datetime` support
- #467 `description` field for cursor
- #473 Adding `read_only` flag to `connect`
- #481 Rewrite of Python API using `pybind11`

R client
- #468 Support for prepared statements in R client
- #479 Adding automatic CSV to table function `read_csv_duckdb`
- #483 Direct scan operator for R `data.frame` objects



# duckdb 0.1.5

This is the fourth preview release of DuckDB. Feedback is very welcome. Note: The v0.1.4 version was skipped because of a Python packaging issue.

Binary builds can be found here:
http://download.duckdb.org/rev/59f8907b5d89268c158ae1774d77d6314a5c075f/

Major changes:
 - #409 Vector Overhaul
 - #423 Remove individual vector cardinalities
 - #418 `DATE_TRUNC` SQL function
 - #424 `REVERSE` SQL function
 - #416 Support for `SELECT table.* FROM table`
 - #414 STRUCT types in query execution
 - #431 Changed internal string representation
 - #433 Rename internal type `index_t` to `idx_t`
 - #439 Support for temporary structures in read-only mode
 - #440 Builds on Solaris & OpenBSD


*Note*: This release contains a bug in the Python API that leads to crashes when fetching strings to NumPy/Pandas #447 


# duckdb 0.1.3

This is the third preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
http://download.duckdb.org/rev/59f8907b5d89268c158ae1774d77d6314a5c075f/

Major changes:
  * #388 Major updates to shell
  * #390 Unused Column & Column Lifetime Optimizers
  * #402 String and compound keys in indices/primary keys
  * #406 Adaptive reordering of filter expressions
  


# duckdb 0.1.2

This is the third preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
http://download.duckdb.org/rev/6fcb5ef8e91dcb3c9b2c4ca86dab3b1037446b24/


# duckdb 0.1.1

This is the second preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
http://download.duckdb.org/rev/2e51e9bae7699853420851d3d2237f232fc2a9a8/


# duckdb 0.1.0

This is the first preview release of DuckDB. Feedback is very welcome.

Binary builds can be found here: http://download.duckdb.org/rev/c1cbc9d0b5f98a425bfb7edb5e6c59b5d10550e4/
