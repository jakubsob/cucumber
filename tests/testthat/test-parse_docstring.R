describe("parse_docstring", {
  it("should remove the first and last lines of a docstring", {
    # Arrange
    lines <- c(
      "\"\"\"",
      "a",
      "b",
      "\"\"\""
    )

    # Act
    result <- parse_docstring(lines)

    # Assert
    expect_equal(result, c("a", "b"))
  })
})
