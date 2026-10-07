describe("match_single_step snippet", {

  it("uses the step keyword and indents the snippet", {
    local_steps()
    given("some other step", function(context) {})
    step <- new_pickle_step(keyword = "Then", text = "it passes")

    expect_snapshot(
      match_single_step(step),
      error = TRUE
    )
  })

  it("keeps parameter placeholders in the snippet", {
    local_steps()
    given("some other step", function(context) {})
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

describe("format_step_snippet", {
  it("escapes Cucumber Expression syntax so the snippet matches the step", {
    # Arrange
    description <- "I see (5) items on a/b {page}"

    # Act
    snippet <- format_step_snippet("Then", description, get_parameters())

    # Assert
    code <- parse(text = snippet)[[1]]
    expression <- code[[2]]
    expect_equal(expression, "I see \\({int}\\) items on a\\/b \\{page\\}")
    expect_true(stringr::str_detect(
      description,
      step_regex(expression_to_pattern(expression))
    ))
  })
})
