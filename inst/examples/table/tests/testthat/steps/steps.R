read_table <- function(x) {
  x |>
    dplyr::mutate_all(as.numeric)
}

given("I have a table", function(table, context) {
  context$table <- table |>
    read_table()
})

when("I multiply {string} column by {int}", function(column, factor, context) {
  context$table <- context$table |>
    dplyr::mutate(dplyr::across({{ column }}, \(x) x * factor))
})

then("I should see the following table", function(table, context) {
  table <- table |>
    read_table()

  expect_equal(
    context$table,
    table
  )
})
