# rpgconn <img src="man/figures/logo.png" align="right" height="120" alt="" />

<!-- badges: start -->
[![Codecov](https://codecov.io/gh/r-data-science/rpgconn/branch/main/graph/badge.svg)](https://app.codecov.io/gh/r-data-science/rpgconn?branch=main)
[![R-CMD-check](https://github.com/r-data-science/rpgconn/actions/workflows/R-CMD-check.yaml/badge.svg?branch=main)](https://github.com/r-data-science/rpgconn/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/r-data-science/rpgconn/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/r-data-science/rpgconn/actions/workflows/test-coverage.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/rpgconn)](https://CRAN.R-project.org/package=rpgconn)
<!-- badges: end -->

## Why rpgconn?

PostgreSQL connection management in R is unnecessarily painful:

- **Credentials scattered everywhere**: Connection strings copy-pasted across dozens of scripts
- **Security nightmares**: Passwords accidentally committed to version control
- **Format hell**: Local dev uses `host=localhost user=...`, cloud uses `postgresql://...`, CI uses something else
- **Cryptic errors**: "Could not connect to server" - but *why*? Wrong port? Missing password? Typo in host?
- **Boilerplate fatigue**: Writing `DBI::dbConnect(Postgres(), host=..., port=..., user=..., password=..., dbname=...)` gets old fast

**rpgconn fixes all of this.** One package, one function, one connection string - everywhere.

## Features

✅ **Portable** - Standard PostgreSQL URI format works across Python, Node.js, Go, command-line tools, and cloud platforms
✅ **Secure** - Credentials stored in user-specific config directories, never in your repo
✅ **Flexible** - Supports URI format, keyword/value format, and YAML configs
✅ **Fail-Fast** - Validates connection strings upfront with clear, actionable error messages
✅ **Zero Friction** - One function call replaces 6+ lines of DBI boilerplate
✅ **CRAN-Ready** - Stable, tested, maintained, with comprehensive documentation

## Installation

```r
# From CRAN
install.packages("rpgconn")

# Development version from GitHub
# install.packages("pak")
pak::pkg_install("r-data-science/rpgconn")
```

## Quick Start

### Method 1: Connection String (Cloud Databases)

```r
library(rpgconn)

# Set your database connection string (from DigitalOcean, AWS RDS, etc.)
Sys.setenv(RPG_CONN_STRING = "postgresql://user:pass@db.example.com:5432/mydb?sslmode=require")

# Connect in one line
cn <- dbc()

# Use standard DBI functions
DBI::dbGetQuery(cn, "SELECT * FROM users LIMIT 10")

# Disconnect
dbd(cn)
```

### Method 2: YAML Configuration (Teams & Local Dev)

```r
library(rpgconn)

# Initialize config files in ~/.config/rpgconn/
init_yamls()

# Edit config (opens in your default editor)
edit_config()
```

Edit `config.yml`:
```yaml
config:
  dev:
    host: localhost
    port: 5432
    user: myapp_user
    password: dev_password

  prod:
    host: prod-db.example.com
    port: 5432
    user: app_prod
    password: secret
```

Connect using named configs:
```r
# Development database
cn <- dbc(cfg = "dev", db = "myapp_dev")
dbd(cn)

# Production database
cn <- dbc(cfg = "prod", db = "myapp_prod")
dbd(cn)
```

## Supported Connection String Formats

rpgconn supports all standard PostgreSQL connection formats:

### URI Format (Recommended)

```r
# Basic
"postgresql://user:password@host:5432/database"

# With SSL
"postgresql://user:pass@host/db?sslmode=require"

# IPv6 host
"postgresql://user:pass@[2001:db8::1]:5432/db"

# Multiple parameters
"postgresql://user@host/db?sslmode=require&connect_timeout=30&application_name=MyApp"
```

Both `postgresql://` and `postgres://` prefixes are supported.

### Keyword/Value Formats

```r
# Semicolon-delimited (legacy)
"user=alice;password=secret;host=localhost;port=5432;dbname=mydb"

# Whitespace-delimited (libpq standard)
"host=localhost port=5432 user=alice dbname=mydb"

# With quoted values (for spaces)
"host='my host' user=alice dbname='my database' port=5432"
```

## Comparison: Before vs After

### Without rpgconn
```r
library(DBI)
library(RPostgres)

cn <- dbConnect(
  Postgres(),
  host = "db.example.com",
  port = 5432,
  dbname = "mydb",
  user = "myuser",
  password = "mypassword",
  sslmode = "require"
)

# ... do work ...

dbDisconnect(cn)
```

### With rpgconn
```r
library(rpgconn)

cn <- dbc()  # All config from RPG_CONN_STRING

# ... do work ...

dbd(cn)
```

**Result**: 9 lines → 3 lines. Zero chance of committing credentials. One source of truth.

## Learn More

- 📘 **[Package Overview](https://r-data-science.github.io/rpgconn/articles/rpgconn.html)** - Design philosophy and architecture
- 🚀 **[Quickstart Guide](https://r-data-science.github.io/rpgconn/articles/quickstart.html)** - Get connected in 5 minutes
- 🔧 **[Advanced Workflow](https://r-data-science.github.io/rpgconn/articles/advanced-workflow.html)** - SSL, IPv6, troubleshooting, and more
- 📖 **[Function Reference](https://r-data-science.github.io/rpgconn/reference/index.html)** - Complete API documentation

## Getting Help

- 💬 **Questions?** [Open a discussion](https://github.com/r-data-science/rpgconn/discussions)
- 🐛 **Found a bug?** [Report an issue](https://github.com/r-data-science/rpgconn/issues)
- 💡 **Feature request?** [Share your idea](https://github.com/r-data-science/rpgconn/issues/new)
