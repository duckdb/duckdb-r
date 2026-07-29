#!/usr/bin/env python3
"""Partition a commit range into contiguous, cost-balanced `each-rcc` shards.

Reads `<sha> <invalidated-objects>` lines, oldest first -- what
`scripts/each-cost.py batch` produces -- and writes the shard list
`scripts/each-plan.sh` turns into a matrix.

Two passes, and they optimise different things.

**Pass 1, greedy fill** minimises the number of legs subject to the leg
deadline. Shards must be contiguous, because that is what makes consecutive
checkouts cheap, so this is not bin packing: partitioning a sequence into the
fewest contiguous parts under a fixed budget is solved exactly by one
left-to-right pass. That pass alone is the cheapest possible plan in
runner-minutes, and for a small batch it is also the slowest possible plan in
wall clock -- 25 commits fit in two 300-minute legs, so the branch tip waits
five hours for a verdict it could have had in one.

**Pass 2, splitting** buys that wall clock back. It repeatedly splits the
longest shard, which is the only shard that can be setting the makespan, and
stops at the first of three limits:

  * `--max-parallel` -- more legs than can run at once move no verdict earlier,
    they only queue;
  * `--split-factor` -- the plan may cost at most this multiple of the pass-1
    plan's runner-minutes;
  * a longest shard of one commit, which cannot be split further.

Each split costs exactly one more cold build plus one more job setup, because
the second half no longer inherits the first half's ccache. That is the whole
of the trade, and `--split-factor` is the dial on it.

The cost model per leg:

    build_minutes    = FULL + sum(min(FLOOR + OBJECT_SECONDS * objects, FULL))
                                                        over all but the first
    estimate_minutes = SETUP + build_minutes

The first commit of a leg pays FULL rather than its own weight: it starts on an
empty ccache, so it rebuilds all of `sources.mk` no matter how little it
changed. `build_minutes` is what `scripts/each-shard.sh` measures itself
against (its deadline starts after setup); `estimate_minutes` is the job's wall
clock.
"""

import argparse
import json
import sys


def parse_args(argv):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--budget", type=float, default=300.0,
                   help="leg deadline in minutes, excluding job setup")
    p.add_argument("--setup", type=float, default=5.0,
                   help="per-leg checkout, R and dependency install")
    p.add_argument("--full", type=float, default=40.0,
                   help="a build on an empty ccache -- all of sources.mk")
    p.add_argument("--floor", type=float, default=6.0,
                   help="per-commit link, install, check and gates")
    p.add_argument("--object-seconds", type=float, default=9.7,
                   help="marginal cost of recompiling one unity object")
    p.add_argument("--max-shards", type=int, default=250)
    p.add_argument("--max-parallel", type=int, default=20)
    p.add_argument("--split-factor", type=float, default=1.5,
                   help="runner-minutes the split plan may cost, as a multiple "
                        "of the fewest-legs plan; 1.0 disables splitting")
    return p.parse_args(argv)


def read_items(stream):
    items = []
    for line in stream:
        fields = line.split()
        if len(fields) >= 2:
            items.append((fields[0], int(fields[1])))
    return items


class Model:
    def __init__(self, args):
        self.setup = args.setup
        self.full = args.full
        self.floor = args.floor
        self.objsec = args.object_seconds

    def warm(self, objects):
        """A commit built on the ccache its predecessor in the leg left behind."""
        return min(self.floor + objects * self.objsec / 60.0, self.full)

    def weights(self, shard):
        """Marginal minutes per commit, in leg order. The first pays a cold build."""
        return [self.full if i == 0 else self.warm(objects)
                for i, (_sha, objects) in enumerate(shard)]

    def build_minutes(self, shard):
        return sum(self.weights(shard))

    def estimate_minutes(self, shard):
        return self.setup + self.build_minutes(shard) if shard else 0.0


def greedy(items, model, budget):
    """Fewest contiguous shards whose build time stays under the deadline.

    A single commit heavier than the budget still gets its own shard rather
    than being dropped; the leg's own deadline handles the overrun.
    """
    shards, current, used = [], [], 0.0
    for item in items:
        weight = model.warm(item[1]) if current else model.full
        if current and used + weight > budget:
            shards.append(current)
            current, used, weight = [], 0.0, model.full
        current.append(item)
        used += weight
    if current:
        shards.append(current)
    return shards


def makespan(shards, model, parallel):
    """Wall clock of the whole matrix, newest shard submitted first."""
    if not shards:
        return 0.0
    slots = [0.0] * max(1, min(parallel, len(shards)))
    for shard in reversed(shards):
        i = min(range(len(slots)), key=lambda j: slots[j])
        slots[i] += model.estimate_minutes(shard)
    return max(slots)


def best_cut(shard, model):
    """The contiguous cut that leaves the shorter longer half."""
    best = None
    for i in range(1, len(shard)):
        head, tail = shard[:i], shard[i:]
        longer = max(model.estimate_minutes(head), model.estimate_minutes(tail))
        if best is None or longer < best[0]:
            best = (longer, head, tail)
    return best[1], best[2]


def split(shards, model, parallel, factor):
    """Split the longest shard while it is affordable and there is a slot free.

    Splitting the *longest* shard is what makes this terminate usefully: with
    fewer shards than slots the makespan is that shard's own time, and both
    halves of a contiguous cut are shorter than the whole, so every accepted
    split strictly shortens the critical path.
    """
    shards = [list(s) for s in shards]
    limit = min(parallel, sum(len(s) for s in shards))
    base = sum(model.estimate_minutes(s) for s in shards)
    splits = 0

    while len(shards) < limit:
        i = max(range(len(shards)), key=lambda j: model.estimate_minutes(shards[j]))
        if len(shards[i]) < 2:
            # The critical path is one commit; nothing left to parallelise.
            break
        head, tail = best_cut(shards[i], model)
        trial = shards[:i] + [head, tail] + shards[i + 1:]
        if sum(model.estimate_minutes(s) for s in trial) > factor * base:
            break
        shards = trial
        splits += 1

    return shards, splits


def main(argv):
    args = parse_args(argv)
    model = Model(args)
    items = read_items(sys.stdin)

    shards = greedy(items, model, args.budget)
    planned = len(shards)
    before = {
        "shards": planned,
        "makespan_minutes": round(makespan(shards, model, args.max_parallel), 1),
        "runner_minutes": round(sum(model.estimate_minutes(s) for s in shards), 1),
    }

    factor = max(1.0, args.split_factor)
    parallel = min(args.max_parallel, args.max_shards)
    shards, splits = split(shards, model, parallel, factor)

    # Capping drops the *oldest* shards; the next run replans them.
    deferred = 0
    if len(shards) > args.max_shards:
        dropped = shards[:len(shards) - args.max_shards]
        deferred = sum(len(s) for s in dropped)
        shards = shards[len(shards) - args.max_shards:]

    out = {
        "shards": [
            {
                "commits": [
                    {"sha": sha, "objects": objects,
                     "weight_minutes": round(weight, 2)}
                    for (sha, objects), weight in zip(shard, model.weights(shard))
                ],
                "build_minutes": round(model.build_minutes(shard), 1),
                "estimate_minutes": round(model.estimate_minutes(shard), 1),
            }
            for shard in shards
        ],
        "deferred": deferred,
        "split": {
            "factor": factor,
            "splits": splits,
            "before": before,
            "after": {
                "shards": len(shards),
                "makespan_minutes": round(makespan(shards, model, args.max_parallel), 1),
                "runner_minutes": round(sum(model.estimate_minutes(s) for s in shards), 1),
            },
        },
    }
    json.dump(out, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
