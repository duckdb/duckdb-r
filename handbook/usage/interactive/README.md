# Interactive use

What the package shows while you work,
rather than what it returns when you ask:
the query progress display, and the RStudio Connections pane.

**The progress display** is the engine calling back into R.
The C++ side holds the symbol it invokes
(`get_progress_display_sym` in
[`src/include/rapi.hpp`](/src/include/rapi.hpp)),
and [`R/progress_display.R`](/R/progress_display.R) draws it,
throttled so that a fast query never paints:
updates closer together than half a second are dropped.

**The Connections pane** is RStudio-only and lives in
[`R/Viewer.R`](/R/Viewer.R), adapted from the odbc package's.
It queries `information_schema` to decide which object types the
database actually has, so a database with no views does not advertise
them, and it tells the IDE when a connection closes.

*To deepen: state what turns the progress display on and off, and what
the pane does with a connection the user closes from the IDE.*
