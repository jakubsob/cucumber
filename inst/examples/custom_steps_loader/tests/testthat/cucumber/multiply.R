box::use(
  cucumber[
    when,
  ],
)

box::use(
  R/multiply[multiply],
)

#' @export
steps <- list(
  when("I multiply {int} and {int}", function(x, y, context) {
    context$result <- multiply(x, y)
  })
)
