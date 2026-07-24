describe("match_single_step snippet", {
  local_steps <- function(env = parent.frame()) {
    withr::local_options(
      .cucumber_steps_option = "test_steps",
      .cucumber_parameters_option = "test_parameters",
      test_steps = NULL,
      test_parameters = NULL,
      .local_envir = env
    )
    set_default_parameters()
    given("some other step", function(context) {})
  }

  it("uses the step keyword and indents the snippet", {
    local_steps()
    step <- new_pickle_step(keyword = "Then", text = "it passes")

    expect_snapshot(
      match_single_step(step),
      error = TRUE
    )
  })

  it("keeps parameter placeholders in the snippet", {
    local_steps()
    step <- new_pickle_step(
      keyword = "When",
      text = "I have 5 cucumbers in my basket"
    )

    expect_snapshot(
      match_single_step(step),
      error = TRUE
    )
  })
})
