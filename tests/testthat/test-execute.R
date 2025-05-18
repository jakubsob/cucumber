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
      given("the Maker has the word {string}", function(word, context) {
        spies[[1]]()
        testthat::succeed()
      }),
      when("the Maker says {string}", function(word, context) {
        spies[[2]]()
        testthat::succeed()
      }),
      then("the Maker should say {string}", function(word, context) {
        spies[[3]]()
        testthat::succeed()
      })
    )
    parameters <- .parameters(
      .parameter(
        name = "string",
        regex = "'[:print:]+'",
        transformer = as.character
      )
    )

    # Act
    execute(feature, steps, parameters)

    # Assert
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 1)
    mockery::expect_called(spies[[3]], 1)
  })

  it("should run scenarios with hooks", {
    # Arrange
    feature <- c(
      "Feature: The Maker",
      "  Scenario: The Maker has the word 'silky'",
      "    Given the Maker has the word 'silky'",
      "    When the Maker says 'hello'",
      "    Then the Maker should say 'hello'",
      "",
      "  Scenario: The Maker has the word 'smooth'",
      "    Given the Maker has the word 'smooth'",
      "    When the Maker says 'hello'",
      "    Then the Maker should say 'hello'"
    )
    spies <- list(
      before = mockery::mock(),
      after = mockery::mock()
    )
    steps <- list(
      given("the Maker has the word {string}", function(word, context) {
        testthat::succeed()
      }),
      when("the Maker says {string}", function(word, context) {
        testthat::succeed()
      }),
      then("the Maker should say {string}", function(word, context) {
        testthat::succeed()
      })
    )
    hooks <- list(
      before = function(context, name) {
        spies$before(name)
      },
      after = function(context, name) {
        spies$after(name)
      }
    )
    parameters <- .parameters(
      .parameter(
        name = "string",
        regex = "'[:print:]+'",
        transformer = as.character
      )
    )

    # Act
    execute(feature, steps, parameters, hooks)

    # Assert
    mockery::expect_called(spies$before, 2)
    mockery::expect_called(spies$after, 2)
    expect_equal(mockery::mock_args(spies$before)[[1]][[1]], "The Maker has the word 'silky'")
    expect_equal(mockery::mock_args(spies$before)[[2]][[1]], "The Maker has the word 'smooth'")
    expect_equal(mockery::mock_args(spies$after)[[1]][[1]], "The Maker has the word 'silky'")
    expect_equal(mockery::mock_args(spies$after)[[2]][[1]], "The Maker has the word 'smooth'")
  })
})
