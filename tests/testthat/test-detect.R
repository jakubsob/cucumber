describe("detect_table", {
  it("should return TRUE if lines are a table with 1 row", {
    # Arrange
    lines <- c("| a | b |", "| 1 | 2 |")

    # Act
    result <- detect_table(lines)

    # Assert
    expect_true(result)
  })

  it("should return TRUE if lines are a table with many rows", {
    # Arrange
    lines <- c("| a | b |", "| 1 | 2 |", "| 3 | 4 |")

    # Act
    result <- detect_table(lines)

    # Assert
    expect_true(result)
  })

  it("should return TRUE if lines are a table only with header", {
    # Arrange
    lines <- c("| a | b |")

    # Act
    result <- detect_table(lines)

    # Assert
    expect_true(result)
  })

  it("should return FALSE if lines are not a table", {
    # Arrange
    lines <- c("a", "b")

    # Act
    result <- detect_table(lines)

    # Assert
    expect_false(result)
  })

  it("should return FALSE if lines are a docstring", {
    # Arrange
    lines <- c("```", "a", "b", "```")

    # Act
    result <- detect_table(lines)

    # Assert
    expect_false(result)
  })

  it("should return FALSE if lines are NULL", {
    # Arrange
    lines <- NULL

    # Act
    result <- detect_table(lines)

    # Assert
    expect_false(result)
  })

  it("should reurn FALSe if lines are NA", {
    # Arrange
    lines <- NA

    # Act
    result <- detect_table(lines)

    # Assert
    expect_false(result)
  })
})
