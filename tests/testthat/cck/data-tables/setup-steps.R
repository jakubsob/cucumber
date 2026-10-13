raw <- function(data_table) rbind(names(data_table), as.matrix(data_table), deparse.level = 0)

when("the following table is transposed:", function(data_table, context) {
  context$transposed <- t(raw(data_table))
})

then("it should be:", function(data_table, context) {
  expect_equal(unname(context$transposed), unname(raw(data_table)))
})
