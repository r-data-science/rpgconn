#' Validate and Normalize PostgreSQL Connection String
#'
#' Validates connection string format and normalizes scheme to postgresql://.
#' This function catches configuration errors early with clear messages,
#' preventing vague "could not connect" errors deep in DBI.
#'
#' @param ctxt Character scalar, raw connection string.
#'
#' @return Invisibly returns normalized connection string with:
#'   - Scheme normalized to "postgresql://"
#'   - Whitespace trimmed
#'   - Basic structural validation passed
#'
#' @noRd
#' @keywords internal
.validate_conn_str <- function(ctxt) {
  if (!is.character(ctxt) || length(ctxt) != 1L) {
    stop("Connection string must be a single character value.", call. = FALSE)
  }

  x <- trimws(ctxt)
  if (!nzchar(x)) {
    stop(
      "Connection string is empty; check RPG_CONN_STRING or function input.",
      call. = FALSE
    )
  }

  # We restrict to postgres/postgresql URIs so that the parser can remain
  # straightforward and so that misconfigured Oracle/MySQL strings fail
  # loudly instead of being misinterpreted.
  if (!grepl("^postgres(ql)?://", x, ignore.case = TRUE)) {
    stop(
      "Connection string must start with 'postgres://' or 'postgresql://'. ",
      "Got: '", substr(x, 1L, min(32L, nchar(x))), "...'",
      call. = FALSE
    )
  }

  # We normalize to a single scheme to avoid carrying conditional logic
  # everywhere else in the code.
  x <- sub("^postgres(ql)?://", "postgresql://", x, ignore.case = TRUE)

  # Whitespace tends to signal copy/paste issues (line breaks, trailing spaces),
  # so we reject it early to avoid surprising parsing behavior.
  if (grepl("[[:space:]]", x)) {
    stop("Connection string must not contain whitespace.", call. = FALSE)
  }

  # Strip off scheme for structural checks.
  rest <- sub("^postgresql://", "", x)

  # We require at least one "/" so that a database name is always present.
  if (!grepl("/", rest, fixed = TRUE)) {
    stop(
      "Connection string must include a '/{database}' segment, e.g. ",
      "'postgresql://user@host:5432/dbname'.",
      call. = FALSE
    )
  }

  parts <- strsplit(rest, "/", fixed = TRUE)[[1]]
  if (length(parts) < 2L || !nzchar(parts[2L])) {
    stop("Database name appears to be missing in connection string.", call. = FALSE)
  }

  authority <- parts[1L]
  if (!nzchar(authority)) {
    stop("Host/user information appears to be missing in connection string.", call. = FALSE)
  }

  # Here we only ensure that the host portion isn't empty; we don't
  # over-validate hostnames or ports so that future deployment variations
  # (e.g., unix sockets, service names) remain possible without changing
  # this function.
  if (grepl("@", authority, fixed = TRUE)) {
    hostport <- sub("^.*@", "", authority)
    userinfo <- sub("@.*$", "", authority)
    if (!nzchar(userinfo)) {
      stop("User information before '@' is empty in connection string.", call. = FALSE)
    }
  } else {
    hostport <- authority
  }

  if (!nzchar(hostport)) {
    stop("Host portion after '@' is empty in connection string.", call. = FALSE)
  }

  invisible(x)
}


