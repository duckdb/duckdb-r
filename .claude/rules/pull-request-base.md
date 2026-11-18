<!--
derived_from:
  - handbook/operations/review/README.md

No front matter: a rule file without `paths` loads in every session, and this
one must, since a pull request can be opened from any session whatever files it
touched. The declaration sits in this comment, as in prose-authoring.md beside
it, because the front matter is Claude Code's.
-->

# Which branch a pull request targets

_Derived from [`handbook/operations/review/`](/handbook/operations/review/README.md), which owns the rule.
This is the short form, and it loads in every session.
Fix the leaf first and re-derive this, never the other way around._

- Branch from, and open the pull request against, the oldest active release branch the change applies to: `v2.0-cyanoptera` today.
  The active ones are the CRAN row's `upstream` in `scripts/series.yaml`
  and every `releases_from` other than `main` on a row not declared `stale: true`.
- Name the base explicitly: `main` is the repository's default branch, so GitHub and `gh pr create` propose it otherwise.
- Target `main` only for a change that concerns only the line `main` previews,
  or one that changes nothing but the tooling every series takes from `main` (`series_tooling` in `scripts/series-config.sh`),
  with its generated files and the handbook pages that describe only that tooling.
  Split a change that mixes tooling with anything else by default: its tooling to `main`, the rest to the release branch.
- The change reaches the newer lines by a forward merge, so it needs no second pull request,
  except a `patch/` entry, which is opened against each line whose engine needs it.
- A landing's review and its forward merge take the bases `series-land` gives them.
- Leave an open pull request's base alone until the maintainer changes it.
