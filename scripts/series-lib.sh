# shellcheck shell=bash
# Shared helpers for the names of a line's generations, sourced by the
# scripts/series-*.sh that read them (handbook/branches/model/README.md).
#
# A line `<L>` such as `v2.0-cyanoptera` is served by generations. Its first
# refs are `<L>-build`, `<L>-dev`, `<L>-green` and `<L>-build-base`; a forward
# creates the next generation beside them as `<L>-v<NNN>-*`, three digits,
# numbered from `v000`, and each generation is built from the newest one before
# it (.claude/skills/series-forward/SKILL.md). The older spelling `<L>-fwd-*` is
# generation `v000` where it exists and no `<L>-v000-*` does, so that nothing
# live is renamed: the next forward of such a line is `v001`.
#
# A series name, as every script takes one, is the line for its first refs and
# `<L>-v<NNN>` or `<L>-fwd` for a generation; the strand suffixes `-build`,
# `-dev`, `-green`, `-build-base`, `-rc-dev`, `-alpha` and `-rc-alpha` follow it.
#
# Every function here reads refs under `refs/remotes/<remote>/`, which the
# calling script has fetched, and writes nothing.

# The line a series name belongs to: its generation suffix stripped.
series_line() { # <series> -> <line>
  case "$1" in
    *-fwd) echo "${1%-fwd}" ;;
    *-v[0-9][0-9][0-9]) echo "${1%-v[0-9][0-9][0-9]}" ;;
    *) echo "$1" ;;
  esac
}

# The generation a series name is: 0 for `-fwd`, N for `-v<NNN>`, and nothing
# for the line's first refs.
series_gen() { # <series> -> <n> | ""
  case "$1" in
    *-fwd) echo 0 ;;
    *-v[0-9][0-9][0-9]) echo $((10#${1##*-v})) ;;
    *) echo "" ;;
  esac
}

# Is there a `-dev` ref of that name on the remote?
series_has_dev() { # <series> <remote>
  git rev-parse -q --verify "refs/remotes/$2/$1-dev^{commit}" >/dev/null 2>&1
}

# The series name of generation <n> of a line. Generation 0 keeps its older
# spelling, `<L>-fwd`, wherever those refs exist and `<L>-v000-dev` does not.
series_gen_name() { # <line> <n> <remote>
  if [ "$2" -eq 0 ] && series_has_dev "$1-fwd" "$3" && ! series_has_dev "$1-v000" "$3"; then
    echo "$1-fwd"
    return
  fi
  printf '%s-v%03d\n' "$1" "$2"
}

# The generation a series was built from: the one below it, and the line's first
# refs below generation 0. Nothing for the first refs themselves.
series_base() { # <series> <remote> -> <series> | ""
  local g
  g=$(series_gen "$1")
  [ -n "$g" ] || return 0
  if [ "$g" -eq 0 ]; then
    series_line "$1"
  else
    series_gen_name "$(series_line "$1")" $((g - 1)) "$2"
  fi
}

# Every generation of a line that has a `-dev`, newest first, the line's first
# refs last when they exist.
series_generations() { # <line> <remote>
  local line=$1 remote=$2 r n
  {
    while IFS= read -r r; do
      r=${r#refs/remotes/"$remote"/}
      r=${r%-dev}
      n=$(series_gen "$r")
      [ -n "$n" ] || continue
      # `-fwd` is generation 0 only while no `v000` spells it.
      case "$r" in *-fwd) series_has_dev "$line-v000" "$remote" && continue ;; esac
      printf '%03d\t%s\n' "$n" "$r"
    done < <(git for-each-ref --format='%(refname)' \
      "refs/remotes/$remote/$line-v[0-9][0-9][0-9]-dev" "refs/remotes/$remote/$line-fwd-dev")
  } | sort -r | cut -f2
  series_has_dev "$line" "$remote" && echo "$line"
  return 0
}

# The newest generation of a line, or the line itself when it has none.
series_newest() { # <line> <remote>
  series_generations "$1" "$2" | head -n 1
}

# The name the next generation of a line takes: one above the newest, `v000`
# for a line that has none, and `v001` where `-fwd` stands for `v000`.
series_next() { # <line> <remote>
  local newest n
  newest=$(series_newest "$1" "$2")
  n=$(series_gen "${newest:-$1}")
  if [ -z "$n" ]; then n=-1; fi
  printf '%s-v%03d\n' "$1" $((n + 1))
}

# One field of a flavor's declaration in `scripts/series.yaml`, read from a
# tree-ish (`main`'s, as scripts/series-port.sh reads `releases_from`), for the
# flavor whose `series:` names the line. Empty when undeclared.
series_yaml_field() { # <tree-ish> <line> <field>
  { git show "$1:scripts/series.yaml" 2>/dev/null || true; } |
    awk -v s="$2" -v f="$3:" '
      /^  - / { if (ser == s) print val; ser = ""; val = ""; sub(/^  - /, "    ") }
      /^    series:/ { ser = $2 }
      $1 == f { val = $2 }
      END { if (ser == s) print val }' | head -n 1
}

# The generation r-universe publishes for a line: the series whose `-green` the
# declaration's `publishes_from` names, or nothing where none is declared.
series_published() { # <tree-ish> <line>
  local from
  from=$(series_yaml_field "$1" "$2" publishes_from)
  case "$from" in
    "$2"-green | "$2"-v[0-9][0-9][0-9]-green | "$2"-fwd-green) echo "${from%-green}" ;;
  esac
}

# Is a generation served by the loop? The two newest generations of its line
# are, and so is the published one wherever it is older than those; everything
# else is frozen (.claude/skills/series-loop/SKILL.md).
series_served() { # <series> <remote> <published series or "">
  local line gens
  line=$(series_line "$1")
  [ "$1" != "${3:-}" ] || return 0
  gens=$(series_generations "$line" "$2" | head -n 2)
  grep -qxF -- "$1" <<<"$gens"
}
