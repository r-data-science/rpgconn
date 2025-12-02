test_that("Test init yamls", {
  init_yamls() |>
    fs::dir_exists() |>
    expect_true()
})

test_that("Test Files", {
  # The example configuration templates should be installed in the package's
  # extdata directory.  Use system.file() to locate them.
  system.file("extdata", "config.yml", package = "rpgconn") |>
    fs::file_exists() |>
    expect_true()
  system.file("extdata", "options.yml", package = "rpgconn") |>
    fs::file_exists() |>
    expect_true()
})

test_that("Test Edit", {
  edit_config() |>
    fs::file_exists() |>
    expect_true()
  edit_options() |>
    fs::file_exists() |>
    expect_true()
})

ck_names <- c(
  "host", "port", "dbname", "drv", "connect_timeout",
  "timezone", "application_name", "client_encoding",
  "user", "password"
)

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



test_that("Test custom cfg_path parameter", {
  # Create a temporary config file
  temp_config <- tempfile(fileext = ".yml")
  test_config <- list(
    config = list(
      test_cfg = list(
        host = "localhost",
        port = "5432"
      )
    )
  )
  yaml::write_yaml(test_config, temp_config)

  # Test that custom path works
  args <- dbc(
    cfg = "test_cfg", db = "test_db",
    args_only = TRUE, cfg_path = temp_config
  )
  expect_equal(args$host, "localhost")
  expect_equal(args$dbname, "test_db")

  # Clean up
  unlink(temp_config)
})

test_that("Test custom opt_path parameter", {
  # Similar test for opt_path
  temp_opts <- tempfile(fileext = ".yml")
  test_opts <- list(
    options = list(
      connect_timeout = 30,
      timezone = "UTC"
    )
  )
  yaml::write_yaml(test_opts, temp_opts)

  args <- dbc("local", "test", args_only = TRUE, opt_path = temp_opts)
  expect_equal(args$connect_timeout, 30)

  unlink(temp_opts)
})

# Tests for robust connection string parsing
test_that("Parse URI format with postgresql:// prefix", {
  conn_str <- "postgresql://testuser:testpass@localhost:5432/testdb"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_equal(args$password, "testpass")
  expect_equal(args$host, "localhost")
  expect_equal(args$port, "5432")
  expect_equal(args$dbname, "testdb")
})

test_that("Parse URI format with postgres:// prefix", {
  conn_str <- "postgres://testuser:testpass@localhost:5432/testdb"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_equal(args$password, "testpass")
  expect_equal(args$host, "localhost")
  expect_equal(args$port, "5432")
  expect_equal(args$dbname, "testdb")
})

test_that("Parse URI format without password", {
  conn_str <- "postgresql://testuser@localhost:5432/testdb"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_null(args$password)
  expect_equal(args$host, "localhost")
  expect_equal(args$port, "5432")
  expect_equal(args$dbname, "testdb")
})

test_that("Parse URI format with query parameters", {
  conn_str <- "postgresql://testuser:testpass@localhost:5432/testdb?sslmode=require"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_equal(args$password, "testpass")
  expect_equal(args$host, "localhost")
  expect_equal(args$port, "5432")
  expect_equal(args$dbname, "testdb")
  expect_equal(args$sslmode, "require")
})

test_that("Parse URI format with multiple query parameters", {
  conn_str <- "postgresql://testuser@localhost/testdb?sslmode=require&connect_timeout=10"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_equal(args$host, "localhost")
  expect_equal(args$dbname, "testdb")
  expect_equal(args$sslmode, "require")
  expect_equal(args$connect_timeout, "10")
})

test_that("Parse URI format with URL-encoded characters", {
  # Password with @ and : characters (URL-encoded)
  conn_str <- "postgresql://testuser:p%40ss%3Aword@localhost:5432/testdb"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_equal(args$password, "p@ss:word")
  expect_equal(args$host, "localhost")
  expect_equal(args$port, "5432")
  expect_equal(args$dbname, "testdb")
})

test_that("Parse keyword/value format with semicolons (legacy)", {
  conn_str <- "user=testuser;password=testpass;host=localhost;port=5432;dbname=testdb"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_equal(args$password, "testpass")
  expect_equal(args$host, "localhost")
  expect_equal(args$port, "5432")
  expect_equal(args$dbname, "testdb")
})

test_that("Parse keyword/value format with whitespace", {
  conn_str <- "host=localhost user=testuser password=testpass dbname=testdb port=5432"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_equal(args$password, "testpass")
  expect_equal(args$host, "localhost")
  expect_equal(args$port, "5432")
  expect_equal(args$dbname, "testdb")
})

test_that("Parse keyword/value format with quoted values", {
  conn_str <- "host='my host' user=testuser dbname='test db' port=5432"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$host, "my host")
  expect_equal(args$user, "testuser")
  expect_equal(args$dbname, "test db")
  expect_equal(args$port, "5432")
})

test_that("URI format without port defaults correctly", {
  conn_str <- "postgresql://testuser:testpass@localhost/testdb"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_equal(args$password, "testpass")
  expect_equal(args$host, "localhost")
  expect_null(args$port)
  expect_equal(args$dbname, "testdb")
})

test_that("URI format with password containing colon", {
  # Password: pass:word:123
  conn_str <- "postgresql://testuser:pass%3Aword%3A123@localhost:5432/testdb"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_equal(args$password, "pass:word:123")
  expect_equal(args$host, "localhost")
  expect_equal(args$port, "5432")
  expect_equal(args$dbname, "testdb")
})

test_that("URI format with query parameter value containing equals", {
  # Query parameter with value containing =
  conn_str <- "postgresql://testuser@localhost/testdb?options=-c%20search_path%3Dschema1%2Cschema2"
  Sys.setenv(RPG_CONN_STRING = conn_str)
  
  args <- dbc(args_only = TRUE)
  
  expect_equal(args$user, "testuser")
  expect_equal(args$options, "-c search_path=schema1,schema2")
})
