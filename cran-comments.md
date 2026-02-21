## R CMD check results

0 errors | 0 warnings | 1 note

- NOTE: `unable to verify current time`
  - Environment/network artifact from running checks in a restricted sandbox.

## Release notes

This release focuses on hardening and maintainer onboarding:

- Hardened connection parsing and validation for malformed URI and key/value inputs.
- Redacted credentials in invalid connection-string diagnostics.
- Removed YAML expression evaluation (`eval.expr = FALSE`) for safer config loading.
- Added backward-compatible (deprecated) support for `dbc(path = ...)`.
- Reworked tests to be hermetic and isolated from user config directories.
- Added optional local PostgreSQL end-to-end test with disposable temp tables.
- Expanded maintainer documentation (`README.md`, `DEVELOPMENT.md`, `RELEASE.md`, `AGENTS.md`).
- Added Quarto maintainer/release vignettes and updated pkgdown article navigation.
