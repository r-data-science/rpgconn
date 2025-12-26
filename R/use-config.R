#' Adopt External Configuration File
#'
#' Replace rpgconn's active configuration with an external YAML file.
#' This function solves the problem of managing multiple config files across
#' environments without manual file copying.
#'
#' @param path Character string. Path to YAML config file to adopt.
#'   Can be absolute or relative to current working directory.
#' @param overwrite Logical. If `TRUE`, overwrite existing config.
#'   If `FALSE` (default), error if config already exists.
#'
#' @return Invisibly returns the path to the active configuration file
#'   after replacement. In non-interactive sessions, the path is returned
#'   silently without opening an editor.
#'
#' @family configuration
#' @family config-management
#' @keywords database
#' @keywords configuration
#' @concept config-management
#'
#' @seealso
#' - [edit_config()] to edit the active configuration file
#' - [init_yamls()] to initialize default configuration files
#' - [dbc()] to connect using the active configuration
#'
#' @details
#' ## Why use_config()?
#'
#' This function addresses several common pain points:
#'
#' **Problem 1: Team Collaboration**
#' Teams often maintain a shared config in their project repository.
#' Instead of manually copying `team-config.yml` to `~/.config/rpgconn/config.yml`,
#' just call `use_config("team-config.yml")`.
#'
#' **Problem 2: Environment-Specific Configs**
#' Different environments (dev/staging/prod) need different configs.
#' Store each as a separate file and switch between them:
#'
#' ```r
#' use_config("config-dev.yml")    # Use dev database
#' use_config("config-prod.yml", overwrite = TRUE)  # Switch to prod
#' ```
#'
#' **Problem 3: Testing with Fixtures**
#' Tests need isolated, reproducible configurations:
#'
#' ```r
#' use_config("tests/fixtures/mock-config.yml")
#' ```
#'
#' ## How It Works
#'
#' 1. Reads and validates the YAML file at `path`
#' 2. Copies it to `~/.config/rpgconn/config.yml` (or platform equivalent)
#' 3. All subsequent `dbc(cfg = "name")` calls use the new config
#'
#' The function ensures the directory structure exists before copying,
#' making it safe to use even on fresh installations.
#'
#' ## Config File Format
#'
#' Config files should follow this structure:
#'
#' ```yaml
#' config:
#'   local:
#'     host: localhost
#'     port: 5432
#'   prod:
#'     host: prod.example.com
#'     port: 5432
#'     user: app_user
#'     password: secret
#' ```
#'
#' See `vignette("quickstart")` for complete examples.
#'
#' @examples
#' \dontrun{
#' # Adopt project-level config
#' use_config("project_config.yml")
#'
#' # Force overwrite existing config
#' use_config("new_config.yml", overwrite = TRUE)
#'
#' # Use environment-specific config
#' env <- Sys.getenv("APP_ENV", "dev")
#' use_config(paste0("config-", env, ".yml"))
#'
#' # Testing with fixture
#' withr::with_tempfile("temp_config", {
#'   use_config("tests/fixtures/test-config.yml")
#'   cn <- dbc(cfg = "test", db = "testdb")
#'   # ... run tests ...
#'   dbd(cn)
#' })
#' }
#'
#' @concept configuration
#' @concept config-management
#' @export
use_config <- function(path, overwrite = FALSE) {
  tmp_path <- tryCatch(
    {
      # write input yaml at path to temp yaml file
      tmp <- tempfile(fileext = ".yml")
      new_yaml <- yaml::read_yaml(path)
      yaml::write_yaml(new_yaml, file = tmp)
      tmp
    },
    error = function(c) {
      stop(paste0(
        "Failed reading yaml at path: ", path,
        "... with message: ", c$message
      ), call. = FALSE)
    }
  )


  # Replace current config with file at tmp_path
  curr_path <- xpath_config()

  ## In case there actually is no file at the current path,
  ## we need to ensure the directory structure exists
  fs::dir_create(dir_rpg(), recurse = TRUE)

  tryCatch(
    {
      fs::file_copy(
        tmp_path,
        curr_path,
        overwrite = overwrite
      )
    },
    error = function(c) {
      stop(paste0(
        "Failed to overwrite existing config with message: ",
        c$message
      ), call. = FALSE)
    }
  )

  # return the path invisibly so that tests can assert on it without printing
  invisible(curr_path)
}
