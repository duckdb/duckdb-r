#!/usr/bin/env bash
# Print the version a landing's hand-written bump sets, short of an upstream release.
#
# Takes the version of the branch the landing lands on and the series' version
# the landing's build ends on, and prints the next version above both:
#
#   * the prefix, the first three components, is the larger of the two prefixes;
#   * where it is not the branch's, the bump opens it at `.9000`:
#     `main`'s first landing of its own series takes `2.0.0.9000` to `2.0.99.9000`,
#     and a release branch at `2.0.1` takes a series still on `2.0.0` to `2.0.1.9000`;
#   * where it is, the fourth component goes one up, `2.0.99.9000` to `2.0.99.9001`,
#     or opens at `.9000` on a released version without one, `2.0.1` to `2.0.1.9000`.
#
# A landing that brings an upstream release sets that release instead, which
# the series-land skill's bump block takes before calling this
# (handbook/operations/releases/versioning/README.md).
#
# Usage:
#   scripts/landing-version.sh <branch version> <series version>
set -euo pipefail

[ $# -eq 2 ] || { echo "usage: landing-version.sh <branch version> <series version>" >&2; exit 2; }
for v in "$1" "$2"; do
  [[ "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+){0,2}$ ]] || { echo "landing-version.sh: not a version: $v" >&2; exit 2; }
done

IFS=. read -r b1 b2 b3 b4 _ <<<"$1"
IFS=. read -r s1 s2 s3 _ <<<"$2"
if [ "$(printf '%s\n%s\n' "$b1.$b2.$b3" "$s1.$s2.$s3" | sort -V | tail -n 1)" != "$b1.$b2.$b3" ]; then
  echo "$s1.$s2.$s3.9000"
elif [ -z "${b4:-}" ]; then
  echo "$b1.$b2.$b3.9000"
else
  echo "$b1.$b2.$b3.$((b4 + 1))"
fi
