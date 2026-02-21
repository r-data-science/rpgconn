test_that("use_config validates inputs", {
  local_rpg_sandbox()

  expect_error(use_config(1), "`path` must be a single, non-empty character")
  expect_error(use_config("some.yml", overwrite = NA), "`overwrite` must be TRUE or FALSE")
})

test_that("use_config rejects invalid yaml structure", {
  local_rpg_sandbox()

  invalid_cfg <- withr::local_tempfile(fileext = ".yml")
  yaml::write_yaml(list(not_config = list(dev = list(host = "localhost"))), invalid_cfg)

  expect_error(
    use_config(invalid_cfg, overwrite = TRUE),
    "top-level 'config:' mapping"
  )
})

test_that("use_config adopts config and dbc can read it", {
  local_rpg_sandbox()
  init_yamls()

  incoming_cfg <- withr::local_tempfile(fileext = ".yml")
  yaml::write_yaml(
    list(
      config = list(
        dev = list(host = "127.0.0.1", port = 5432, user = "dev_user", password = "dev_pass")
      )
    ),
    incoming_cfg
  )

  expect_error(use_config(incoming_cfg), "Failed to overwrite existing config")

  out_path <- use_config(incoming_cfg, overwrite = TRUE)
  expect_true(fs::file_exists(out_path))

  args <- dbc(cfg = "dev", db = "mydb", args_only = TRUE)
  expect_equal(args$host, "127.0.0.1")
  expect_equal(args$port, 5432)
  expect_equal(args$user, "dev_user")
  expect_equal(args$password, "dev_pass")
  expect_equal(args$dbname, "mydb")
})
