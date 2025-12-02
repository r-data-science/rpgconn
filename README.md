# rpgconn <img src="man/figures/logo.png" align="right" height="120" alt="" />


<!-- badges: start -->
[![Codecov](https://codecov.io/gh/r-data-science/rpgconn/branch/main/graph/badge.svg)](https://app.codecov.io/gh/r-data-science/rpgconn?branch=main)
[![R-CMD-check](https://github.com/r-data-science/rpgconn/actions/workflows/R-CMD-check.yaml/badge.svg?branch=main)](https://github.com/r-data-science/rpgconn/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/r-data-science/rpgconn/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/r-data-science/rpgconn/actions/workflows/test-coverage.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/rpgconn)](https://CRAN.R-project.org/package=rpgconn)
<!-- badges: end -->

The goal of rpgconn is to provide a simple interface for connecting to a PostgreSQL database.

## Setting RPG_CONN_STRING

The environment variable `RPG_CONN_STRING` must be set. The package supports multiple valid PostgreSQL connection string formats:

### URI Format (Recommended)

``` r
# With username and password
cs <- "postgresql://postgres:some_password@some_host:5432/postgres"
Sys.setenv(RPG_CONN_STRING = cs)

# With query parameters
cs <- "postgresql://postgres:some_password@some_host:5432/postgres?sslmode=require"
Sys.setenv(RPG_CONN_STRING = cs)

# Without password (for trust/peer authentication)
cs <- "postgresql://postgres@some_host:5432/postgres"
Sys.setenv(RPG_CONN_STRING = cs)
```

Note: Both `postgresql://` and `postgres://` prefixes are supported.

### Keyword/Value Format

``` r
# Semicolon-delimited (legacy)
cs <- "user=postgres;password=some_password;host=some_host;port=5432;dbname=postgres"
Sys.setenv(RPG_CONN_STRING = cs)

# Whitespace-delimited (libpq standard)
cs <- "host=some_host user=postgres password=some_password dbname=postgres port=5432"
Sys.setenv(RPG_CONN_STRING = cs)

# With quoted values (for spaces in values)
cs <- "host='my host' user=postgres dbname='my database' port=5432"
Sys.setenv(RPG_CONN_STRING = cs)
```

### Supported Connection Parameters

When using URI format with query parameters, the following are commonly supported:

- `sslmode`: SSL connection mode (`disable`, `allow`, `prefer`, `require`, `verify-ca`, `verify-full`)
- `connect_timeout`: Connection timeout in seconds
- `application_name`: Application identifier
- `options`: Runtime configuration options
- `target_session_attrs`: Required session attributes for high-availability setups

## Installation

```r
install.packages("rpgconn")
# OR
remotes::install_github("r-data-science/rpgconn")
```

## Example


```r
library(rpgconn)
library(DBI)

#open connection
cn <- dbc("some_database")

# List tables
dbListTables(cn)

# Close connection
dbd(cn)
```
