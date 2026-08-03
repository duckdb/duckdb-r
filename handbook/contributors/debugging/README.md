# Debugging

Reproducing a crash or a memory error under an R built to catch it,
when the ordinary build only shows the symptom.

[`docker/`](/docker) holds two images, both on `wch1/r-debug`,
and [`docker-compose.yml`](/docker-compose.yml) names them as services
with the repository mounted at `/root/workspace`,
so a container sees the working tree as it stands.
Each image installs this package's dependencies at build time from
`docker/deps.R`, against the R build it instruments.

Which instrumented R each one runs is its own script under `docker/` —
`RDstrictbarrier` for write-barrier violations,
`RDthreadcheck` for threading ones.

*To deepen: state what each build catches, which failures are worth
reaching for it, and how to run the suite inside one.*