#' Parse PostgreSQL Connection String
#'
#' Parses a validated PostgreSQL URI into DBI-ready connection arguments.
#' Handles URI format with query parameters and URL encoding.
#'
#' @param ctxt Character scalar; PostgreSQL connection string. Defaults to
#'   Sys.getenv("RPG_CONN_STRING").
#'
#' @return Named list suitable for passing into DBI::dbConnect(), e.g.:
#'   list(dbname = ..., host = ..., port = ..., user = ..., password = ..., sslmode = ...)
#'
#' @noRd
#' @keywords internal
parse_conn_str <- function(ctxt = Sys.getenv("RPG_CONN_STRING")) {
  # We validate immediately so that any misconfiguration is surfaced as a clear,
  # early error rather than as a vague "could not connect" further downstream.
  std <- .validate_conn_str(ctxt)

  # At this point we assume std starts with "postgresql://", so we can ignore
  # historical variations and keep parsing logic simple and predictable.
  x <- std
  x_no_scheme <- sub("^postgresql://", "", x)

  # Separate the query component so URL parameters can be mapped to DBI args.
  # This keeps the core connection info (host/user/db) and optional parameters
  # conceptually distinct.
  parts <- strsplit(x_no_scheme, "\\?", fixed = FALSE)[[1]]
  main_part <- parts[1L]
  query_raw <- if (length(parts) > 1L) paste(parts[-1L], collapse = "?") else ""

  # The first "/" separates the authority (userinfo@host:port) from the db name.
  slash_pos <- regexpr("/", main_part, fixed = TRUE)
  if (slash_pos < 0) {
    stop("Internal parsing error: expected '/' separating host and database name.", call. = FALSE)
  }

  authority <- substr(main_part, 1L, slash_pos - 1L)
  path <- substr(main_part, slash_pos + 1L, nchar(main_part))

  # Using the entire path as dbname avoids surprising behavior when people
  # (rarely) include slashes in database names; we simply pass through what
  # they specified.
  dbname <- utils::URLdecode(path)

  user <- password <- host <- NULL
  port <- NA_integer_

  # We split userinfo from hostport only if '@' exists; this lets us support
  # passwordless URIs and future auth mechanisms without over-constraining.
  if (grepl("@", authority, fixed = TRUE)) {
    userinfo <- sub("@.*$", "", authority)
    hostport <- sub("^.*@", "", authority)

    # We only treat the first ":" in userinfo as the user/password separator.
    # This avoids rejecting passwords that contain ":" while staying simple.
    up <- strsplit(userinfo, ":", fixed = TRUE)[[1]]
    if (length(up) >= 1L && nzchar(up[1L])) {
      user <- utils::URLdecode(up[1L])
    }
    if (length(up) >= 2L) {
      # We re-join remaining pieces so passwords with ":" continue to work.
      password <- utils::URLdecode(paste(up[-1L], collapse = ":"))
    }
  } else {
    hostport <- authority
  }

  # We treat IPv6 separately so we don't misinterpret "host:port" semantics.
  # This makes the parser robust on modern networks without complicating the
  # common IPv4/hostname path.
  hp <- hostport
  if (startsWith(hp, "[")) {
    end_bracket <- regexpr("]", hp, fixed = TRUE)
    if (end_bracket < 0) {
      stop("Invalid IPv6 host in connection string (missing closing ']').", call. = FALSE)
    }
    host <- substr(hp, 2L, end_bracket - 1L)
    rest <- substr(hp, end_bracket + 1L, nchar(hp))
    if (nzchar(rest)) {
      if (substr(rest, 1L, 1L) != ":") {
        stop("Unexpected characters after IPv6 host; expected optional ':port'.", call. = FALSE)
      }
      port_str <- substr(rest, 2L, nchar(rest))
      if (nzchar(port_str)) {
        port <- suppressWarnings(as.integer(port_str))
        if (is.na(port)) {
          stop("Port in connection string is not a valid integer.", call. = FALSE)
        }
      }
    }
  } else {
    # For non-IPv6 hosts, we assume the final ":" separates host and port,
    # which is consistent with typical "host:port" patterns and avoids
    # surprising results when hostnames contain ":" rarely or never.
    hp_parts <- strsplit(hp, ":", fixed = TRUE)[[1]]
    if (length(hp_parts) == 1L) {
      host <- hp_parts[1L]
    } else {
      port_str <- hp_parts[length(hp_parts)]
      host <- paste(hp_parts[-length(hp_parts)], collapse = ":")
      if (nzchar(port_str)) {
        port <- suppressWarnings(as.integer(port_str))
        if (is.na(port)) {
          stop("Port in connection string is not a valid integer.", call. = FALSE)
        }
      }
    }
  }

  # Query parameters allow enforcing things like sslmode at the caller level
  # while keeping the URI concise. We preserve them as-is so DBI/RPostgres can
  # make the final decision on which ones it understands.
  params <- list()
  if (nzchar(query_raw)) {
    q_parts <- unlist(strsplit(query_raw, "&", fixed = TRUE), use.names = FALSE)
    for (kv in q_parts) {
      if (!nzchar(kv)) next
      kv_split <- strsplit(kv, "=", fixed = TRUE)[[1]]
      key <- utils::URLdecode(kv_split[1L])
      val <- if (length(kv_split) >= 2L) {
        utils::URLdecode(paste(kv_split[-1L], collapse = "="))
      } else {
        ""
      }
      if (!nzchar(key)) next
      params[[key]] <- val
    }
  }

  # We build a minimal core argument list first so that the essentials
  # remain obvious. Then we layer query parameters on top, allowing them
  # to override core fields intentionally if the caller chooses to do so.
  res <- list()
  if (!is.null(dbname) && nzchar(dbname)) res$dbname <- dbname
  if (!is.null(host) && nzchar(host))   res$host   <- host
  if (!is.na(port))                     res$port   <- as.character(port)
  if (!is.null(user) && nzchar(user))   res$user   <- user
  if (!is.null(password) && nzchar(password)) res$password <- password

  for (nm in names(params)) {
    res[[nm]] <- params[[nm]]
  }

  res
}


