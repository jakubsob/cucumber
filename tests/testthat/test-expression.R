describe("expression_to_pattern", {
  it("should convert an expression to a pattern that detects parameters", {
    # Arrange
    expression <- "word {string} word"
    parameters <- .parameters(
      .parameter(
        name = "string",
        regex = "[^\"]*",
        transformer = as.character
      )
    )

    # Act
    result <- expression_to_pattern(expression, parameters)

    # Assert
    expect_equal(result, "word ([^\"]*) word")
  })
})
