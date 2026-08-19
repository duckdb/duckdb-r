# Experiments

Evidence lives outside the handbook, under [`experiments/`](/experiments/README.md):
one directory per run, holding what it measured and everything the run took.
A leaf states what is true, and an experiment records what was measured, when, and on what.
The two are different kinds of writing, which is why they live apart.
Intent is [`meta/plans/`](/handbook/meta/plans/README.md)'s.

The leaf that leans on a finding links the directory carrying it, which is what lets a reader weigh the finding without repeating the work.
A finding no leaf cites is an orphan: the tree is how anything here is found, and nobody reads a directory of results looking for an answer.

## What earns a directory

**Only what is too expensive to re-derive.**
The cheaper homes come first, and
[`meta/authoring/`](/handbook/meta/authoring/README.md) walks them in order:
a claim a test can pin, a claim a check can enforce, a derivation a reader can redo in a minute.
What is left is the measurement that needs a specific platform, an old package version, or an hour of compute.
It is committed while the result is fresh, because session scratch space, chat transcripts, and CI logs all expire,
and a finding that lived only there is the same work waiting to be done again.

**An experiment is evidence, not a check.**
Nothing under `experiments/` runs on its own, and nothing there gates a merge.
It carries no intent either.
A finding that argues for a change is quoted by the plan that carries it, and the experiment stays a record of what was measured.

**A record ages rather than rots.**
It is true of the day it names, on the versions it names,
and a leaf leaning on it says so rather than presenting a measurement as a permanent property.
Refreshing one is re-running it, which is why the method is committed.
The finding it replaces is git's, not a section of the page.

## The shape of a directory

The directory is named for the date and the topic, as `YYYY-MM-DD-<topic>/`.

Its `README.md` opens with three italic-labelled paragraphs before anything else,
saying what it measures, when and on what, and what it supports.
The rest is the method, the findings, and how to replicate them.
Everything the run took is committed beside that page.

Whatever can be a standalone R script is recorded as one,
rendered to Markdown with `reprex::reprex(si = TRUE)` and committed beside the script it came from.
An experiment may hold several, one per run,
where the runs are separate questions or the same question against separate builds.

Where reprex cannot host the run, the findings go in the experiment's `README.md` instead.
A run driven from a shell, or one needing a background process, a build, a second machine, or subprocesses, does not fit in a reprex.
What would have been the transcript becomes quoted excerpts chosen for what the finding rests on,
with the driver committed beside them, and whatever output the run recorded.
A raw transcript is committed only where it is short enough to be read whole, and never in place of the excerpts.
A long one is bulk nobody reads, it ages the same as the page, and it buries the handful of lines that carried the point.

Some directories predate these rules, in their name or in their shape, and are left as they are.
Renaming one breaks every inbound link for no gain,
and reshaping a record to a convention younger than it gives a reader nothing they did not have.
