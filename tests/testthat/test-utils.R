describe("find_definition", {
  it("should find definition with {int} types", {
    # Arrange
    input <- c(
      "Feature: Add",
      "  Scenario: Adding 1 + 1",
      "    Given I have numbers 1 and 1",
      "    When I add numbers 1 and 1",
      "    Then the result is 2"
    )
    template <- "When I add numbers {int} and {int}"

    # Act
    result <- find_definition(input, template)

    # Assert
    expect_equal(result, "When I add numbers 1 and 1")
  })

  it("should find definition with {float} types", {
    # Arrange
    input <- c(
      "Feature: Add",
      "  Scenario: Adding 1.1 + 1.1",
      "    Given I have numbers 1.1 and 1.1",
      "    When I add numbers 1.1 and 1.1",
      "    Then the result is 2.2"
    )
    template <- "When I add numbers {float} and {float}"

    # Act
    result <- find_definition(input, template)

    # Assert
    expect_equal(result, "When I add numbers 1.1 and 1.1")
  })

  it("should find definition with {string} types", {
    # Arrange
    input <- c(
      "Feature: Add",
      "  Scenario: Adding one + one",
      "    Given I have numbers one and one",
      "    When I add numbers one and one",
      "    Then the result is two"
    )
    template <- "When I add numbers {string} and {string}"

    # Act
    result <- find_definition(input, template)

    # Assert
    expect_equal(result, "When I add numbers one and one")
  })

  it("should find definition with mixed types", {
    # Arrange
    input <- c(
      "Feature: Add",
      "  Scenario: Adding 1 + 1.1",
      "    Given I have numbers 1 and 1.1",
      "    When I add numbers 1 and 1.1",
      "    Then the result is 2.1"
    )
    template <- "When I add numbers {int} and {float}"

    # Act
    result <- find_definition(input, template)

    # Assert
    expect_equal(result, "When I add numbers 1 and 1.1")
  })
})

describe("extract_params", {
  it("should extract {int} types", {
    # Arrange
    input <- "When I add numbers 1 and 1"
    template <- "When I add numbers {int} and {int}"

    # Act
    result <- extract_params(input, template)

    # Assert
    expect_equal(result, list(1L, 1L))
  })

  it("should extract {float} types", {
    # Arrange
    input <- "When I add numbers 1.1 and 1.1"
    template <- "When I add numbers {float} and {float}"

    # Act
    result <- extract_params(input, template)

    # Assert
    expect_equal(result, list(1.1, 1.1))
  })

  it("should extract {string} types", {
    # Arrange
    input <- "When I add numbers one and one"
    template <- "When I add numbers {string} and {string}"

    # Act
    result <- extract_params(input, template)

    # Assert
    expect_equal(result, list("one", "one"))
  })

  it("should extract mixed types", {
    # Arrange
    input <- "When I add numbers 1 and 1.1"
    template <- "When I add numbers {int} and {float}"

    # Act
    result <- extract_params(input, template)

    # Assert
    expect_equal(result, list(1L, 1.1))
  })

  it("should extract custom type", {
    withr::with_options(
      define_parameter_type(
        name = "color",
        regexp = "red|green|blue",
        transformer = function(x) structure(x, class = "color")
      ), {
        # Arrange
        input <- "When I add numbers red and green"
        template <- "When I add numbers {color} and {color}"

        # Act
        result <- extract_params(input, template)

        # Assert
        expect_equal(
          result,
          list(
            structure("red", class = "color"),
            structure("green", class = "color")
          )
        )
      }
    )
  })
})
