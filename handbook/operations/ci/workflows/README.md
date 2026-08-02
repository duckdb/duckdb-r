# Workflows

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](/handbook/meta/handbook/);
the last section holds this leaf's parameters.*

Scope: the inventory under [`.github/workflows/`](/.github/workflows):
what each gates, and where it runs.

Today:

* no prose owner today; the workflow files themselves are the record

To write this leaf:

* write the inventory from `.github/workflows/`:
  one line per workflow — trigger, what it gates, which branches
* never add `.github/README.md` — GitHub would surface it as the
  repository front page (precedence `.github/` → root → `docs/`)
