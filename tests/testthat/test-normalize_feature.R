describe("normalize_feature", {
  it("should preserve Given/When/Then and resolve And/But/* to previous keyword", {
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
        "    Given I have 1",
        "    Given I have 2",
        "    Given I have 3",
        "    When I add them",
        "    When I do nothing more",
        "    Then I get 6",
        "    Then it's over"
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
        "    Given I have 1"
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

  it("shouldn replace only keywords, not words in step descriptions", {
    # Arrange
    lines <- c(
      "Feature: Feature",
      "  Scenario: Scenario",
      "    Given I have Given",
      "    When I add When",
      "    Then I get Then",
      "    And I have And"
    )

    # Act
    result <- normalize_feature(lines)

    # Assert
    expect_equal(
      result,
      c(
        "Feature: Feature",
        "  Scenario: Scenario",
        "    Given I have Given",
        "    When I add When",
        "    Then I get Then",
        "    Then I have And"
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
        "    Given I have",
        "    ```",
        "    *",
        "    And",
        "    But",
        "    ```",
        "    When I add them",
        "    Then I get 6"
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
        "    Given I have",
        "    | Given | When | Then |",
        "    | *     | *    | *    |",
        "    | *     | *    | *    |",
        "    When I add them",
        "    Then I get 6"
      )
    )
  })
})
