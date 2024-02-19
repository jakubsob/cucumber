describe("normalize_feature", {
  it("should replace 'And' keywords with the preceeding keyword", {
    # Arrange
    lines <- c(
      "Feature: Addition",
      "  Scenario: Addition should work for 2 numbers",
      "    Given I have 1",
      "    And I have 2",
      "    And I have 3",
      "    When I add them",
      "    And I do nothing more",
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

  it("should replace 'But' keywords with the preceeding keyword", {
    # Arrange
    lines <- c(
      "Feature: Addition",
      "  Scenario: Addition should work for 2 numbers",
      "    Given I have 1",
      "    But I have 2",
      "    But I have 3",
      "    When I add them",
      "    But I do nothing more",
      "    Then I get 6",
      "    But it's over"
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
})