#' Parse Keyword/Value PostgreSQL Connection String
#'
#' Parses libpq-style keyword/value connection strings.
#' Supports both semicolon-delimited (legacy) and whitespace-delimited formats.
#' Properly handles quoted values containing spaces.
#'
#' @param kv_str A PostgreSQL keyword/value connection string
#'
#' @return A named list of connection parameters
#' @noRd
#' @keywords internal
parse_kv_conn_string <- function(kv_str) {
  # Support both semicolon and whitespace as delimiters.
  # Semicolon is our legacy format; whitespace matches libpq standard.
  if (grepl(";", kv_str)) {
    cs <- stringr::str_split_1(kv_str, ";")
  } else {
    # For whitespace-delimited format, we need to handle quoted values specially
    # because they can contain spaces. We use a simple tokenizer that respects quotes.
    cs <- tokenize_kv_string(kv_str)
  }

  # Parse key=value pairs
  c_args <- list()
  for (pair in cs) {
    pair <- trimws(pair)
    if (nchar(pair) == 0) next

    if (grepl("=", pair)) {
      # Extract key and value
      key <- stringr::str_extract(pair, ".+(?=\\=)")
      value <- stringr::str_extract(pair, "(?<=\\=).+")

      # Remove quotes if present (for whitespace-delimited format with quoted values)
      if (!is.na(value)) {
        value <- gsub("^['\"]|['\"]$", "", value)
        c_args[[key]] <- value
      }
    }
  }

  c_args
}


#' Tokenize Keyword/Value String Respecting Quotes
#'
#' Simple tokenizer that splits by whitespace but keeps quoted strings together.
#' Handles both single and double quotes.
#'
#' @param str String to tokenize
#'
#' @return Character vector of tokens
#' @noRd
#' @keywords internal
tokenize_kv_string <- function(str) {
  str <- trimws(str)
  tokens <- character(0)
  current_token <- ""
  in_quote <- FALSE
  quote_char <- ""

  chars <- strsplit(str, "")[[1]]
  i <- 1

  while (i <= length(chars)) {
    char <- chars[i]

    if (!in_quote && (char == "'" || char == "\"")) {
      # Start of quoted section
      in_quote <- TRUE
      quote_char <- char
      current_token <- paste0(current_token, char)
    } else if (in_quote && char == quote_char) {
      # End of quoted section
      in_quote <- FALSE
      current_token <- paste0(current_token, char)
      quote_char <- ""
    } else if (!in_quote && char == " ") {
      # Whitespace outside quotes - end current token
      if (nchar(current_token) > 0) {
        tokens <- c(tokens, current_token)
        current_token <- ""
      }
    } else {
      # Regular character - add to current token
      current_token <- paste0(current_token, char)
    }

    i <- i + 1
  }

  # Don't forget the last token
  if (nchar(current_token) > 0) {
    tokens <- c(tokens, current_token)
  }

  tokens
}


