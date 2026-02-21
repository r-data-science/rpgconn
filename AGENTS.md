# AGENTS.md

## Repository: rpgconn

This file is the persistent operations guide for humans and coding agents working in this repository.

## Project Purpose

`rpgconn` provides a user-friendly PostgreSQL connection workflow for R with:
- environment-variable support (`RPG_CONN_STRING`)
- YAML config management
- optional config/option path overrides
- explicit parsing/validation with actionable errors

## Non-Negotiable Conventions

1. Use `data.table` semantics for tabular work. Do not introduce `data.frame`-centric patterns in new code.
2. Vignettes must be Quarto `.qmd` files.
3. Every exported function must have complete, self-contained roxygen2 documentation.
4. Do not log raw credentials. Redact passwords in errors and diagnostics.
5. Keep parser changes paired with regression tests.

## API Expectations

- Primary user entrypoint: `dbc()`
- Supported connection inputs:
  - PostgreSQL URI (`postgresql://...` or `postgres://...`)
  - libpq key/value strings (`host=... port=... dbname=...`)
  - named YAML config entries (`cfg = "..."`)
- `dbc(path = ...)` is deprecated compatibility behavior; prefer `cfg_path`.

## Development Standards

- R >= 4.1.0
- Explicit `pkg::fn()` usage in package code
- testthat edition 3
- roxygen2-generated docs in `man/`
- pkgdown website driven by `_pkgdown.yml`

## Repository Map

- `R/`: source code
- `tests/testthat/`: unit tests + optional local Postgres E2E test
- `vignettes/*.qmd`: Quarto vignettes
- `README.md`: root onboarding + maintainer workflow
- `NEWS.md`: release notes
- `_pkgdown.yml`: website navigation/config
- `.github/workflows/`: CI pipelines

## Setup and Dependency Management

Use pak for dependency management.

```r
pak::local_install_dev_deps(dependencies = TRUE)
```

Useful pak helpers:
- `pak::local_dev_deps()`
- `pak::local_install_dev_deps()`
- `pak::pkg_install()`

## Local QA Gate (Run Before Release)

```r
devtools::document()
devtools::test()
devtools::check()
devtools::spell_check()
urlchecker::url_check(".")
```

## Testing Policy

### Unit tests

- Must be hermetic.
- Must not rely on real user config paths.
- Isolate state using temporary `R_USER_CONFIG_DIR` and scoped env vars.

### Optional E2E PostgreSQL test

`tests/testthat/test-e2e-local-postgres.R` is skipped unless enabled.

Enable with:

```bash
export RPGCONN_RUN_DB_TESTS=true
export RPGCONN_TEST_CONN_STRING="postgresql://postgres:postgres@localhost:5432/postgres"
```

E2E tests should create only temporary resources (for example `CREATE TEMP TABLE`) and leave no persistent data behind.

## Documentation Policy

- Keep README complete for a new maintainer.
- Keep function docs synchronized via roxygen2.
- Keep vignettes aligned with current API names and arguments.
- Keep pkgdown navigation current.

## Release Policy

- Update `NEWS.md` with user-visible and internal changes.
- Ensure `cran-comments.md` reflects current submission/check state.
- Confirm no stale argument names or removed features remain in docs.

## Agent Handoff Requirement

Any agent completing substantial work must provide a concise execution summary that includes:
- user-facing changes
- internal changes
- test/check outcomes
- remaining risks or follow-ups
