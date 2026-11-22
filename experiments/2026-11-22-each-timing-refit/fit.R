# Refits the per-commit cost model of scripts/each-partition.py to data.tsv,
# and replays the plan of run 44932694459 under the old and the new constants.
# The committed data.tsv is the snapshot the planner's constants were fitted
# to; re-running collect.sh picks up later records and changes it, and with it
# every number below.
# Handbook: handbook/operations/ci/per-commit/planning/README.md

d <- read.delim("data.tsv")
m <- d[!is.na(d$minutes), ]
m$cold <- m$pos == 1
table(run = m$run, cold = m$cold)

# The model: the first commit of a leg pays FULL, every later one
# FLOOR + OBJECT_SECONDS * objects, capped at FULL.
predict_minutes <- function(p, objects, cold) {
  ifelse(
    cold,
    p[["full"]],
    pmin(p[["floor"]] + p[["objsec"]] * objects / 60, p[["full"]])
  )
}
rmse <- function(p, x) {
  sqrt(mean((x$minutes - predict_minutes(p, x$objects, x$cold))^2))
}
bias <- function(p, x) mean(x$minutes - predict_minutes(p, x$objects, x$cold))

old <- c(full = 40, floor = 6, objsec = 9.7)
sse <- function(v) {
  sum(
    (m$minutes -
      predict_minutes(
        c(full = v[1], floor = v[2], objsec = v[3]),
        m$objects,
        m$cold
      ))^2
  )
}
fit <- optim(c(40, 6, 9.7), sse)
round(setNames(fit$par, names(old)), 2)
new <- c(full = 48, floor = 9.3, objsec = 10)

# Old against new, over all records, the warm ones and the cold ones.
sapply(list(old = old, new = new), function(p) {
  c(
    rmse_all = rmse(p, m),
    rmse_warm = rmse(p, m[!m$cold, ]),
    rmse_cold = rmse(p, m[m$cold, ]),
    bias_all = bias(p, m)
  )
}) |>
  round(2)

# Cold builds: flat, and independent of what the commit changed.
summary(m$minutes[m$cold])
cor(m$minutes[m$cold], m$objects[m$cold])

# Warm builds by invalidated objects: measured mean against both models.
w <- m[!m$cold, ]
w$bin <- cut(w$objects, c(-1, 2, 5, 20, 40, 80, 160, 230, Inf))
do.call(
  rbind,
  lapply(split(w, w$bin), function(x) {
    data.frame(
      n = nrow(x),
      measured = mean(x$minutes),
      p10 = unname(quantile(x$minutes, 0.1)),
      p90 = unname(quantile(x$minutes, 0.9)),
      old = mean(predict_minutes(old, x$objects, FALSE)),
      new = mean(predict_minutes(new, x$objects, FALSE))
    )
  })
) |>
  round(1)

# A separate cap for warm builds, below the cold build, buys almost nothing.
sse4 <- function(v) {
  sum(
    (m$minutes -
      ifelse(m$cold, v[1], pmin(v[2] + v[3] * m$objects / 60, v[4])))^2
  )
}
fit4 <- optim(c(48, 9, 10, 46), sse4)
round(
  c(
    setNames(fit4$par, c("full", "floor", "objsec", "warm_cap")),
    rmse = sqrt(fit4$value / nrow(m))
  ),
  2
)

# Job overhead outside the build loop, on the legs that built every commit
# they started (a leg that killed a commit at its deadline spent the rest of
# the job in that commit): setup, and the steps after the loop.
jobs <- read.delim("jobs.tsv")
jobs$shard <- as.integer(sub("shard (\\d+) .*", "\\1", jobs$job))
jobs$job_minutes <- as.numeric(difftime(
  as.POSIXct(jobs$completed, "UTC", format = "%Y-%m-%dT%H:%M:%SZ"),
  as.POSIXct(jobs$started, "UTC", format = "%Y-%m-%dT%H:%M:%SZ"),
  units = "mins"
))
r1 <- d[d$run == 44932694459, ]
built <- aggregate(minutes ~ shard, r1, sum)
jobs <- merge(jobs, built)
jobs$outside <- jobs$job_minutes - jobs$minutes
summary(jobs$outside[jobs$outside < 10])
max(jobs$job_minutes)

# Replay: plan run 1's 822 commits with a set of constants, then run every leg
# through the deadline logic of scripts/each-shard.sh on the measured times.
# A commit measured warm keeps that time wherever it lands warm; a cold one
# keeps its own cold time if it has one, else the mean cold build; a commit
# without a record takes the new model's estimate.
warm_minutes <- setNames(m$minutes[!m$cold], m$sha[!m$cold])
cold_minutes <- setNames(m$minutes[m$cold], m$sha[m$cold])
actual <- function(sha, objects, first) {
  if (first) {
    return(
      if (sha %in% names(cold_minutes)) {
        cold_minutes[[sha]]
      } else {
        mean(cold_minutes)
      }
    )
  }
  if (sha %in% names(warm_minutes)) {
    return(warm_minutes[[sha]])
  }
  predict_minutes(new, objects, FALSE)
}
leg <- function(commits, deadline = 300) {
  t <- 0
  last <- 0
  built <- 0
  for (k in seq_len(nrow(commits))) {
    remaining <- deadline - t
    if (k > 1 && remaining <= last) {
      break
    }
    a <- actual(commits$sha[k], commits$objects[k], k == 1)
    if (k > 1 && a > remaining) {
      break
    }
    t <- t + a
    last <- a
    built <- built + 1
  }
  c(commits = nrow(commits), built = built, planned = commits$planned[1])
}
items <- r1[order(r1$shard, r1$pos), c("sha", "objects")]
replay <- function(p) {
  args <- c(
    "../../scripts/each-partition.py",
    "--budget",
    300,
    "--setup",
    5,
    "--full",
    p[["full"]],
    "--floor",
    p[["floor"]],
    "--object-seconds",
    p[["objsec"]],
    "--max-parallel",
    20,
    "--split-factor",
    1.5
  )
  plan <- jsonlite::fromJSON(system2(
    "python3",
    args,
    input = paste(items$sha, items$objects),
    stdout = TRUE
  ))
  legs <- t(sapply(seq_along(plan$shards$commits), function(i) {
    leg(cbind(plan$shards$commits[[i]], planned = plan$shards$build_minutes[i]))
  }))
  c(
    legs = nrow(legs),
    complete = sum(legs[, "built"] == legs[, "commits"]),
    built = sum(legs[, "built"]),
    longest_planned = max(legs[, "planned"]),
    makespan = plan$split$after$makespan_minutes,
    runner = plan$split$after$runner_minutes
  )
}
sapply(list(old = old, new = new), replay)

# What run 1 actually did, to check the replay of the old plan against.
c(
  legs = length(unique(r1$shard)),
  built = sum(!is.na(r1$minutes)),
  complete = sum(tapply(!is.na(r1$minutes), r1$shard, all))
)

# Run 1's legs packed to the deadline: what the old constants planned for each,
# and what its commits add up to, measured where a record exists and taken
# from `actual()` where none does.
r1$planned <- predict_minutes(old, r1$objects, r1$pos == 1)
r1$actual <- mapply(actual, r1$sha, r1$objects, r1$pos == 1)
per_leg <- aggregate(cbind(planned, actual) ~ shard, r1, sum)
packed <- per_leg[per_leg$planned > 250, ]
nrow(packed)
round(rbind(planned = range(packed$planned), actual = range(packed$actual)), 1)
round(median(packed$actual), 1)