#' Parse PostgreSQL Connection String (Dispatcher)
#'
#' Detects format and dispatches to appropriate parser.
#' Supports URI format and keyword/value format.
#'
#' @param conn_str A PostgreSQL connection string in various formats
#'
#' @return A named list of connection parameters
#' @noRd
#' @keywords internal
parse_conn_string <- function(conn_str) {
  conn_str <- trimws(conn_str)

  # Check if it's a URI format (postgresql:// or postgres://)
  if (grepl("^postgres(ql)?://", conn_str, ignore.case = TRUE)) {
    return(parse_conn_str(conn_str))
  }

  # Otherwise, parse as keyword/value format
  parse_kv_conn_string(conn_str)
}

#' PostgreSQL Database Connection Management
#'
#' Simplified interface for connecting to PostgreSQL databases using either
#' environment variables, URI connection strings, or YAML configuration files.
#'
#' @param cfg A connection configuration name used when loading connection arguments
#'   from internally stored YAML files. If `NULL` (the default), connection
#'   arguments are read from the environment variable `RPG_CONN_STRING`.
#' @param db Database name. If `NULL`, the `dbname` value from the connection string
#'   or configuration is used. Required when using `cfg` parameter.
#' @param args_only Logical. If `TRUE`, return only the connection arguments without
#'   establishing a connection. If `FALSE` (default), establish and return the connection.
#' @param cfg_path Optional path to override default database config file location.
#'   Useful for testing or project-specific configurations.
#' @param opt_path Optional path to override default database options file location.
#' @param cn A database connection object to disconnect.
#'
#' @importFrom RPostgres Postgres
#' @importFrom DBI dbConnect dbDisconnect
#' @importFrom stringr str_extract str_split_1
#' @importFrom usethis edit_file
#' @importFrom fs path_package dir_create path file_exists file_copy
#' @importFrom yaml yaml.load_file
#'
#' @return
#' - `dbc()`: A database connection object (class `PqConnection`) when `args_only = FALSE`,
#'   or a named list of connection arguments when `args_only = TRUE`.
#' - `dbd()`: `NULL`, invisibly. Called for side effect of closing connection.
#' - `init_yamls()`: Path to rpgconn config directory, invisibly.
#' - `dir_rpg()`: Character string path to rpgconn config directory.
#' - `edit_config()`: Path to config file, invisibly.
#' - `edit_options()`: Path to options file, invisibly.
#'
#' @family database-connection
#' @family configuration
#' @keywords database
#' @keywords connection
#' @concept postgresql
#' @concept database-config
#'
#' @seealso
#' - [RPostgres::Postgres()] for the underlying PostgreSQL driver
#' - [DBI::dbConnect()] for lower-level connection details
#' - [use_config()] for adopting external configuration files
#'
#' @details
#' ## Why rpgconn?
#'
#' Managing PostgreSQL connections across environments (local, staging, production)
#' is error-prone and insecure. rpgconn eliminates this friction by:
#'
#' - **Portable**: Uses standard PostgreSQL URI format that works across languages and tools
#' - **Secure**: Stores configurations locally in user directories, never in version control
#' - **Flexible**: Supports URI format, keyword/value format, and YAML configs
#' - **Fail-fast**: Validates connection strings upfront with clear error messages
#' - **Zero friction**: Single function call replaces repetitive `DBI::dbConnect()` boilerplate
#'
#' ## Connection Methods
#'
#' ### Method 1: Environment Variable (Recommended for Cloud)
#'
#' Set `RPG_CONN_STRING` to a PostgreSQL URI:
#'
#' ```r
#' Sys.setenv(RPG_CONN_STRING = "postgresql://user:pass@host:5432/db")
#' cn <- dbc()
#' ```
#'
#' Supports query parameters for SSL and other options:
#'
#' ```r
#' Sys.setenv(RPG_CONN_STRING = "postgresql://user:pass@host/db?sslmode=require")
#' ```
#'
#' ### Method 2: YAML Configuration (Recommended for Teams)
#'
#' Initialize and edit config files:
#'
#' ```r
#' init_yamls()
#' edit_config()  # Opens ~/.config/rpgconn/config.yml
#' ```
#'
#' Then connect using named configurations:
#'
#' ```r
#' cn <- dbc(cfg = "local", db = "mydb")
#' ```
#'
#' ## Connection String Formats
#'
#' The package supports multiple PostgreSQL connection string formats:
#'
#' - **URI**: `postgresql://user:pass@host:5432/db?sslmode=require`
#' - **Keyword/value (semicolon)**: `user=...;password=...;host=...;port=...;dbname=...`
#' - **Keyword/value (whitespace)**: `host=... user=... dbname=... port=...`
#'
#' See `vignette("advanced-workflow")` for comprehensive format documentation.
#'
#' @examples
#' \dontrun{
#' # Method 1: Using connection string (cloud databases)
#' Sys.setenv(RPG_CONN_STRING = "postgresql://user:pass@localhost:5432/mydb")
#' cn <- dbc()
#' DBI::dbGetQuery(cn, "SELECT version()")
#' dbd(cn)
#'
#' # Method 2: Using YAML config (team/local setups)
#' init_yamls()
#' edit_config()  # Edit ~/.config/rpgconn/config.yml
#' cn <- dbc(cfg = "local", db = "mydb")
#' dbd(cn)
#'
#' # Get connection args without connecting (useful for debugging)
#' args <- dbc(args_only = TRUE)
#' str(args)
#'
#' # Use custom config file (testing, project-specific)
#' cn <- dbc(cfg = "test", db = "testdb", cfg_path = "tests/fixtures/config.yml")
#' dbd(cn)
#' }
#' @name pgdbconn
NULL

