# Development Guide

This guide is for maintainers onboarding to `rpgconn`.

## Prerequisites

- R >= 4.1.0
- PostgreSQL client libraries (`libpq`) for `RPostgres`
- Quarto CLI (for vignette + pkgdown article rendering)

## Install Dependencies

```r
pak::local_install_dev_deps(dependencies = TRUE)
```

## Core Commands

```r
devtools::load_all()
devtools::document()
devtools::test()
devtools::check()
```

## Architecture

- `R/pgdbconn.R`:
  - connection string validation/parsing
  - connection orchestration (`dbc`, `dbd`)
  - YAML load helpers
- `R/use-config.R`:
  - adoption of external config files into active package config

### Parse pipeline

1. Validate input format and structural requirements.
2. Parse URI or key/value form into DBI-ready args.
3. Merge options YAML.
4. Connect via `DBI::dbConnect()` unless `args_only = TRUE`.

## Testing

### Unit tests

Unit tests are hermetic and isolate:
- `RPG_CONN_STRING`
- `R_USER_CONFIG_DIR`

### Optional E2E test

`tests/testthat/test-e2e-local-postgres.R` can run against a local disposable database session:

```bash
export RPGCONN_RUN_DB_TESTS=true
export RPGCONN_TEST_CONN_STRING="postgresql://postgres:postgres@localhost:5432/postgres"
```

## Documentation

- Roxygen is authoritative for function docs.
- Vignettes are Quarto `.qmd` files.
- pkgdown site config is `_pkgdown.yml`.

Generate docs:

```r
devtools::document()
pkgdown::build_site()
```

## Style and Conventions

- Prefer explicit `pkg::fn()` calls.
- Use `data.table` patterns for tabular workflows (do not introduce new `data.frame`-centric code).
- Never print plaintext credentials in errors/logs.
