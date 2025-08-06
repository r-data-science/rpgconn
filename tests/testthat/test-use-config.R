test_that("multiplication works", {

  ## Move existing config to temp and reset after test
  old_conf <- tempfile(fileext = ".yaml")
  conf_path <- fs::path(dir_rpg(), "config.yml")
  fs::file_copy(conf_path, old_conf)
  on.exit(
    fs::file_copy(old_conf, conf_path, overwrite = TRUE)
  )


  ## Expect Error (already exists and overwrite not TRUE)
  use_config("test_config.yaml") |>
    expect_error()


  ## Remove Existing file and try again
  fs::file_delete(conf_path)

  use_config("test_config.yaml") |>
    expect_no_error()


  ## Now try with overwrite as TRUE
  use_config("test_config.yaml", overwrite = TRUE) |>
    expect_no_error()
})