#' @describeIn pgdbconn Connect to a database or return the connection arguments
#' @concept database-connection
#' @concept postgresql
#' @export
dbc <- function(cfg = NULL, db = NULL, args_only = FALSE,
                cfg_path = NULL, opt_path = NULL) {
  # if cfg is null, use envvar
  if (is.null(cfg)) {
    message("\n[---- Checking RPG_CONN_STRING ----]")
    c_envvar <- Sys.getenv("RPG_CONN_STRING", "") # Envvar must be set
    if (c_envvar == "") {
      stop("RPG_CONN_STRING not set", call. = FALSE)
    }

    # parse connection string using new robust parser
    c_args <- parse_conn_string(c_envvar)
    
    # db optional if using envvar bc it could be specified in the string
    if (!is.null(db)) c_args$dbname <- db
  } else {
    # Get args from yaml
    configs <- load_c_args(cfg_path)
    if (!cfg %in% names(configs)) {
      stop("Connection config not found", call. = FALSE)
    }
    c_args <- configs[[cfg]]

    if (is.null(db)) {
      stop("Database name must be specified when using arg cfg", call. = FALSE)
    }
    c_args$dbname <- db
  }

  # Check connection args
  # Allow additional parameters beyond the core five for URI query params
  tryCatch(
    {
      ck_names <- c("host", "port", "dbname", "user", "password", 
                    "sslmode", "connect_timeout", "application_name", 
                    "options", "target_session_attrs")
      # Only check that recognized names are used and have non-empty values
      unknown_params <- setdiff(names(c_args), ck_names)
      if (length(unknown_params) > 0) {
        warning("Unknown connection parameters: ", paste(unknown_params, collapse = ", "))
      }
      stopifnot(all(sapply(c_args, nchar) > 0))
    },
    error = function(c) {
      if (is.null(cfg)) {
        message("RPG_CONN_STRING is invalid")
        message("\nExpecting one of the following formats: ")
        message("\tURI: postgresql://user:pass@host:5432/dbname")
        message("\tURI with params: postgresql://user@host/db?sslmode=require")
        message("\tKeyword/value (semicolon): user=...;password=...;host=...;port=...;dbname=...")
        message("\tKeyword/value (whitespace): host=... user=... dbname=...")
        message("\nCurrent value set to: ")
        message("\t", Sys.getenv("RPG_CONN_STRING"), "\n")
      } else {
        message("cfg specified is invalid")
        message("\nCheck config yaml file for correct format")
        message("\tcall edit_config() to view/edit")
      }
      stop("Unable to make connection", call. = FALSE)
    }
  )

  # Add driver
  c_args$drv <- RPostgres::Postgres()

  # Add options
  c_args <- c(c_args, load_c_opts(opt_path))

  # Return args only if requested
  if (args_only) {
    return(c_args)
  }

  # make connection and return
  message("\n<-------- Making Connection ------->")
  do.call(DBI::dbConnect, c_args)
}

