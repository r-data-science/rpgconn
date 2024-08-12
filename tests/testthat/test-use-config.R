test_that("multiplication works", {

  ## Move existing config to temp and reset after test
  old_conf <- tempfile(fileext = ".yaml")
  fs::file_copy(xpath_config(), old_conf)
  on.exit(
    fs::file_copy(old_conf, xpath_config(), overwrite = TRUE)
  )


  ## Expect Error (already exists and overwrite not TRUE)
  use_config("test_config.yaml") |>
    expect_error()


  ## Remove Existing file and try again
  fs::file_delete(xpath_config())

  use_config("test_config.yaml") |>
    expect_no_error()


  ## Now try with overwrite as TRUE
  use_config("test_config.yaml", overwrite = TRUE) |>
    expect_no_error()
})
