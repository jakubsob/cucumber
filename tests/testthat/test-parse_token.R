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
        type = "Step",
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
      regexp = "No step found for: \"the Maker has {string}\""
    )
  })

  it("should throw an error if duplicated step definitions have been found", {
    # Arrange
    token <- list(
      list(
        type = "Step",
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
      regexp = "Multiple steps found for: \"the Maker has \"a hat\""
    )
  })

  it("should throw an error if duplicated step definitions with different keywords have been found", {
    # Arrange
    token <- list(
      list(
        type = "Step",
        value = "the Maker has \"a hat\"",
        children = NULL,
        data = NULL
      )
    )
    steps <- list(
      given("the Maker has {string}", function(string, context) {

      }),
      when("the Maker has {string}", function(string, context) {

      })
    )
    parameters <- .parameters(
      get_parameters()$string
    )

    # Act & Assert
    expect_error(
      parse_token(token, steps, parameters),
      regexp = "Multiple steps found for: \"the Maker has \"a hat\""
    )
  })

  it("should parse a token to a call list", {
    # Arrange
    token <- list(
      list(
        type = "Step",
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
    purrr::walk(callable, \(x) x())

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
            type = "Step",
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
    purrr::walk(callable, \(x) x())

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
            type = "Step",
            value = "the Maker has the word foo and bar",
            children = NULL,
            data = NULL
          ),
          list(
            type = "Step",
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
    purrr::walk(callable, \(x) x())

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
            type = "Step",
            value = "the Maker has the word 'foo' and 'bar'",
            children = NULL,
            data = NULL
          ),
          list(
            type = "Step",
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
    purrr::walk(callable, \(x) x())

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
            type = "Step",
            value = "the Maker has the word 'foo' and bar",
            children = NULL,
            data = NULL
          ),
          list(
            type = "Step",
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
    purrr::walk(callable, \(x) x())

    # Assert
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 1)
  })

  it("should parse a Scenario Outline to a call list", {
    # Arrange
    token <- list(
      list(
        type = "Scenario Outline",
        value = "eating",
        children = list(
          list(
            type = "Step",
            value = "there are <start> cucumbers",
            children = NULL,
            data = NULL
          ),
          list(
            type = "Step",
            value = "I eat <eat> cucumbers",
            children = NULL,
            data = NULL
          ),
          list(
            type = "Step",
            value = "I should have <left> cucumbers",
            children = NULL,
            data = NULL
          ),
          list(
            type = "Scenarios",
            value = "",
            children = NULL,
            data = c("| start | eat | left |", "|    12 |   5 |    7 |", "|    20 |   5 |   15 |")
          )
        ),
        data = NULL
      )
    )
    spies <- list(mockery::mock(), mockery::mock(), mockery::mock())
    steps <- list(
      given("there are {int} cucumbers", function(start, context) {
        spies[[1]]()
        testthat::succeed()
      }),
      when("I eat {int} cucumbers", function(eat, context) {
        spies[[2]]()
        testthat::succeed()
      }),
      then("I should have {int} cucumbers", function(left, context) {
        spies[[3]]()
        testthat::succeed()
      })
    )
    parameters <- .parameters(
      get_parameters()$int
    )

    # Act
    callable <- parse_token(token, steps, parameters)
    purrr::walk(callable, \(x) x())

    # Assert
    mockery::expect_called(spies[[1]], 2)
    mockery::expect_called(spies[[2]], 2)
    mockery::expect_called(spies[[3]], 2)
  })

  it("should parse a Feature with a Background", {
    # Arrange
    tokens <- list(
      list(
        type = "Feature",
        value = "Multiple site support",
        children = list(
          list(
            type = "Background",
            value = "",
            children = list(
              list(
                type = "Step",
                value = "a global administrator named \"Greg\"",
                children = NULL,
                data = NULL
              ),
              list(
                type = "Step",
                value = "a blog named \"Greg's anti-tax rants\"",
                children = NULL,
                data = NULL
              ),
              list(
                type = "Step",
                value = "a customer named \"Dr. Bill\"",
                children = NULL,
                data = NULL
              ),
              list(
                type = "Step",
                value = "a blog named \"Expensive Therapy\" owned by \"Dr. Bill\"",
                children = NULL,
                data = NULL
              )
            ),
            data = NULL
          ),
          list(
            type = "Scenario",
            value = "Dr. Bill posts to his own blog",
            children = list(
              list(
                type = "Step",
                value = "I am logged in as \"Dr. Bill\"",
                children = NULL,
                data = NULL
              ),
              list(
                type = "Step",
                value = "I try to post to \"Expensive Therapy\"",
                children = NULL,
                data = NULL
              ),
              list(
                type = "Step",
                value = "I should see \"Your article was published.\"",
                children = NULL,
                data = NULL
              )
            ),
            data = NULL
          ),
          list(
            type = "Scenario",
            value = "Dr. Bill tries to post to somebody else's blog, and fails",
            children = list(
              list(
                type = "Step",
                value = "I am logged in as \"Dr. Bill\"",
                children = NULL,
                data = NULL
              ),
              list(
                type = "Step",
                value = "I try to post to \"Greg's anti-tax rants\"",
                children = NULL,
                data = NULL
              ),
              list(
                type = "Step",
                value = "I should see \"Hey! That's not your blog!\"",
                children = NULL,
                data = NULL
              )
            ),
            data = NULL
          )
        ),
        data = c("Only blog owners can post to a blog, except administrators,", "who can post to all blogs.")
      )
    )
    spies <- list(mockery::mock(), mockery::mock(), mockery::mock(), mockery::mock(), mockery::mock(), mockery::mock(), mockery::mock())
    steps <- list(
      given("a global administrator named {string}", function(name, context) {
        spies[[1]]()
        testthat::succeed()
      }),
      given("a blog named {string}", function(name, context) {
        spies[[2]]()
        testthat::succeed()
      }),
      given("a customer named {string}", function(name, context) {
        spies[[3]]()
        testthat::succeed()
      }),
      given("a blog named {string} owned by {string}", function(blog_name, owner_name, context) {
        spies[[4]]()
        testthat::succeed()
      }),
      when("I am logged in as {string}", function(name, context) {
        testthat::succeed()
      }),
      when("I try to post to {string}", function(blog_name, context) {
        testthat::succeed()
      }),
      then("I should see {string}", function(message, context) {
        testthat::succeed()
      })
    )
    parameters <- .parameters(
      get_parameters()$string
    )

    # Act
    callable <- parse_token(tokens, steps, parameters)
    purrr::walk(callable, \(x) x())

    # Assert
    mockery::expect_called(spies[[1]], 2)
    mockery::expect_called(spies[[2]], 2)
    mockery::expect_called(spies[[3]], 2)
    mockery::expect_called(spies[[4]], 2)
  })

  it("should parse a Feature with Background and Scenario Outline", {
    # Arrange
    tokens <- list(
      list(
        type = "Feature",
        value = "Multiple site support",
        children = list(
          list(
            type = "Background",
            value = "",
            children = list(
              list(
                type = "Step",
                value = "a global administrator named <admin>",
                children = NULL,
                data = NULL
              )
            ),
            data = NULL
          ),
          list(
            type = "Scenario Outline",
            value = "Dr. Bill posts to his own blog",
            children = list(
              list(
                type = "Step",
                value = "I am logged in as <user>",
                children = NULL,
                data = NULL
              ),
              list(
                type = "Step",
                value = "I try to post to <blog>",
                children = NULL,
                data = NULL
              ),
              list(
                type = "Scenarios",
                value = "",
                children = NULL,
                data = c("| admin | user | blog |", "| 'Greg' | 'Dr. Bill' | 'Expensive Therapy' |", "| 'John' | 'Dr. Bill' | \"Greg's anti-tax rants\" |")
              )
            ),
            data = NULL
          )
        )
      )
    )
    spies <- list(mockery::mock(), mockery::mock(), mockery::mock())
    steps <- list(
      given("a global administrator named {string}", function(admin, context) {
        spies[[1]]()
        testthat::succeed()
      }),
      when("I am logged in as {string}", function(user, context) {
        spies[[2]]()
        testthat::succeed()
      }),
      when("I try to post to {string}", function(blog, context) {
        spies[[3]]()
        testthat::succeed()
      })
    )
    parameters <- .parameters(
      get_parameters()$string
    )

    # Act
    callable <- parse_token(tokens, steps, parameters)
    purrr::walk(callable, \(x) x())

    # Assert
    mockery::expect_called(spies[[1]], 2)
    mockery::expect_called(spies[[2]], 2)
    mockery::expect_called(spies[[3]], 2)
  })
})
