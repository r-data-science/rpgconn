test_that("optional e2e test against local Postgres succeeds", {
  skip_on_cran()
  skip_if_not_installed("data.table")

  if (!identical(tolower(Sys.getenv("RPGCONN_RUN_DB_TESTS", "false")), "true")) {
    skip("Set RPGCONN_RUN_DB_TESTS=true to enable local Postgres e2e tests")
  }

  conn_str <- Sys.getenv("RPGCONN_TEST_CONN_STRING", unset = "")
  if (!nzchar(conn_str)) {
    conn_str <- "postgresql://postgres:postgres@localhost:5432/postgres"
  }

  local_rpg_sandbox()
  withr::local_envvar(c(RPG_CONN_STRING = conn_str), .local_envir = environment())

  cn <- NULL
  on.exit(
    if (!is.null(cn) && DBI::dbIsValid(cn)) {
      dbd(cn)
    },
    add = TRUE
  )

  cn <- dbc()

  DBI::dbExecute(cn, "CREATE TEMP TABLE rpgconn_e2e (id INTEGER, payload TEXT)")
  DBI::dbExecute(cn, "INSERT INTO rpgconn_e2e (id, payload) VALUES (1, 'ok')")

  result_dt <- data.table::as.data.table(
    DBI::dbGetQuery(cn, "SELECT id, payload FROM rpgconn_e2e")
  )

  expect_equal(nrow(result_dt), 1L)
  expect_equal(result_dt$id[[1]], 1L)
  expect_equal(result_dt$payload[[1]], "ok")
})
