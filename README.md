# rpgconn

<!-- badges: start -->
<!-- badges: end -->

The goal of rpgconn is to provide a simple interface for connecting to a PostgreSQL database.

## Installation

You can install the development version of rpgconn like so:

``` r
# dev version
devtools::install_github("r-data-science/rpgconn")
```

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
