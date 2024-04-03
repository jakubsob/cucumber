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
      given("the Maker has the word {string}", function(word, context) {
        spies[[1]]()
      })
    )
    parameters <- .parameters(
      get_parameters()$string
    )

    # Act & Assert
    expect_error(
      parse_token(token, steps, parameters),
      regexp = "Unknown token type: Unknown"
    )
  })

  it("should throw an error if no step definition has been found", {
    # Arrange
    token <- list(
      list(
        type = "Given",
        value = "the Maker has {string}",
        children = NULL,
        data = NULL
      )
    )
    steps <- list(
      given("the Maker has the word {string}", function(word, context) {
        spies[[1]]()
      })
    )
    parameters <- .parameters(
      get_parameters()$string
    )

    # Act & Assert
    expect_error(
      parse_token(token, steps, parameters),
      fixed = TRUE,
      regexp = "No step found for: \"Given the Maker has {string}\""
    )
  })

  it("should throw an error if duplicated step definitions have been found", {
    # Arrange
    token <- list(
      list(
        type = "Given",
        value = "the Maker has \"a hat\"",
        children = NULL,
        data = NULL
      )
    )
    steps <- list(
      given("the Maker has {string}", function(string, context) {

      }),
      given("the Maker has {string}", function(string, context) {

      })
    )
    parameters <- .parameters(
      get_parameters()$string
    )

    # Act & Assert
    expect_error(
      parse_token(token, steps, parameters),
      regexp = "Multiple steps found for: \"Given the Maker has \"a hat\""
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
      given("the Maker has the word {string} and number {int}", function(word, number, context) {
        spies[[1]]()
      }),
      given("the Breaker joins the Maker's game", function(context) {
        spies[[2]]()
      })
    )
    parameters <- .parameters(
      get_parameters()$string,
      get_parameters()$int
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
      given("the Maker has the word {string} and number {int}", function(word, number, context) {
        spies[[1]]()
        testthat::succeed()
      }),
      given("the Breaker joins the Maker's game", function(context) {
        spies[[2]]()
      })
    )
    parameters <- .parameters(
      get_parameters()$string,
      get_parameters()$int
    )

    # Act
    callable <- parse_token(token, steps, parameters)
    purrr::walk(callable, eval)

    # Assert
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 0)
  })

  it("should parse a step with multiple words", {
    # Arrange
    token <- list(
      list(
        type = "Scenario",
        value = "the test scenario with 1 step",
        data = NULL,
        children = list(
          list(
            type = "Given",
            value = "the Maker has the word foo and bar",
            children = NULL,
            data = NULL
          ),
          list(
            type = "Given",
            value = "the Maker has the word foo",
            children = NULL,
            data = NULL
          )
        )
      )
    )
    spies <- list(mockery::mock(), mockery::mock())
    steps <- list(
      given("the Maker has the word {word} and {word}", function(word_1, word_2, context) {
        spies[[1]]()
        testthat::succeed()
      }),
      given("the Maker has the word {word}", function(word, context) {
        spies[[2]]()
        testthat::succeed()
      })
    )
    parameters <- .parameters(
      get_parameters()$string,
      get_parameters()$word
    )

    # Act
    callable <- parse_token(token, steps, parameters)
    purrr::walk(callable, eval)

    # Assert
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 1)
  })

  it("should parse a step with multiple strings", {
    # Arrange
    token <- list(
      list(
        type = "Scenario",
        value = "the test scenario with 1 step",
        data = NULL,
        children = list(
          list(
            type = "Given",
            value = "the Maker has the word 'foo' and 'bar'",
            children = NULL,
            data = NULL
          ),
          list(
            type = "Given",
            value = "the Maker has the word 'foo'",
            children = NULL,
            data = NULL
          )
        )
      )
    )
    spies <- list(mockery::mock(), mockery::mock())
    steps <- list(
      given("the Maker has the word {string} and {string}", function(string_1, string_2, context) {
        spies[[1]]()
        testthat::succeed()
      }),
      given("the Maker has the word {string}", function(string, context) {
        spies[[2]]()
        testthat::succeed()
      })
    )
    parameters <- .parameters(
      get_parameters()$string
    )

    # Act
    callable <- parse_token(token, steps, parameters)
    purrr::walk(callable, eval)

    # Assert
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 1)
  })

  it("should parse a step with string and a word", {
    # Arrange
    token <- list(
      list(
        type = "Scenario",
        value = "the test scenario with 1 step",
        data = NULL,
        children = list(
          list(
            type = "Given",
            value = "the Maker has the word 'foo' and bar",
            children = NULL,
            data = NULL
          ),
          list(
            type = "Given",
            value = "the Maker has the word 'foo bar'",
            children = NULL,
            data = NULL
          )
        )
      )
    )
    spies <- list(mockery::mock(), mockery::mock())
    steps <- list(
      given("the Maker has the word {string} and {word}", function(string, word, context) {
        spies[[1]]()
        testthat::succeed()
      }),
      given("the Maker has the word {string}", function(string, context) {
        spies[[2]]()
        testthat::succeed()
      })
    )
    parameters <- .parameters(
      get_parameters()$string,
      get_parameters()$word
    )

    # Act
    callable <- parse_token(token, steps, parameters)
    purrr::walk(callable, eval)

    # Assert
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 1)
  })
})
