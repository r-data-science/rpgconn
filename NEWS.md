# rpgconn 0.4.0

## Breaking Changes

None. All existing code continues to work without modification.

## New Features

* **Robust PostgreSQL URI Connection String Parsing** (#9, #10)
  - Support for standard PostgreSQL URI format: `postgresql://user:pass@host:5432/db`
  - Both `postgresql://` and `postgres://` prefixes supported
  - Query parameter support: `?sslmode=require&connect_timeout=10&application_name=MyApp`
  - IPv6 host support with bracket notation: `postgresql://user@[2001:db8::1]:5432/db`
  - Proper URL-encoding for credentials with special characters (`@`, `:`, `/`, etc.)
  - Validation-first architecture catches errors early with clear, actionable messages

* **Enhanced Documentation**
  - Three comprehensive vignettes:
    - `vignette("rpgconn")` - Package overview and design philosophy
    - `vignette("quick-start")` - 5-minute setup guide for cloud and local databases
    - `vignette("advanced-usage")` - SSL config, IPv6, troubleshooting, and advanced patterns
  - WHY-focused inline code comments explaining design decisions
  - Complete roxygen2 documentation with `@family`, `@seealso`, `@keywords`, and `@concept` tags
  - Runnable examples for all exported functions (wrapped in `\dontrun{}`)
  - Cross-referenced documentation following tidyverse style guide

## Improvements

* Connection string validation now fails fast with helpful error messages instead of cryptic DBI errors
* Completely rewritten README with clear value proposition and before/after comparisons
* Test coverage increased to 85%+ with 97 comprehensive test cases
* Proper handling of quoted values in keyword/value format connection strings
* Better test isolation to prevent environment variable pollution
* Improved error messages reference specific connection string requirements

## Bug Fixes

* Fixed handling of colons in passwords (requires URL encoding: `pass:word` → `pass%3Aword`)
* Fixed handling of equals signs in query parameter values
* Fixed parsing of quoted values containing spaces in keyword/value format
* Fixed port parsing to properly handle IPv6 addresses and hostnames with colons

## Internal Changes

* Refactored connection string parsing into three focused functions:
  - `.validate_conn_str()` - Upfront validation with clear errors
  - `parse_conn_str()` - Robust URI parsing with IPv6 and URL decoding support
  - `parse_kv_conn_string()` - Enhanced keyword/value parser with quote handling
  - `tokenize_kv_string()` - Quote-aware tokenizer for whitespace-delimited format
* Added comprehensive inline comments explaining design rationale
* All parsing functions now marked `@keywords internal` for cleaner API surface

---

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
