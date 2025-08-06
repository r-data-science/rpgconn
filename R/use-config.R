
#' Use New Config at Path
#'
#' @param path path to new config yaml file to use
#' @param overwrite overwrite existing config yaml set prior. Default FALSE
#'
#' @return Invisible character vector giving the path to the active configuration
#'   file after it has been replaced.  In non-interactive sessions the file is
#'   silently returned.
#'
#' @export
use_config <- function(path, overwrite = FALSE) {

  tmp_path <- tryCatch({

    # write input yaml at path to temp yaml file
    tmp <- tempfile(fileext = ".yml")
    new_yaml <- yaml::read_yaml(path)
    yaml::write_yaml(new_yaml, file = tmp)
    tmp

  }, error = function(c) {
    stop(paste0(
      "Failed reading yaml at path: ", path,
      "... with message: ", c$message
    ), call. = FALSE)
  })


  # Replace current config with file at tmp_path
  curr_path <- xpath_config()

  ## In case there actually is no file at the current path,
  ## we need to ensure the directory structure exists
  fs::dir_create(dir_rpg(), recurse = TRUE)

  tryCatch({
    fs::file_copy(
      tmp_path,
      curr_path,
      overwrite = overwrite
    )
  }, error = function(c) {
    stop(paste0(
      "Failed to overwrite existing config with message: ",
      c$message
    ), call. = FALSE)
  })

  # return the path invisibly so that tests can assert on it without printing
  invisible(curr_path)
}

