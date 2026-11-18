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
  or one that changes nothing but tooling that takes effect from `main`'s copy,
  with its generated files and the handbook pages that describe only that tooling.
  Where a release branch's own copy needs the same change too, pick it onto that branch once it has merged.
  Split a change that mixes such tooling with anything else by default: its tooling to `main`, the rest to the release branch.
- Where tooling takes effect decides its target, not that it is tooling.
  `main`'s copy is the tooling the series loop runs and the series refs run, which the port stage syncs from `main`,
  and what GitHub runs on a `schedule`, `workflow_run` or `pull_request_target` trigger.
  A release branch's own copy runs on a `push` or `workflow_dispatch` run on that branch
  and on a `pull_request` or `merge_group` run into it, which reads the merge into its base, and so do the scripts these call.
  Tooling that takes effect only from a release branch's own copy, such as a trigger that fires only for release branches,
  targets that branch and reaches `main` by the forward merge.
  A change to a file `cynkra/cynkratemplate` owns goes to the template too.
- The change reaches the newer lines by a forward merge, so it needs no second pull request,
  except a `patch/` entry, which is opened against each line whose engine needs it.
- A landing's review and its forward merge take the bases `series-land` gives them.
- Leave an open pull request's base alone until the maintainer changes it.
