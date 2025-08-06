#' Connect to a PostgreSQL database or return connection arguments
#'
#' Create a connection to a PostgreSQL database using configuration settings loaded
#' from environment variables or YAML files. When `args_only` is `TRUE`, the function
#' returns a list of connection arguments instead of establishing the connection.
#'
#' @param cfg A connection configuration name used when loading connection arguments
#'   from internally stored YAML files. If `NULL` (the default), connection
#'   arguments are read from the environment variable `RPG_CONN_STRING`.
#' @param db Database name. If `NULL`, the `dbname` value from the connection string
#'   is used.
#' @param args_only Logical. If `TRUE`, return only the connection arguments. If
#'   `FALSE` (default), make the connection and return the resulting connection object.
#'
#' @importFrom RPostgres Postgres
#' @importFrom DBI dbConnect dbDisconnect
#' @importFrom stringr str_extract str_split_1
#' @importFrom usethis edit_file
#' @importFrom fs path_package dir_create path file_exists file_copy
#' @importFrom yaml yaml.load_file
#'
#' @return If `args_only = FALSE`, a database connection object created by
#'   `DBI::dbConnect()`. If `args_only = TRUE`, a named list of connection arguments.
#'
#' @examples
#' # Connect to a database using a configuration stored in ~/.config/rpgconn/config.yml:
#' # cn <- dbc(cfg = "local", db = "mydb")
#' # Disconnect from the database:
#' # dbd(cn)
#' @export


dbc <- function(cfg = NULL, db = NULL, args_only = FALSE) {
  # if cfg is null, use envvar
  if (is.null(cfg)) {
    message("\n[---- Checking RPG_CONN_STRING ----]")
    c_envvar <- Sys.getenv("RPG_CONN_STRING", "") # Envvar must be set
    if (c_envvar == "") {
      stop("RPG_CONN_STRING not set", call. = FALSE)
    }

    # parse connection string
    cs <- stringr::str_split_1(c_envvar, ";")
    c_args <- stats::setNames(
      as.list(stringr::str_extract(cs, "(?<=\\=).+")),
      stringr::str_extract(cs, ".+(?=\\=)")
    )
    # db optional if using envvar bc it could be specified in the string
    if (!is.null(db)) c_args$dbname <- db
  } else {
    # Get args from yaml
    configs <- load_c_args()
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
  tryCatch(
    {
      ck_names <- c("host", "port", "dbname", "user", "password")
      stopifnot(all(names(c_args) %in% ck_names))
      stopifnot(all(sapply(c_args, nchar) > 0))
      stopifnot(length(c_args) < 6)
    },
    error = function(c) {
      if (is.null(cfg)) {
        message("RPG_CONN_STRING is invalid")
        message("\nExpecting of the form: ")
        message("\tuser=...;password=...;host=...;port=...;dbname=...")
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
  c_args <- c(c_args, load_c_opts())

  # Return args only if requested
  if (args_only) {
    return(c_args)
  }

  # make connection and return
  message("\n<-------- Making Connection ------->")
  do.call(DBI::dbConnect, c_args)
}

#' Disconnect from a PostgreSQL database
#'
#' Close a database connection created by `dbc()`.
#'
#' @param cn A database connection object created by `dbc()`.
#' @return Invisibly returns `NULL`.
#' @export
dbd <- function(cn) {
  message("\n|------- Closing Connection -------|")
  DBI::dbDisconnect(cn)
}


#' Initialize configuration files
#'
#' Ensures that the default connection (`config.yml`) and options (`options.yml`) templates
#' exist in the user-specific configuration directory. If they do not exist, they are copied
#' from the package's `extdata` directory. Use `edit_config()` and `edit_options()` to modify them.
#'
#' @return Invisibly returns the path to the configuration directory.
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


#' Get the path to the rpgconn configuration directory
#'
#' Returns the directory path used by rpgconn for storing configuration files.
#'
#' @return A character string giving the path to the configuration directory.
#' @export
dir_rpg <- function() {
  # Use a user-specific configuration directory compliant with CRAN policies
  # tools::R_user_dir creates a directory unique to this package in a standard
  # per-user location. See ?tools::R_user_dir for details.
  tools::R_user_dir("rpgconn", which = "config")
}

#' Edit the connection configuration file
#'
#' In an interactive session, opens the YAML configuration file for editing using the user's
#' preferred editor. In non-interactive contexts (e.g. during automated checks), the file
#' path is returned invisibly without opening the editor.
#'
#' @return Invisibly returns the path to the configuration file.
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

#' Edit the options configuration file
#'
#' In an interactive session, opens the YAML options file for editing using the user's
#' preferred editor. In non-interactive contexts, the file path is returned invisibly
#' without opening the editor.
#'
#' @return Invisibly returns the path to the options file.
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

#' Internal function to read connection arguments from yaml
#' @noRd
load_c_args <- function() {
  path <- xpath_config()
  if (!fs::file_exists(path)) {
    init_yamls()
  }
  yaml::yaml.load_file(path, eval.expr = TRUE)$config
}

#' Internal function to read connection options from yaml
#' @noRd
load_c_opts <- function() {
  path <- xpath_options()
  if (!fs::file_exists(path)) {
    init_yamls()
  }
  yaml::yaml.load_file(path)$options
}

#' Internal function to get path of config file
#' @noRd
xpath_config <- function() {
  fs::path(dir_rpg(), "config.yml")
}

#' Internal function to get path of options file
#' @noRd
xpath_options <- function() {
  fs::path(dir_rpg(), "options.yml")
}


#' Internal function to get path of config file template
#' @noRd
xpath_config_templ <- function() {
  fs::path_package("rpgconn", "extdata", "config.yml")
}

#' Internal function to get path of options file template
#' @noRd
xpath_options_templ <- function() {
  fs::path_package("rpgconn", "extdata", "options.yml")
}
