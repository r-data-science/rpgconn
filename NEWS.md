# rpgconn development

## Highlights

- Start of development cycle after `0.4.1` CRAN submission.
- No user-facing changes yet.

---

# rpgconn 0.4.1

## Highlights

- Hardened connection parsing and validation for malformed inputs.
- Redacted credentials in invalid connection-string diagnostics.
- Disabled YAML expression evaluation when loading config/options.
- Added backward-compatible (deprecated) support for `dbc(path = ...)`.
- Reworked tests to be hermetic (isolated config/env state).
- Added optional local PostgreSQL end-to-end test (temp-table based).
- Expanded maintainer onboarding docs (`README.md`, `DEVELOPMENT.md`, `RELEASE.md`, `AGENTS.md`).

## Breaking Changes

- None intended.

## Internal/Quality Improvements

- Added regression coverage for URI and keyword/value edge cases.
- Improved config/options YAML structure validation errors.
- Updated package metadata `Suggests` to cover release/test/docs workflows.

---

# rpgconn 0.4.0

## Breaking Changes

- None. All existing code continues to work without modification.

## New Features

- Robust PostgreSQL URI connection string parsing.
- Support for both `postgresql://` and `postgres://` prefixes.
- Query parameter support (`sslmode`, `connect_timeout`, `application_name`, etc.).
- IPv6 host support with bracket notation.
- URL-encoded credential handling.

## Documentation Improvements

- Added three vignettes:
  - `vignette("rpgconn")`
  - `vignette("quickstart")`
  - `vignette("advanced-workflow")`
- Expanded inline rationale comments and cross-referenced docs.

## Parser/Validation Improvements

- Validation-first connection-string checks with clearer errors.
- Better handling of colons in passwords and equals signs in query values.
- Improved tokenization for quoted values in key/value format strings.

---

# rpgconn 0.3.2

- Added config path override support in `dbc()` and internal loaders.
- Updated Roxygen metadata and docs.

# rpgconn 0.3.1

- Previous release.

# rpgconn 0.3.0

- Previous release.
