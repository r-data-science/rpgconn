local_rpg_sandbox <- function(envir = parent.frame()) {
  base_dir <- withr::local_tempdir(.local_envir = envir)
  withr::local_envvar(
    c(
      R_USER_CONFIG_DIR = base_dir,
      RPG_CONN_STRING = NA_character_
    ),
    .local_envir = envir
  )

  list(
    base_dir = base_dir,
    config_dir = tools::R_user_dir("rpgconn", which = "config")
  )
}

write_test_config <- function(path, cfg_name = "dev") {
  cfg <- list(host = "localhost", port = 5432, user = "tester", password = "secret")
  payload <- list(config = list())
  payload$config[[cfg_name]] <- cfg
  yaml::write_yaml(payload, path)
}
