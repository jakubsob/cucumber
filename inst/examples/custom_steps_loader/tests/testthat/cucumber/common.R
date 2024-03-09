box::use(
  testthat[expect_equal],
  cucumber[
    then,
  ],
)

#' @export
steps <- list(
  then("I get {int}", function(expected, context) {
    expect_equal(context$result, expected)
  })
)
