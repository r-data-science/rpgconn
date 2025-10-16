# AGENTS.md

## Repository: rpgconn

### Overview
User-friendly PostgreSQL connection management package for R. Provides helper functions to create, edit, and load connection configuration files.

### Key Features
- YAML-based connection configuration
- Support for RPostgres and ODBC backends
- Environment variable integration (RPG_CONN_STRING)
- Optional path parameter for config file override

### Development Standards
- R (>= 4.1.0)
- Use explicit package::function() syntax
- Test with testthat (>= 3.0.0)
- Document with roxygen2

### Common Commands
```r
# Development
devtools::load_all()
devtools::test()
devtools::check()
devtools::document()

# Usage
dbc(cfg = "myconfig")  # Connect using stored config
dbc(cfg = "myconfig", path = "custom/path.yml")  # Override config path
```

### Testing
- Unit tests in tests/testthat/
- Coverage target: 80%+
- Mock external database connections

### Documentation
- Roxygen2 for function documentation
- NEWS.md for release notes
- Examples in @examples sections
