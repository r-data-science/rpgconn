# rpgconn 0.3.3 (Development)

## New Features

* Added `db_query_safe()` function for executing parameterized SELECT queries safely
* Added `db_execute_safe()` function for executing parameterized INSERT/UPDATE/DELETE statements safely
* Both functions support batch operations via data frame parameters
* Parameterized queries use DBI's binding mechanism to prevent SQL injection attacks

# rpgconn 0.3.2

## New Features

* Added optional `path` argument to `dbc()` function to allow users to override any existing config file set by the user (R/pgdbconn.R:26)
* Internal functions `load_c_args()` and `load_c_opts()` now accept optional `path` parameter for config file override

## Minor Improvements

* Updated RoxygenNote to 7.3.3
* Improved code formatting in `use_config()` function
* Enhanced documentation for `init_yamls()` function

# rpgconn 0.3.1

* Previous release

# rpgconn 0.3.0

* Previous release
