test_that("db_query_safe validates inputs", {
  # Test with invalid connection
  expect_error(
    db_query_safe("not_a_connection", "SELECT * FROM test"),
    "cn must be a valid database connection object"
  )
  
  # Test with invalid query
  mock_cn <- structure(list(), class = "PqConnection")
  expect_error(
    db_query_safe(mock_cn, c("query1", "query2")),
    "query must be a single character string"
  )
  expect_error(
    db_query_safe(mock_cn, 123),
    "query must be a single character string"
  )
})

test_that("db_query_safe validates params format", {
  mock_cn <- structure(list(), class = "PqConnection")
  
  # Test with invalid params (not a list)
  expect_error(
    db_query_safe(mock_cn, "SELECT * FROM test WHERE id = ?", params = "not_a_list"),
    "params must be a list"
  )
  expect_error(
    db_query_safe(mock_cn, "SELECT * FROM test WHERE id = ?", params = 123),
    "params must be a list"
  )
})

test_that("db_execute_safe validates inputs", {
  # Test with invalid connection
  expect_error(
    db_execute_safe("not_a_connection", "INSERT INTO test VALUES (?)"),
    "cn must be a valid database connection object"
  )
  
  # Test with invalid query
  mock_cn <- structure(list(), class = "PqConnection")
  expect_error(
    db_execute_safe(mock_cn, c("query1", "query2")),
    "query must be a single character string"
  )
  expect_error(
    db_execute_safe(mock_cn, 123),
    "query must be a single character string"
  )
})

test_that("db_execute_safe validates params format", {
  mock_cn <- structure(list(), class = "PqConnection")
  
  # Test with invalid params (not a list or data frame)
  expect_error(
    db_execute_safe(mock_cn, "INSERT INTO test VALUES (?)", params = "not_valid"),
    "params must be a list or data frame"
  )
  expect_error(
    db_execute_safe(mock_cn, "INSERT INTO test VALUES (?)", params = 123),
    "params must be a list or data frame"
  )
})

# Note: Full integration tests would require a real database connection.
# The tests above focus on input validation which can be tested without a database.
# In a real-world scenario with access to a test database, you would add tests like:
#
# test_that("db_query_safe executes parameterized SELECT", {
#   cn <- dbc("test_db")
#   # Create test table
#   DBI::dbExecute(cn, "CREATE TEMP TABLE test_users (id INT, name TEXT, age INT)")
#   DBI::dbExecute(cn, "INSERT INTO test_users VALUES (1, 'Alice', 30), (2, 'Bob', 25)")
#   
#   # Test parameterized query
#   result <- db_query_safe(cn, "SELECT * FROM test_users WHERE age > ?", params = list(26))
#   expect_equal(nrow(result), 1)
#   expect_equal(result$name, "Alice")
#   
#   dbd(cn)
# })
#
# test_that("db_execute_safe executes parameterized INSERT", {
#   cn <- dbc("test_db")
#   # Create test table
#   DBI::dbExecute(cn, "CREATE TEMP TABLE test_users (name TEXT, email TEXT)")
#   
#   # Test single insert
#   rows <- db_execute_safe(
#     cn,
#     "INSERT INTO test_users (name, email) VALUES (?, ?)",
#     params = list("John", "john@example.com")
#   )
#   expect_equal(rows, 1)
#   
#   # Test batch insert
#   batch_data <- data.frame(
#     name = c("Alice", "Bob"),
#     email = c("alice@example.com", "bob@example.com")
#   )
#   rows <- db_execute_safe(
#     cn,
#     "INSERT INTO test_users (name, email) VALUES (?, ?)",
#     params = batch_data
#   )
#   expect_equal(rows, 2)
#   
#   dbd(cn)
# })
