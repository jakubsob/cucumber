describe("run", {
  it("should run the feature", {
    # Arrange
    feature <- c(
      "Feature: The Maker",
      "  Scenario: The Maker has the word 'silky'",
      "    Given the Maker has the word 'silky'",
      "    When the Maker says 'hello'",
      "    Then the Maker should say 'hello'"
    )
    spies <- list(
      mockery::mock(),
      mockery::mock(),
      mockery::mock()
    )
    steps <- list(
      given("the Maker has the word '{string}'", function(word, context) {
        spies[[1]]()
        testthat::succeed()
      }),
      when("the Maker says '{string}'", function(word, context) {
        spies[[2]]()
        testthat::succeed()
      }),
      then("the Maker should say '{string}'", function(word, context) {
        spies[[3]]()
        testthat::succeed()
      })
    )
    parameters <- .parameters(
      .parameter(
        name = "string",
        regex = "[:print:]+",
        transformer = as.character
      )
    )

    # Act
    run(feature, steps, parameters)

    # Assert
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 1)
    mockery::expect_called(spies[[3]], 1)
  })
})
