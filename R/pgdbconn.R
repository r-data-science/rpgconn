#' Parse PostgreSQL Connection String
#'
#' @param conn_str A PostgreSQL connection string in various formats
#'
#' @return A named list of connection parameters
#' @noRd
parse_conn_string <- function(conn_str) {
  conn_str <- trimws(conn_str)
  
  # Check if it's a URI format (postgresql:// or postgres://)
  if (grepl("^postgres(ql)?://", conn_str, ignore.case = TRUE)) {
    return(parse_uri_conn_string(conn_str))
  }
  
  # Otherwise, parse as keyword/value format
  return(parse_kv_conn_string(conn_str))
}

#' Parse URI-style PostgreSQL Connection String
#'
#' @param uri_str A PostgreSQL URI connection string
#'
#' @return A named list of connection parameters
#' @noRd
parse_uri_conn_string <- function(uri_str) {
  c_args <- list()
  
  # Extract query parameters if present
  query_params <- NULL
  if (grepl("\\?", uri_str)) {
    parts <- strsplit(uri_str, "\\?", fixed = FALSE)[[1]]
    uri_str <- parts[1]
    if (length(parts) > 1) {
      query_params <- parts[2]
    }
  }
  
  # Remove the scheme (postgresql:// or postgres://)
  uri_str <- sub("^postgres(ql)?://", "", uri_str, ignore.case = TRUE)
  
  # Extract user:password@host:port/dbname
  # Pattern: [user[:password]@]host[:port]/dbname
  
  # Check for authentication part (user[:password]@)
  if (grepl("@", uri_str)) {
    parts <- strsplit(uri_str, "@", fixed = TRUE)[[1]]
    auth_part <- parts[1]
    host_part <- parts[2]
    
    # Parse authentication
    if (grepl(":", auth_part, fixed = TRUE)) {
      # Split only on the first colon to handle passwords with colons
      colon_pos <- regexpr(":", auth_part, fixed = TRUE)[1]
      c_args$user <- utils::URLdecode(substr(auth_part, 1, colon_pos - 1))
      c_args$password <- utils::URLdecode(substr(auth_part, colon_pos + 1, nchar(auth_part)))
    } else {
      c_args$user <- utils::URLdecode(auth_part)
    }
  } else {
    host_part <- uri_str
  }
  
  # Parse host:port/dbname
  if (grepl("/", host_part, fixed = TRUE)) {
    parts <- strsplit(host_part, "/", fixed = TRUE)[[1]]
    host_port <- parts[1]
    c_args$dbname <- utils::URLdecode(parts[2])
    
    # Parse host and port
    if (grepl(":", host_port, fixed = TRUE)) {
      host_port_parts <- strsplit(host_port, ":", fixed = TRUE)[[1]]
      c_args$host <- host_port_parts[1]
      c_args$port <- host_port_parts[2]
    } else {
      c_args$host <- host_port
    }
  } else {
    # No database specified, just host:port
    if (grepl(":", host_part, fixed = TRUE)) {
      host_port_parts <- strsplit(host_part, ":", fixed = TRUE)[[1]]
      c_args$host <- host_port_parts[1]
      c_args$port <- host_port_parts[2]
    } else {
      c_args$host <- host_part
    }
  }
  
  # Parse query parameters
  if (!is.null(query_params)) {
    params <- strsplit(query_params, "&", fixed = TRUE)[[1]]
    for (param in params) {
      if (grepl("=", param, fixed = TRUE)) {
        # Split only on the first equals to handle values with embedded equals
        eq_pos <- regexpr("=", param, fixed = TRUE)[1]
        key <- utils::URLdecode(substr(param, 1, eq_pos - 1))
        value <- utils::URLdecode(substr(param, eq_pos + 1, nchar(param)))
        c_args[[key]] <- value
      }
    }
  }
  
  return(c_args)
}

#' Parse Keyword/Value PostgreSQL Connection String
#'
#' @param kv_str A PostgreSQL keyword/value connection string
#'
#' @return A named list of connection parameters
#' @noRd
parse_kv_conn_string <- function(kv_str) {
  # Support both semicolon and whitespace as delimiters
  # First try semicolon (legacy format)
  if (grepl(";", kv_str)) {
    cs <- stringr::str_split_1(kv_str, ";")
  } else {
    # Split by whitespace, handling quoted values
    # Simple approach: split by whitespace, then handle quotes
    cs <- strsplit(trimws(kv_str), "\\s+")[[1]]
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
      
      # Remove quotes if present
      if (!is.na(value)) {
        value <- gsub("^['\"]|['\"]$", "", value)
        c_args[[key]] <- value
      }
    }
  }
  
  return(c_args)
}

#' Database Connect/Disconnect
#'
#' @param db Database name. Default of NULL will utilize the dbname in the connection string
#' @param args_only If TRUE, only return the connection arguments (Default FALSE will make the connection)
#' @param cn a database connection object
#' @param cfg a connection config name used when loading connection args from internally stored yaml
#' @param cfg_path optional path to override default db config file.
#' @param opt_path optional path to override default db options file.
#'
#' @importFrom RPostgres Postgres
#' @importFrom DBI dbConnect dbDisconnect
#' @importFrom stringr str_extract str_split_1
#' @importFrom usethis edit_file
#' @importFrom fs path_package dir_create path file_exists file_copy
#' @importFrom yaml yaml.load_file
#'
#' @return \code{dbc} returns a database connection object or a list of connection arguments while \code{dbd} returns nothing
#'
#' @examples
#' # cn <- dbc("mydb") # Connect
#' # dbd(cn)           # Disconnect
#' @name pgdbconn
NULL

#' @describeIn pgdbconn Connect to a database or return the connection arguments
#' @export
dbc <- function(cfg = NULL, db = NULL, args_only = FALSE, cfg_path = NULL, opt_path = NULL) {
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
#' @export
dbd <- function(cn) {
  message("\n|------- Closing Connection -------|")
  DBI::dbDisconnect(cn)
}


#' @describeIn pgdbconn Initialize connection files
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
#' @export
dir_rpg <- function() {
  # Use a user-specific configuration directory compliant with CRAN policies
  # tools::R_user_dir creates a directory unique to this package in a standard
  # per-user location. See ?tools::R_user_dir for details.
  tools::R_user_dir("rpgconn", which = "config")
}

#' @describeIn pgdbconn edit the internally configured connection parameters
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
