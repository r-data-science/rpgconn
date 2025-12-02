# rpgconn <img src="man/figures/logo.png" align="right" height="120" alt="" />


<!-- badges: start -->
[![Codecov](https://codecov.io/gh/r-data-science/rpgconn/branch/main/graph/badge.svg)](https://app.codecov.io/gh/r-data-science/rpgconn?branch=main)
[![R-CMD-check](https://github.com/r-data-science/rpgconn/actions/workflows/R-CMD-check.yaml/badge.svg?branch=main)](https://github.com/r-data-science/rpgconn/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/r-data-science/rpgconn/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/r-data-science/rpgconn/actions/workflows/test-coverage.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/rpgconn)](https://CRAN.R-project.org/package=rpgconn)
<!-- badges: end -->

The goal of rpgconn is to provide a simple interface for connecting to a PostgreSQL database.

## Setting RPG_CONN_STRING

The environment variable `RPG_CONN_STRING` must be set and have the format shown below.

``` r
cs <- "user=postgres;password=some_password;host=some_host;port=5432;dbname=postgres"
Sys.setenv(RPG_CONN_STRING = cs)
```

## Installation

```r
install.packages("rpgconn")
# OR
remotes::install_github("r-data-science/rpgconn")
```

## Example

### Basic Connection

```r
library(rpgconn)
library(DBI)

# Open connection
cn <- dbc("some_database")

# List tables
dbListTables(cn)

# Close connection
dbd(cn)
```

### Safe Parameterized Queries

rpgconn provides functions for executing parameterized queries safely, protecting against SQL injection attacks:

```r
library(rpgconn)

# Open connection
cn <- dbc("some_database")

# Safe SELECT query with parameters
users <- db_query_safe(
  cn,
  "SELECT * FROM users WHERE age > ? AND city = ?",
  params = list(25, "New York")
)

# Safe INSERT statement
db_execute_safe(
  cn,
  "INSERT INTO users (name, email) VALUES (?, ?)",
  params = list("John Doe", "john@example.com")
)

# Batch INSERT - insert multiple rows at once
new_users <- data.frame(
  name = c("Alice", "Bob", "Charlie"),
  email = c("alice@example.com", "bob@example.com", "charlie@example.com")
)
db_execute_safe(
  cn,
  "INSERT INTO users (name, email) VALUES (?, ?)",
  params = new_users
)

# Safe UPDATE statement
db_execute_safe(
  cn,
  "UPDATE users SET status = ? WHERE age < ?",
  params = list("active", 18)
)

# Close connection
dbd(cn)
```

The parameterized query functions (`db_query_safe` and `db_execute_safe`) use DBI's parameter binding mechanism to ensure that user input is properly escaped and cannot be used to inject malicious SQL code.
