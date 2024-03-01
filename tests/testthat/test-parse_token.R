describe("parse_token", {
  it("should throw an error if the token type is unknown", {
    # Arrange
    token <- list(
      list(
        type = "Unknown",
        value = "the Maker has the word 'silky'",
        children = NULL,
        data = NULL
      )
    )
    steps <- list(
      given("the Maker has the word '{string}'", function(word, context) {
        spies[[1]]()
      })
    )
    parameters <- .parameters(
      .parameter(
        name = "string",
        regex = "[:print:]+",
        transformer = as.character
      )
    )

    # Act & Assert
    expect_error(
      parse_token(token, steps, parameters),
      regexp = "Unknown token type: Unknown"
    )
  })

  it("should throw an arror if no step definition has been found", {
    # Arrange
    token <- list(
      list(
        type = "Given",
        value = "the Maker has '{string}'",
        children = NULL,
        data = NULL
      )
    )
    steps <- list(
      given("the Maker has the word '{string}'", function(word, context) {
        spies[[1]]()
      })
    )
    parameters <- .parameters(
      .parameter(
        name = "string",
        regex = "[:print:]+",
        transformer = as.character
      )
    )

    # Act & Assert
    expect_error(
      parse_token(token, steps, parameters),
      regexp = "No step found for: Given the Maker has '\\{string\\}'"
    )
  })

  it("should throw an error if multiple step definitions have been found", {
    # Arrange
    token <- list(
      list(
        type = "Given",
        value = "the Maker has the word 'silky'",
        children = NULL,
        data = NULL
      )
    )
    steps <- list(
      given("the Maker has the word '{string}'", function(word, context) {
        spies[[1]]()
      }),
      given("the Maker has the word '{string}'", function(word, context) {
        spies[[2]]()
      })
    )
    parameters <- .parameters(
      .parameter(
        name = "string",
        regex = "[:print:]+",
        transformer = as.character
      )
    )

    # Act & Assert
    expect_error(
      parse_token(token, steps, parameters),
      regexp = "Multiple steps found for: Given the Maker has the word 'silky'"
    )
  })

  it("should parse a token to a call list", {
    # Arrange
    token <- list(
      list(
        type = "Given",
        value = "the Maker has the word 'silky' and number 44",
        children = NULL,
        data = NULL
      )
    )
    spies <- list(mockery::mock(), mockery::mock())
    steps <- list(
      given("the Maker has the word '{string}' and number {int}", function(word, number, context) {
        spies[[1]]()
      }),
      given("the Breaker joins the Maker's game", function(context) {
        spies[[2]]()
      })
    )
    parameters <- .parameters(
      .parameter(
        name = "string",
        regex = "[:print:]+",
        transformer = as.character
      ),
      .parameter(
        name = "int",
        regex = "[0-9]+",
        transformer = as.integer
      )
    )

    # Act
    callable <- parse_token(token, steps, parameters)
    eval(callable[[1]])

    # Assert
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 0)
  })

  it("should parse a Scenario to a call list", {
    # Arrange
    token <- list(
      list(
        type = "Scenario",
        value = "the test scenario with 1 step",
        data = NULL,
        children = list(
          list(
            type = "Given",
            value = "the Maker has the word 'silky' and number 44",
            children = NULL,
            data = NULL
          )
        )
      )
    )
    spies <- list(mockery::mock(), mockery::mock())
    steps <- list(
      given("the Maker has the word '{string}' and number {int}", function(word, number, context) {
        spies[[1]]()
        testthat::succeed()
      }),
      given("the Breaker joins the Maker's game", function(context) {
        spies[[2]]()
      })
    )
    parameters <- .parameters(
      .parameter(
        name = "string",
        regex = "[:print:]+",
        transformer = as.character
      ),
      .parameter(
        name = "int",
        regex = "[0-9]+",
        transformer = as.integer
      )
    )

    # Act
    callable <- parse_token(token, steps, parameters)
    purrr::walk(callable, eval)

    # Assert
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 0)
  })
})
