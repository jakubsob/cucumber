describe("match_single_step snippet", {

  it("uses the step keyword and indents the snippet", {
    local_steps()
    given("some other step", function(context) {})
    step <- new_pickle_step(keyword = "Then", type = "Outcome", text = "it passes")

    matched <- match_single_step(step)

    expect_equal(matched$status, "undefined")
    expect_snapshot(cat(conditionMessage(matched$error)))
  })

  it("keeps parameter placeholders in the snippet", {
    local_steps()
    given("some other step", function(context) {})
    step <- new_pickle_step(
      keyword = "When",
      type = "Action",
      text = "I have 5 cucumbers in my basket"
    )

    matched <- match_single_step(step)

    expect_equal(matched$status, "undefined")
    expect_snapshot(cat(conditionMessage(matched$error)))
  })
})

describe("format_step_snippet", {
  it("escapes Cucumber Expression syntax so the snippet matches the step", {
    # Arrange
    local_steps()
    description <- "I see (5) items on a/b {page} \\ \"quoted \\\"text\\\"\""

    # Act
    snippet <- format_step_snippet("Then", description, get_parameters())

    # Assert
    code <- parse(text = snippet)[[1]]
    expression <- code[[2]]
    expect_equal(expression, "I see \\({int}) items on a\\/b \\{page} \\\\ {string}")
    expect_true(stringr::str_detect(description, expression_to_pattern(expression)))
  })

  it("suggests every parameter type that matches, the first one as code", {
    local_steps()

    snippet <- format_step_snippet("Given", "I have 5 and 6 cucumbers", get_parameters())

    expect_snapshot(cat(snippet))
  })

  it("passes parameters in the order they are written", {
    local_steps()

    snippet <- format_step_snippet("Given", "\"a\" has 1.5 and 'b'", get_parameters())

    expect_snapshot(cat(snippet))
  })

  it("adds the data table and doc string arguments", {
    local_steps()

    snippet <- format_step_snippet("When", "I send", get_parameters(), c("dataTable", "docString"))

    expect_snapshot(cat(snippet))
  })

  it("uses custom parameter types", {
    local_steps()
    define_parameter_type("colour", "red|blue", as.character)
    define_parameter_type("size", "big|small", as.character, use_for_snippets = FALSE)

    snippet <- format_step_snippet("Given", "a big red ball", get_parameters())

    expect_snapshot(cat(snippet))
  })
})
