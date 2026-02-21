test_that("init_yamls creates files in an isolated user directory", {
  sandbox <- local_rpg_sandbox()

  expect_false(fs::dir_exists(sandbox$config_dir))
  out <- init_yamls()

  expect_equal(as.character(out), sandbox$config_dir)
  expect_true(fs::dir_exists(sandbox$config_dir))
  expect_true(fs::file_exists(fs::path(sandbox$config_dir, "config.yml")))
  expect_true(fs::file_exists(fs::path(sandbox$config_dir, "options.yml")))
})

test_that("edit helpers return existing paths in non-interactive mode", {
  local_rpg_sandbox()
  init_yamls()

  expect_true(fs::file_exists(edit_config()))
  expect_true(fs::file_exists(edit_options()))
})

test_that("dbc errors when RPG_CONN_STRING is not set", {
  local_rpg_sandbox()
  expect_error(dbc(), "RPG_CONN_STRING not set")
})

test_that("dbc parses URI connection strings", {
  local_rpg_sandbox()
  withr::local_envvar(
    c(RPG_CONN_STRING = "postgresql://testuser:testpass@localhost:5432/testdb?sslmode=require"),
    .local_envir = environment()
  )

  args <- dbc(args_only = TRUE)

  expect_equal(args$user, "testuser")
  expect_equal(args$password, "testpass")
  expect_equal(args$host, "localhost")
  expect_equal(args$port, "5432")
  expect_equal(args$dbname, "testdb")
  expect_equal(args$sslmode, "require")
})

test_that("dbc parses postgres:// and IPv6 URI forms", {
  local_rpg_sandbox()

  withr::local_envvar(
    c(RPG_CONN_STRING = "postgres://user:pass@[2001:db8::1]:5432/db"),
    .local_envir = environment()
  )
  args <- dbc(args_only = TRUE)

  expect_equal(args$user, "user")
  expect_equal(args$password, "pass")
  expect_equal(args$host, "2001:db8::1")
  expect_equal(args$port, "5432")
  expect_equal(args$dbname, "db")
})

test_that("keyword/value parsing supports semicolon, whitespace, and equals in values", {
  local_rpg_sandbox()

  withr::local_envvar(
    c(RPG_CONN_STRING = "user=alice;password=secret;host=localhost;port=5432;dbname=mydb"),
    .local_envir = environment()
  )
  args1 <- dbc(args_only = TRUE)
  expect_equal(args1$user, "alice")
  expect_equal(args1$port, "5432")

  withr::local_envvar(
    c(RPG_CONN_STRING = "host='my host' user=alice dbname='my db' port=5432 options='-c search_path=schema1,schema2'"),
    .local_envir = environment()
  )
  args2 <- dbc(args_only = TRUE)
  expect_equal(args2$host, "my host")
  expect_equal(args2$dbname, "my db")
  expect_equal(args2$options, "-c search_path=schema1,schema2")
})

test_that("invalid connection string formats fail fast", {
  local_rpg_sandbox()

  withr::local_envvar(c(RPG_CONN_STRING = "foo"), .local_envir = environment())
  expect_error(dbc(), "format not recognized")

  withr::local_envvar(c(RPG_CONN_STRING = "mysql://user@host/db"), .local_envir = environment())
  expect_error(dbc(), "must start with 'postgres://' or 'postgresql://'")

  withr::local_envvar(c(RPG_CONN_STRING = "postgresql://user@host"), .local_envir = environment())
  expect_error(dbc(), "must include")

  withr::local_envvar(c(RPG_CONN_STRING = "postgresql://host/?sslmode=require"), .local_envir = environment())
  expect_error(dbc(), "Database name appears to be missing")

  withr::local_envvar(c(RPG_CONN_STRING = "postgresql://user@:5432/db"), .local_envir = environment())
  expect_error(dbc(), "Host portion after '@' is empty")

  withr::local_envvar(c(RPG_CONN_STRING = "postgresql://user@host:abc/db"), .local_envir = environment())
  expect_error(dbc(), "Port in connection string is not a valid integer")

  withr::local_envvar(c(RPG_CONN_STRING = "postgresql://user@host:70000/db"), .local_envir = environment())
  expect_error(dbc(), "must be between 1 and 65535")
})

test_that("invalid env var output redacts password values", {
  local_rpg_sandbox()
  withr::local_envvar(
    c(RPG_CONN_STRING = "host=localhost;port=;dbname=mydb;user=alice;password=supersecret"),
    .local_envir = environment()
  )

  messages <- character(0)
  expect_error(
    withCallingHandlers(
      dbc(),
      message = function(m) {
        messages <<- c(messages, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    ),
    "Unable to build connection arguments"
  )

  expect_false(any(grepl("supersecret", messages, fixed = TRUE)))
  expect_true(any(grepl("\\*\\*\\*\\*", messages)))
})

test_that("cfg mode uses custom cfg_path and opt_path", {
  local_rpg_sandbox()

  temp_cfg <- withr::local_tempfile(fileext = ".yml")
  temp_opt <- withr::local_tempfile(fileext = ".yml")

  write_test_config(temp_cfg, cfg_name = "dev")
  yaml::write_yaml(
    list(options = list(connect_timeout = 30, application_name = "rpgconn-tests")),
    temp_opt
  )

  args <- dbc(
    cfg = "dev",
    db = "analytics",
    args_only = TRUE,
    cfg_path = temp_cfg,
    opt_path = temp_opt
  )

  expect_equal(args$host, "localhost")
  expect_equal(args$port, 5432)
  expect_equal(args$dbname, "analytics")
  expect_equal(args$connect_timeout, 30)
  expect_equal(args$application_name, "rpgconn-tests")
})

test_that("legacy path argument remains supported and deprecated", {
  local_rpg_sandbox()

  temp_cfg <- withr::local_tempfile(fileext = ".yml")
  write_test_config(temp_cfg, cfg_name = "legacy")

  args <- NULL
  expect_warning(
    args <- dbc(cfg = "legacy", db = "warehouse", args_only = TRUE, path = temp_cfg),
    "deprecated"
  )

  expect_equal(args$host, "localhost")
  expect_equal(args$dbname, "warehouse")

  other_cfg <- withr::local_tempfile(fileext = ".yml")
  write_test_config(other_cfg, cfg_name = "other")

  expect_error(
    suppressWarnings(dbc(
      cfg = "legacy",
      db = "warehouse",
      args_only = TRUE,
      path = temp_cfg,
      cfg_path = other_cfg
    )),
    "Specify only one of `path` or `cfg_path`"
  )
})

test_that("cfg mode validates missing config and missing db", {
  local_rpg_sandbox()

  temp_cfg <- withr::local_tempfile(fileext = ".yml")
  write_test_config(temp_cfg, cfg_name = "dev")

  expect_error(
    dbc(cfg = "missing", db = "x", args_only = TRUE, cfg_path = temp_cfg),
    "Connection config not found"
  )

  expect_error(
    dbc(cfg = "dev", args_only = TRUE, cfg_path = temp_cfg),
    "Database name must be specified"
  )
})
