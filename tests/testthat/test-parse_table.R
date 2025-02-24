describe("parse_table", {
  it("should parse Data Table with 1 row", {
    # Arrange
    x <- c(
      "| start | eat | left |",
      "|    12 |   5 |    7 |"
    )

    # Act
    result <- parse_table(x)

    # Assert
    expect_equal(
      result,
      tibble::tibble(
        start = c("12"),
        eat = c("5"),
        left = c("7")
      )
    )
  })

  it("should parse Data Table with header only", {
    # Arrange
    x <- c(
      "| start | eat | left |"
    )

    # Act
    result <- parse_table(x)

    # Assert
    expect_equal(
      result,
      tibble::tibble(
        start = character(),
        eat = character(),
        left = character()
      )
    )
  })

  it("should parse Data Table with many rows", {
    # Arrange
    x <- c(
      "| start | eat | left |",
      "|    12 |   5 |    7 |",
      "|    13 |   6 |    7 |"
    )

    # Act
    result <- parse_table(x)

    # Assert
    expect_equal(
      result,
      tibble::tibble(
        start = c("12", "13"),
        eat = c("5", "6"),
        left = c("7", "7")
      )
    )
  })

  it("should parse Data Table with escaped characters", {
    # Arrange
    x <- c(
      "| start | eat  | left  |",
      "| '\\'  | '\n' | '\\|' |"
    )

    # Act
    result <- parse_table(x)

    # Assert
    expect_equal(
      result,
      tibble::tibble(
        start = c("'\\'"),
        eat = c("'\n'"),
        left = c("'|'")
      )
    )
  })
})
