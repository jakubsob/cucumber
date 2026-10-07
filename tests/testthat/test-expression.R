describe("expression_to_pattern", {
  parameters <- .parameters(
    .parameter(
      name = "string",
      regex = "[^\"]*",
      transformer = as.character
    )
  )

  it("should convert an expression to a pattern that detects parameters", {
    # Act
    result <- expression_to_pattern("word {string} word", parameters)

    # Assert
    expect_equal(c(result), "word ([^\"]*) word")
    expect_equal(attr(result, "parameters"), "string")
  })

  it("should make text in parentheses optional", {
    expect_equal(c(expression_to_pattern("cucumber(s)", parameters)), "cucumber(?:s)?")
  })

  it("should convert words separated by a slash to alternatives", {
    expect_equal(
      c(expression_to_pattern("the Enter/Return key", parameters)),
      "the (?:Enter|Return) key"
    )
  })

  it("should keep a slash that does not separate two words literal", {
    expect_equal(c(expression_to_pattern("I visit /about", parameters)), "I visit /about")
  })

  it("should match anything with an anonymous parameter", {
    result <- expression_to_pattern("I am {}", parameters)

    expect_equal(c(result), "I am (.*)")
    expect_equal(attr(result, "parameters"), "")
  })

  it("should match regex special characters literally", {
    expect_equal(c(expression_to_pattern("Is it 5.0? $[x]+", parameters)), "Is it 5\\.0\\? \\$\\[x\\]\\+")
  })

  it("should match escaped characters literally", {
    expect_equal(
      c(expression_to_pattern("\\(a\\) \\{b\\} c\\/d \\\\", parameters)),
      "\\(a\\) \\{b\\} c/d \\\\"
    )
  })

  it("should fail on an undefined parameter type", {
    expect_error(expression_to_pattern("{color}", parameters), "Undefined parameter type")
  })
})
