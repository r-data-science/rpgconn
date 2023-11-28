
ck_names <- c("host", "port", "dbname", "drv", "connect_timeout",
              "timezone", "application_name", "client_encoding",
              "user", "password")

test_that("Test conn string validation", {
  Sys.setenv(RPG_CONN_STRING = "test")
  expect_error(dbc(), "Unable to make connection")

  Sys.setenv(RPG_CONN_STRING = "user=...;password=...;host=...;port=...;dbname=...")
  expect_error(dbc(), 'invalid integer value "..." for connection option "port"')

  expect_named(dbc(args_only = TRUE), ck_names, ignore.order = TRUE)
})


test_that("Test conn config validation", {
  expect_error(
    object = dbc(cfg = "local"),
    regexp = "Database name must be specified when using arg cfg"
  )
  expect_error(
    object = dbc("fajdksaf", "test"),
    regexp = "Connection config not found"
  )
  ck_names2 <- ck_names[!ck_names %in% c("user", "password")]
  args <- dbc(cfg = "local", db = "test", args_only = TRUE)
  expect_named(args, ck_names2, ignore.order = TRUE)
})
