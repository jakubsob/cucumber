describe("normalize_feature", {
  it("should replace all step keywords with 'Step'", {
    # Arrange
    lines <- c(
      "Feature: Addition",
      "  Scenario: Addition should work for 2 numbers",
      "    Given I have 1",
      "    * I have 2",
      "    * I have 3",
      "    When I add them",
      "    But I do nothing more",
      "    Then I get 6",
      "    And it's over"
    )

    # Act
    result <- normalize_feature(lines)

    # Assert
    expect_equal(
      result,
      c(
        "Feature: Addition",
        "  Scenario: Addition should work for 2 numbers",
        "    Step I have 1",
        "    Step I have 2",
        "    Step I have 3",
        "    Step I add them",
        "    Step I do nothing more",
        "    Step I get 6",
        "    Step it's over"
      )
    )
  })

  it("should replace 'Example:' keyword with 'Scenario:'", {
    # Arrange
    lines <- c(
      "Feature: Addition",
      "  Example: Addition should work for 2 numbers",
      "    Given I have 1"
    )

    # Act
    result <- normalize_feature(lines)

    # Assert
    expect_equal(
      result,
      c(
        "Feature: Addition",
        "  Scenario: Addition should work for 2 numbers",
        "    Step I have 1"
      )
    )
  })

  it("should replace 'Examples:' keyword with 'Scenarios:'", {
    # Arrange
    lines <- c(
      "Feature: Addition",
      "  Examples: Addition should work for 2 numbers"
    )

    # Act
    result <- normalize_feature(lines)

    # Assert
    expect_equal(
      result,
      c(
        "Feature: Addition",
        "  Scenarios: Addition should work for 2 numbers"
      )
    )
  })

  it("should omit docstrings", {
    # Arrange
    lines <- c(
      "Feature: Addition",
      "  Scenario: Addition should work for 2 numbers",
      "    Given I have",
      "    ```",
      "    *",
      "    And",
      "    But",
      "    ```",
      "    When I add them",
      "    Then I get 6"
    )

    # Act
    result <- normalize_feature(lines)

    # Assert
    expect_equal(
      result,
      c(
        "Feature: Addition",
        "  Scenario: Addition should work for 2 numbers",
        "    Step I have",
        "    ```",
        "    *",
        "    And",
        "    But",
        "    ```",
        "    Step I add them",
        "    Step I get 6"
      )
    )
  })

  it("should omit tables", {
    # Arrange
    lines <- c(
      "Feature: Addition",
      "  Scenario: Addition should work for 2 numbers",
      "    Given I have",
      "    | Given | When | Then |",
      "    | *     | *    | *    |",
      "    | *     | *    | *    |",
      "    When I add them",
      "    Then I get 6"
    )

    # Act
    result <- normalize_feature(lines)

    # Assert
    expect_equal(
      result,
      c(
        "Feature: Addition",
        "  Scenario: Addition should work for 2 numbers",
        "    Step I have",
        "    | Given | When | Then |",
        "    | *     | *    | *    |",
        "    | *     | *    | *    |",
        "    Step I add them",
        "    Step I get 6"
      )
    )
  })
})
