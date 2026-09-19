# Timestamps on a build with no icu

Recorded by `run-no-icu.sh`; `README.md` says what it asks.

```
== TZ=UTC, duckdb 1.5.5.9013, DuckDB 1.5.5, source build ==
-- empty extension store --
duckdb_extensions(): loaded=FALSE installed=FALSE install_mode=NOT_INSTALLED
tzone label before anything asks for the setting: UTC
current_setting('TimeZone'): Extension Autoloading Error: An error occurred while trying to automatically install the required extension 'icu': (0.16s)
tzone label after: UTC
dbWriteTable type: TIMESTAMP WITH TIME ZONE
round trip: label UTC, instant preserved
SET TimeZone = 'UTC': Invalid Error: Extension Autoloading Error: An error occurred while trying to automatically install the required extension 'icu': (0.02s)
icu loaded after: FALSE
-- default extension store --
duckdb_extensions(): loaded=FALSE installed=TRUE install_mode=REPOSITORY
tzone label before anything asks for the setting: UTC
current_setting('TimeZone'): UTC (0.05s)
tzone label after: UTC
dbWriteTable type: TIMESTAMP WITH TIME ZONE
round trip: label UTC, instant preserved
SET TimeZone = 'UTC': ok (0.00s)
icu loaded after: TRUE

== TZ=Europe/Zurich, duckdb 1.5.5.9013, DuckDB 1.5.5, source build ==
-- empty extension store --
duckdb_extensions(): loaded=FALSE installed=FALSE install_mode=NOT_INSTALLED
tzone label before anything asks for the setting: UTC
current_setting('TimeZone'): Extension Autoloading Error: An error occurred while trying to automatically install the required extension 'icu': (0.18s)
tzone label after: UTC
dbWriteTable type: TIMESTAMP WITH TIME ZONE
round trip: label UTC, instant preserved
SET TimeZone = 'UTC': Invalid Error: Extension Autoloading Error: An error occurred while trying to automatically install the required extension 'icu': (0.02s)
icu loaded after: FALSE
-- default extension store --
duckdb_extensions(): loaded=FALSE installed=TRUE install_mode=REPOSITORY
tzone label before anything asks for the setting: UTC
current_setting('TimeZone'): Europe/Zurich (0.05s)
tzone label after: Europe/Zurich
dbWriteTable type: TIMESTAMP WITH TIME ZONE
round trip: label Europe/Zurich, instant preserved
SET TimeZone = 'UTC': ok (0.00s)
icu loaded after: TRUE

```
