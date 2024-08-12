test_that("multiplication works", {

  ## Init
  init_yamls() |> fs::dir_exists() |> expect_true()

  ## Expect Error (already exists and overwrite not TRUE)
  use_config("test_config.yaml") |>
    expect_error()


  ## Remove Existing file and try again
  fs::file_delete(xpath_config())

  use_config("test_config.yaml") |>
    expect_no_error()


  ## Now try with overwrite as TRUE
  use_config("test_config.yaml", overwrite = TRUE)


})
