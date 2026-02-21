# rpgconn <img src="man/figures/logo.png" align="right" height="120" alt="" />

<!-- badges: start -->
[![Codecov](https://codecov.io/gh/r-data-science/rpgconn/branch/main/graph/badge.svg)](https://app.codecov.io/gh/r-data-science/rpgconn?branch=main)
[![R-CMD-check](https://github.com/r-data-science/rpgconn/actions/workflows/R-CMD-check.yaml/badge.svg?branch=main)](https://github.com/r-data-science/rpgconn/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/r-data-science/rpgconn/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/r-data-science/rpgconn/actions/workflows/test-coverage.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/rpgconn)](https://CRAN.R-project.org/package=rpgconn)
<!-- badges: end -->

`rpgconn` is a PostgreSQL connection management package for R.

It gives you one stable interface (`dbc()`) for:
- `RPG_CONN_STRING` environment-variable connections
- YAML-based named configs (`cfg = "dev"`)
- optional config/option file overrides (`cfg_path`, `opt_path`)

The package is designed to fail fast with explicit errors before DBI tries to connect.

## Installation

```r
# CRAN
install.packages("rpgconn")

# Development
pak::pkg_install("r-data-science/rpgconn")
```

## Quick Start

### 1. Connect from `RPG_CONN_STRING`

```r
library(rpgconn)

Sys.setenv(
  RPG_CONN_STRING = "postgresql://user:pass@localhost:5432/mydb?sslmode=require"
)

cn <- dbc()
DBI::dbGetQuery(cn, "SELECT version()")
dbd(cn)
```

### 2. Connect from YAML config

```r
library(rpgconn)

init_yamls()      # creates config + options in tools::R_user_dir("rpgconn", "config")
edit_config()     # edit config.yml

cn <- dbc(cfg = "dev", db = "analytics")
dbd(cn)
```

Example `config.yml`:

```yaml
config:
  dev:
    host: localhost
    port: 5432
    user: app_user
    password: secret
```

### 3. Use project-specific config files

```r
cn <- dbc(
  cfg = "dev",
  db = "analytics",
  cfg_path = "config/dev-db.yml",
  opt_path = "config/dev-options.yml"
)
dbd(cn)
```

## Main API

- `dbc()`: build connection args or open a PostgreSQL connection
- `dbd()`: disconnect
- `init_yamls()`: create default config + options files
- `edit_config()`, `edit_options()`: open active files interactively
- `use_config()`: replace active config with an external YAML file

Notes:
- `dbc(path = ...)` is supported for backward compatibility but deprecated; use `cfg_path`.
- Invalid env-var logging redacts secrets.

## Connection String Formats

`dbc()` accepts:

- URI: `postgresql://user:pass@host:5432/db?sslmode=require`
- URI alias: `postgres://...`
- Keyword/value (semicolon): `host=...;port=...;dbname=...`
- Keyword/value (whitespace): `host=... port=... dbname=...`

## Documentation (Pkgdown + Quarto)

This repo uses:
- roxygen2 for function docs (`R/*.R` -> `man/*.Rd`)
- Quarto vignettes (`vignettes/*.qmd`)
- pkgdown for site generation

Primary long-form docs:
- `vignettes/quickstart.qmd`
- `vignettes/rpgconn.qmd`
- `vignettes/advanced-workflow.qmd`

Build docs locally:

```r
devtools::document()
pkgdown::build_site()
```

## Development Setup

Install all development dependencies declared in `DESCRIPTION`:

```r
pak::local_install_dev_deps(dependencies = TRUE)
```

Daily workflow:

```r
devtools::load_all()
devtools::test()
devtools::check()
```

## Testing Strategy

### Unit tests

Unit tests are hermetic:
- they isolate `R_USER_CONFIG_DIR` to temp directories
- they isolate `RPG_CONN_STRING` per test
- they do not depend on your real `~/.config` files

### Optional local Postgres E2E test

A disposable integration test is included and skipped by default.

Enable locally:

```bash
export RPGCONN_RUN_DB_TESTS=true
export RPGCONN_TEST_CONN_STRING="postgresql://postgres:postgres@localhost:5432/postgres"
```

Then run:

```r
devtools::test()
```

The E2E test uses a temporary table (`CREATE TEMP TABLE`) so test data is removed automatically when the connection closes.

## Release Workflow

Run the full pre-release gate:

```r
devtools::document()
devtools::test()
devtools::check()
devtools::spell_check()
urlchecker::url_check(".")
```

If Quarto cache permissions cause `attempt to write a readonly database`, run:

```r
withr::with_envvar(c(XDG_CACHE_HOME = tempdir()), devtools::check())
```

Then:
- update `NEWS.md`
- refresh `cran-comments.md`
- submit/re-submit to CRAN
- publish GitHub release

## Maintainer Conventions

- Prefer `data.table` semantics whenever tabular manipulation is needed.
- Keep vignettes in Quarto `.qmd` format.
- Keep all exported functions fully documented with roxygen2.
- Avoid logging raw credentials.
- Keep parser changes paired with regression tests.

## Project Layout

- `R/`: package source
- `tests/testthat/`: unit + optional E2E tests
- `vignettes/`: Quarto documentation
- `_pkgdown.yml`: site configuration
- `.github/workflows/`: CI for checks, coverage, pkgdown deploy
- `AGENTS.md`: persistent AI/automation conventions for this repo

## Links

- Package website: <https://r-data-science.github.io/rpgconn/>
- Issues: <https://github.com/r-data-science/rpgconn/issues>
- Questions: <https://github.com/r-data-science/rpgconn/issues/new/choose>
