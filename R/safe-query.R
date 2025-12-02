#' Execute Parameterized Queries Safely
#'
#' @description
#' These functions provide a safe interface for executing parameterized queries
#' to prevent SQL injection attacks. They use DBI's parameter binding mechanism
#' to separate SQL code from data values.
#'
#' @param cn A database connection object created by \code{\link{dbc}}
#' @param query SQL query string with placeholders (\code{?} for positional parameters)
#' @param params A list of parameter values to bind to the query for
#'   \code{db_query_safe}. For \code{db_execute_safe}, either a list (single execution)
#'   or a data frame (batch execution) where each row represents one set of parameters.
#' @param n Maximum number of records to retrieve. Default is -1 (all records).
#'   Only applicable to \code{db_query_safe}.
#'
#' @details
#' \code{db_query_safe} is used for SELECT queries that return results.
#' It accepts a list of parameters for a single query execution.
#'
#' \code{db_execute_safe} is used for INSERT, UPDATE, DELETE, or other statements
#' that don't return results but return the number of affected rows.
#' It supports both single execution (with a list) and batch execution (with a data frame).
#'
#' Parameter placeholders in the query should be \code{?} for positional binding
#' (or \code{$1}, \code{$2}, etc. depending on your database backend).
#' The \code{params} argument should contain values in the same order as
#' the placeholders appear in the query.
#'
#' For batch operations with \code{db_execute_safe}, pass a data frame to \code{params}
#' where each row represents one set of parameters. The statement will be executed
#' once for each row efficiently using prepared statement binding.
#'
#' @return
#' \code{db_query_safe} returns a data frame with query results.
#' \code{db_execute_safe} returns the number of rows affected by the statement.
#'
#' @importFrom DBI dbSendQuery dbSendStatement dbBind dbFetch dbClearResult dbGetRowsAffected
#'
#' @examples
#' \dontrun{
#' cn <- dbc("mydb")
#'
#' # Safe SELECT query with parameters
#' users <- db_query_safe(
#'   cn,
#'   "SELECT * FROM users WHERE age > ? AND city = ?",
#'   params = list(25, "New York")
#' )
#'
#' # Safe INSERT statement
#' db_execute_safe(
#'   cn,
#'   "INSERT INTO users (name, email) VALUES (?, ?)",
#'   params = list("John Doe", "john@example.com")
#' )
#'
#' # Batch INSERT - insert multiple rows at once
#' new_users <- data.frame(
#'   name = c("Alice", "Bob", "Charlie"),
#'   email = c("alice@example.com", "bob@example.com", "charlie@example.com")
#' )
#' db_execute_safe(
#'   cn,
#'   "INSERT INTO users (name, email) VALUES (?, ?)",
#'   params = new_users
#' )
#'
#' dbd(cn)
#' }
#' @name safe_query
NULL

#' @describeIn safe_query Execute a parameterized SELECT query safely
#' @export
db_query_safe <- function(cn, query, params = NULL, n = -1) {
  # Validate inputs
  if (!inherits(cn, "PqConnection")) {
    stop("cn must be a valid database connection object", call. = FALSE)
  }
  if (!is.character(query) || length(query) != 1) {
    stop("query must be a single character string", call. = FALSE)
  }
  
  # Validate params format
  if (!is.null(params)) {
    if (!is.list(params)) {
      stop("params must be a list", call. = FALSE)
    }
  }
  
  # Send query to database
  rs <- DBI::dbSendQuery(cn, query)
  
  # Ensure result set is cleared on exit
  on.exit(DBI::dbClearResult(rs), add = TRUE)
  
  # Bind parameters if provided
  if (!is.null(params)) {
    DBI::dbBind(rs, params)
  }
  
  # Fetch and return results
  result <- DBI::dbFetch(rs, n = n)
  return(result)
}

#' @describeIn safe_query Execute a parameterized statement (INSERT, UPDATE, DELETE) safely
#' @export
db_execute_safe <- function(cn, query, params = NULL) {
  # Validate inputs
  if (!inherits(cn, "PqConnection")) {
    stop("cn must be a valid database connection object", call. = FALSE)
  }
  if (!is.character(query) || length(query) != 1) {
    stop("query must be a single character string", call. = FALSE)
  }
  
  # Validate params format
  if (!is.null(params)) {
    if (!is.list(params) && !is.data.frame(params)) {
      stop("params must be a list or data frame", call. = FALSE)
    }
  }
  
  # Send statement to database
  rs <- DBI::dbSendStatement(cn, query)
  
  # Ensure result set is cleared on exit
  on.exit(DBI::dbClearResult(rs), add = TRUE)
  
  # Bind parameters if provided
  if (!is.null(params)) {
    # dbBind handles both single list and data frame (batch) automatically
    DBI::dbBind(rs, params)
  }
  
  # Get and return rows affected
  rows_affected <- DBI::dbGetRowsAffected(rs)
  return(rows_affected)
}
