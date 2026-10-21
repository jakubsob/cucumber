given("a step that always passes", function(context) {
  # no-op
})

second_time_pass <- 0
given("a step that passes the second time", function(context) {
  second_time_pass <<- second_time_pass + 1
  if (second_time_pass < 2) {
    stop("Exception in step")
  }
})

third_time_pass <- 0
given("a step that passes the third time", function(context) {
  third_time_pass <<- third_time_pass + 1
  if (third_time_pass < 3) {
    stop("Exception in step")
  }
})

given("a step that always fails", function(context) {
  stop("Exception in step")
})
