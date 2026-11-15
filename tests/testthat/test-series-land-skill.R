# The series-land skill's fast-forward block, in step 6, lifts the freeze on a
# branch and pushes to it, so it must stop before touching anything unless
# `--status` printed READY, and put the freeze back whatever the push did
# (.claude/skills/series-land/SKILL.md).
# The block is read off the skill by the marker above it and run with bash in a
# scratch repository, `scripts/series-land.sh` and `gh` stubbed.
#
# The skill lives in the checkout, so this runs from one and skips under
# `R CMD check`, as test-types-rd.R does.

skill_block <- function(path, marker) {
  lines <- readLines(path, warn = FALSE)
  at <- which(lines == marker)
  stopifnot(length(at) == 1)
  rest <- seq(at + 1, length(lines))
  open <- rest[lines[rest] == "```sh"][1]
  rest <- seq(open + 1, length(lines))
  close <- rest[lines[rest] == "```"][1]
  lines[seq(open + 1, close - 1)]
}

sh <- function(...) {
  out <- suppressWarnings(system2(
    "bash",
    c("-c", shQuote(paste0(...))),
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(out, "status")
  structure(out, status = if (is.null(status)) 0L else status)
}

# A scratch checkout whose `upstream` is a bare repository with `main`, a
# `scripts/series-land.sh` that names `main` and prints the status file, and a
# `gh` on PATH that logs each call, answers the ruleset query with
# $RULESET_ID, and records where `main` stands when the freeze comes back.
local_landing <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  withr::local_dir(dir, .local_envir = env)
  sh(
    "set -e
    git init -q --bare -b main upstream.git
    git init -q -b main work
    cd work
    git config user.name Test
    git config user.email test@example.invalid
    git config commit.gpgsign false
    echo base > f
    git add f
    git commit -qm base
    git remote add upstream ../upstream.git
    git push -q upstream main
    mkdir -p scripts ../bin
    cat > scripts/series-land.sh <<'EOF'
#!/bin/bash
case \" $* \" in
  *' --target '*) echo main ;;
  *' --status '*) cat \"$STATUS_FILE\" ;;
esac
EOF
    cat > ../bin/gh <<'EOF'
#!/bin/bash
echo \"gh $*\" >> \"$GH_LOG\"
case \" $* \" in
  *' --jq '*) echo \"$RULESET_ID\" ;;
  *enforcement=active*) echo \"main at $(git ls-remote upstream refs/heads/main | cut -f1)\" >> \"$GH_LOG\" ;;
esac
EOF
    chmod +x scripts/series-land.sh ../bin/gh"
  )
  withr::local_dir(file.path(dir, "work"), .local_envir = env)
  withr::local_envvar(
    PATH = paste(file.path(dir, "bin"), Sys.getenv("PATH"), sep = ":"),
    GH_LOG = file.path(dir, "gh.log"),
    STATUS_FILE = file.path(dir, "status"),
    RULESET_ID = "42",
    .local_envir = env
  )
  writeLines(
    skill_block(skill, "<!-- series-land: fast-forward block -->"),
    file.path(dir, "block.sh")
  )
  file.create(file.path(dir, "gh.log"))
  dir
}

upstream_refs <- function() sh("git ls-remote upstream")
gh_log <- function(dir) readLines(file.path(dir, "gh.log"))
run_block <- function(dir) sh("bash ", shQuote(file.path(dir, "block.sh")))

root <- normalizePath(test_path("..", ".."), mustWork = FALSE)
skill <- file.path(root, ".claude", "skills", "series-land", "SKILL.md")

test_that("the fast-forward block changes nothing unless the landing is READY", {
  skip_if_not(
    file.exists(skill),
    "Not running from a checkout of the package source."
  )
  skip_if(
    Sys.which("git") == "" || Sys.which("bash") == "",
    "git or bash is not available."
  )
  dir <- local_landing()
  before <- upstream_refs()

  writeLines("NOT READY: 3 commits have not passed", file.path(dir, "status"))
  out <- run_block(dir)
  expect_false(attr(out, "status") == 0)
  expect_match(paste(out, collapse = "\n"), "not READY")
  expect_identical(upstream_refs(), before)
  expect_false(any(grepl("enforcement=disabled", gh_log(dir))))

  # READY, but no freeze ruleset to lift: still nothing.
  sh("echo next > f && git commit -qam next")
  sha <- sh("git rev-parse HEAD")
  writeLines(
    c(
      "READY: every commit has passed",
      paste0("  git push upstream ", sha, ":refs/heads/main")
    ),
    file.path(dir, "status")
  )
  withr::local_envvar(RULESET_ID = "")
  out <- run_block(dir)
  expect_false(attr(out, "status") == 0)
  expect_identical(upstream_refs(), before)
  expect_false(any(grepl("enforcement=disabled", gh_log(dir))))
})

test_that("the fast-forward block pushes a READY landing and puts the freeze back after", {
  skip_if_not(
    file.exists(skill),
    "Not running from a checkout of the package source."
  )
  skip_if(
    Sys.which("git") == "" || Sys.which("bash") == "",
    "git or bash is not available."
  )
  dir <- local_landing()

  sh("echo next > f && git commit -qam next")
  sha <- sh("git rev-parse HEAD")
  writeLines(
    c(
      "READY: every commit has passed",
      paste0("  git push upstream ", sha, ":refs/heads/main")
    ),
    file.path(dir, "status")
  )
  out <- run_block(dir)
  expect_identical(attr(out, "status"), 0L)
  expect_identical(
    as.character(sh("git ls-remote upstream refs/heads/main | cut -f1")),
    as.character(sha)
  )
  log <- gh_log(dir)
  off <- grep("enforcement=disabled", log)
  on <- grep("enforcement=active", log)
  expect_length(off, 1)
  expect_length(on, 1)
  expect_true(off < on)
  expect_identical(log[on + 1], paste("main at", sha))
})

test_that("the fast-forward block puts the freeze back when the push is refused", {
  skip_if_not(
    file.exists(skill),
    "Not running from a checkout of the package source."
  )
  skip_if(
    Sys.which("git") == "" || Sys.which("bash") == "",
    "git or bash is not available."
  )
  dir <- local_landing()
  before <- upstream_refs()

  # A commit beside `main` rather than on it: not a fast-forward.
  sh(
    "git checkout -q --orphan side && echo side > f && git add f && git commit -qm side"
  )
  sha <- sh("git rev-parse HEAD")
  writeLines(
    c(
      "READY: every commit has passed",
      paste0("  git push upstream ", sha, ":refs/heads/main")
    ),
    file.path(dir, "status")
  )
  out <- run_block(dir)
  expect_false(attr(out, "status") == 0)
  expect_identical(upstream_refs(), before)
  log <- gh_log(dir)
  expect_true(
    grep("enforcement=disabled", log) < grep("enforcement=active", log)
  )
})
