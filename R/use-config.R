
#' Use New Config at Path
#'
#' @param path path to new config yaml file to use
#' @param overwrite overwrite existing config yaml set prior. Default FALSE
#'
#' @export
use_config <- function(path, overwrite = FALSE) {

  tmp_path <- tryCatch({

    # write input yaml at path to temp yaml file
    tmp <- tempfile(fileext = ".yaml")
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
  tryCatch({
    fs::file_copy(
      tmp_path,
      xpath_config(),
      overwrite = overwrite
    )
  }, error = function(c) {
    stop(paste0(
      "Failed to overwrite existing config with message: ",
      c$message
    ), call. = FALSE)
  })
}

