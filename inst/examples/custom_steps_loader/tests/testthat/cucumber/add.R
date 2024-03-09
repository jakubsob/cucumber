box::use(
  cucumber[
    when,
  ],
)

box::use(
  R/add[add],
)

#' @export
steps <- list(
  when("I add {int} and {int}", function(x, y, context) {
    context$result <- add(x, y)
  })
)
