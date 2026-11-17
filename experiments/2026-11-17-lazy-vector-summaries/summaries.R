# Seconds per call of a summary on a converted lazy column of rel_to_altrep(),
# against the same values in a plain vector, mean of five calls.
# Handbook: experiments/2026-11-17-lazy-vector-summaries/README.md
con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE))
seconds <- function(expr) {
  unname(
    system.time(
      for (k in 1:5) {
        force(expr)
      }
    )[["elapsed"]] /
      5
  )
}
once <- function(expr) unname(system.time(expr)[["elapsed"]])
sql <- paste(
  "SELECT random() AS x, (random() * 100)::INTEGER AS i,",
  "random() < 0.5 AS l, 'a' || (range % 10)::VARCHAR AS s",
  "FROM range(10000000)"
)
lazy <- function() duckdb:::rel_to_altrep(duckdb:::rel_from_sql(con, sql))

# First touch of an unconverted column, conversion included
data.frame(
  op = c("sum(l)", "anyNA(l)", "anyNA(s)", "unique(s)"),
  first_call = c(
    once(sum(lazy()$l)),
    once(anyNA(lazy()$l)),
    once(anyNA(lazy()$s)),
    once(unique(lazy()$s))
  )
)

df <- lazy()
x <- df$x
i <- df$i
l <- df$l
s <- df$s
# Converts each column
invisible(list(x[[1]], i[[1]], l[[1]], s[[1]]))
x_plain <- x + 0
i_plain <- i + 0L
l_plain <- !!l
s_plain <- s[seq_along(s)]

ops <- c("sum()", "max()", "range()", "anyNA()", "mean()", "c()", "* 2")
data.frame(
  op = ops,
  double_altrep = c(
    seconds(sum(x)),
    seconds(max(x)),
    seconds(range(x)),
    seconds(anyNA(x)),
    seconds(mean(x)),
    seconds(c(x)),
    seconds(x * 2)
  ),
  double_plain = c(
    seconds(sum(x_plain)),
    seconds(max(x_plain)),
    seconds(range(x_plain)),
    seconds(anyNA(x_plain)),
    seconds(mean(x_plain)),
    seconds(c(x_plain)),
    seconds(x_plain * 2)
  ),
  integer_altrep = c(
    seconds(sum(i)),
    seconds(max(i)),
    seconds(range(i)),
    seconds(anyNA(i)),
    seconds(mean(i)),
    seconds(c(i)),
    seconds(i * 2L)
  ),
  integer_plain = c(
    seconds(sum(i_plain)),
    seconds(max(i_plain)),
    seconds(range(i_plain)),
    seconds(anyNA(i_plain)),
    seconds(mean(i_plain)),
    seconds(c(i_plain)),
    seconds(i_plain * 2L)
  )
)

data.frame(
  op = c("sum(l)", "anyNA(l)", "c(l)", "anyNA(s)", "unique(s)", "c(s)"),
  altrep = c(
    seconds(sum(l)),
    seconds(anyNA(l)),
    seconds(c(l)),
    seconds(anyNA(s)),
    seconds(unique(s)),
    seconds(c(s))
  ),
  plain = c(
    seconds(sum(l_plain)),
    seconds(anyNA(l_plain)),
    seconds(c(l_plain)),
    seconds(anyNA(s_plain)),
    seconds(unique(s_plain)),
    seconds(c(s_plain))
  )
)
