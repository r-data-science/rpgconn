## R CMD check results

0 errors | 0 warnings | 0 notes

* This release addresses CRAN policy feedback and prepares the package for submission.

Changes:

* Updated the Title and Description fields to be more descriptive and to quote
  software and package names ('PostgreSQL', 'odbc', 'RPostgres').
* Added `Depends: R (>= 4.1.0)` and `URL`/`BugReports` entries in the DESCRIPTION.
* Replaced the placeholder MIT licence with the full MIT license text.
* Implemented `tools::R_user_dir()` to store configuration files in a
  user‑specific directory rather than the user's home directory.
* Modified `edit_config()` and `edit_options()` so they open files only in
  interactive sessions and return the file path invisibly in non‑interactive
  contexts.
* Added `@noRd` tags to internal helper functions to suppress unexported Rd files.
* Updated unit tests to avoid calling internal functions directly and to use
  `system.file()` and the new configuration directory.