#' @describeIn pgdbconn Disconnect from a database
#' @concept database-connection
#' @concept postgresql
#' @export
dbd <- function(cn) {
  message("\n|------- Closing Connection -------|")
  DBI::dbDisconnect(cn)
}


#' @describeIn pgdbconn Initialize connection files
#' @concept configuration
#' @concept config-management
#' @export
init_yamls <- function() {
  dir_rpg <- fs::dir_create(dir_rpg())
  if (!fs::file_exists(xpath_config())) {
    fs::file_copy(xpath_config_templ(), xpath_config())
  }
  if (!fs::file_exists(xpath_options())) {
    fs::file_copy(xpath_options_templ(), xpath_options())
  }
  message(
    "rpgconn: configs created",
    "\n...Update connection configs: edit_config()",
    "\n...Update connection options: edit_options()"
  )
  invisible(dir_rpg)
}


#' @describeIn pgdbconn get the path to the rpg settings directory
#' @concept configuration
#' @concept config-management
#' @export
dir_rpg <- function() {
  # Use a user-specific configuration directory compliant with CRAN policies
  # tools::R_user_dir creates a directory unique to this package in a standard
  # per-user location. See ?tools::R_user_dir for details.
  tools::R_user_dir("rpgconn", which = "config")
}

#' @describeIn pgdbconn edit the internally configured connection parameters
#' @concept configuration
#' @concept config-management
#' @export
edit_config <- function() {
  f <- xpath_config()
  if (interactive()) {
    # Only launch the editor in interactive sessions (e.g. at the console).
    usethis::edit_file(f)
  } else {
    message("edit_config() called in non-interactive mode; returning file path without opening an editor.")
  }
  invisible(f)
}

#' @describeIn pgdbconn edit the internally configured connection options
#' @concept configuration
#' @concept config-management
#' @export
edit_options <- function() {
  f <- xpath_options()
  if (interactive()) {
    # Only launch the editor in interactive sessions (e.g. at the console).
    usethis::edit_file(f)
  } else {
    message("edit_options() called in non-interactive mode; returning file path without opening an editor.")
  }
  invisible(f)
}

#' @describeIn pgdbconn internal function to read conn args from yaml
#' @noRd
load_c_args <- function(cfg_path = NULL) {
  if (is.null(cfg_path)) {
    cfg_path <- xpath_config()
  }
  if (!fs::file_exists(cfg_path)) {
    init_yamls()
  }
  yaml::yaml.load_file(cfg_path, eval.expr = TRUE)$config
}

#' @describeIn pgdbconn internal function to read conn options from yaml
#' @noRd
load_c_opts <- function(opt_path = NULL) {
  if (is.null(opt_path)) {
    opt_path <- xpath_options()
  }
  if (!fs::file_exists(opt_path)) {
    init_yamls()
  }
  yaml::yaml.load_file(opt_path)$options
}

#' @describeIn pgdbconn internal function to get path of config file
#' @noRd
xpath_config <- function() {
  fs::path(dir_rpg(), "config.yml")
}

#' @describeIn pgdbconn internal function to get path of options file
#' @noRd
xpath_options <- function() {
  fs::path(dir_rpg(), "options.yml")
}


#' @describeIn pgdbconn internal function to get path of config file template
#' @noRd
xpath_config_templ <- function() {
  fs::path_package("rpgconn", "extdata", "config.yml")
}

#' @describeIn pgdbconn internal function to get path of options file template
#' @noRd
xpath_options_templ <- function() {
  fs::path_package("rpgconn", "extdata", "options.yml")
}
