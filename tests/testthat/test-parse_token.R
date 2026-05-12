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

  it("should include a snippet in the error message when no step is found", {
    # Arrange
    token <- list(
      list(type = "Step", value = "I have 5 cucumbers", children = NULL, data = NULL)
    )

    # Act — rlang merges body into conditionMessage
    err <- tryCatch(parse_token(token, .steps(), get_parameters()), error = function(e) e)

    # Assert
    expect_true(grepl('given("I have {int} cucumbers"', err$message, fixed = TRUE))
    expect_true(grepl("function(int, context)", err$message, fixed = TRUE))
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
      }),
      given("a blog named {string}", function(name, context) {
        spies[[2]]()
      }),
      given("a customer named {string}", function(name, context) {
        spies[[3]]()
      }),
      given(
        "a blog named {string} owned by {string}",
        function(blog_name, owner_name, context) {
          spies[[4]]()
        }
      ),
      when("I am logged in as {string}", function(name, context) {}),
      when("I try to post to {string}", function(blog_name, context) {}),
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

  it("should run only scenarios matching the tags filter", {
    # Arrange
    spies <- list(mockery::mock(), mockery::mock())
    steps <- list(
      given("a step", function(context) {
        spies[[1]]()
        testthat::succeed()
      }),
      given("another step", function(context) {
        spies[[2]]()
        testthat::succeed()
      })
    )
    parameters <- .parameters(get_parameters()$string)
    tokens <- list(
      list(
        type = "Feature",
        value = "My Feature",
        tags = character(0),
        children = list(
          list(
            type = "Scenario",
            value = "smoke scenario",
            tags = c("smoke"),
            children = list(
              list(type = "Step", value = "a step", children = NULL, data = NULL)
            ),
            data = NULL
          ),
          list(
            type = "Scenario",
            value = "wip scenario",
            tags = c("wip"),
            children = list(
              list(type = "Step", value = "another step", children = NULL, data = NULL)
            ),
            data = NULL
          )
        ),
        data = NULL
      )
    )

    # Act — filter to @smoke only
    callable <- parse_token(tokens, steps, parameters, tags = c("smoke"))
    purrr::walk(callable, \(x) x())

    # Assert
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 0)
  })

  it("should run all scenarios when tags filter is NULL", {
    # Arrange
    spies <- list(mockery::mock(), mockery::mock())
    steps <- list(
      given("a step", function(context) {
        spies[[1]]()
        testthat::succeed()
      }),
      given("another step", function(context) {
        spies[[2]]()
        testthat::succeed()
      })
    )
    parameters <- .parameters(get_parameters()$string)
    tokens <- list(
      list(
        type = "Feature",
        value = "My Feature",
        tags = character(0),
        children = list(
          list(
            type = "Scenario",
            value = "smoke scenario",
            tags = c("smoke"),
            children = list(
              list(type = "Step", value = "a step", children = NULL, data = NULL)
            ),
            data = NULL
          ),
          list(
            type = "Scenario",
            value = "untagged scenario",
            tags = character(0),
            children = list(
              list(type = "Step", value = "another step", children = NULL, data = NULL)
            ),
            data = NULL
          )
        ),
        data = NULL
      )
    )

    # Act — no tag filter
    callable <- parse_token(tokens, steps, parameters, tags = NULL)
    purrr::walk(callable, \(x) x())

    # Assert — both scenarios run
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 1)
  })

  it("should propagate Feature tags to child Scenarios", {
    # Arrange
    spy <- mockery::mock()
    steps <- list(
      given("a step", function(context) {
        spy()
        testthat::succeed()
      })
    )
    parameters <- .parameters(get_parameters()$string)
    tokens <- list(
      list(
        type = "Feature",
        value = "Smoke Suite",
        tags = c("smoke"),
        children = list(
          list(
            type = "Scenario",
            value = "scenario inherits feature tag",
            tags = character(0),
            children = list(
              list(type = "Step", value = "a step", children = NULL, data = NULL)
            ),
            data = NULL
          )
        ),
        data = NULL
      )
    )

    # Act — filter by @smoke; scenario has no own tags but Feature does
    callable <- parse_token(tokens, steps, parameters, tags = c("smoke"))
    purrr::walk(callable, \(x) x())

    # Assert — scenario ran because Feature tag propagated
    mockery::expect_called(spy, 1)
  })

  it("should run scenarios matching any of multiple tags (OR logic)", {
    # Arrange
    spies <- list(mockery::mock(), mockery::mock(), mockery::mock())
    steps <- list(
      given("step one", function(context) { spies[[1]](); testthat::succeed() }),
      given("step two", function(context) { spies[[2]](); testthat::succeed() }),
      given("step three", function(context) { spies[[3]](); testthat::succeed() })
    )
    parameters <- .parameters(get_parameters()$string)
    tokens <- list(
      list(
        type = "Feature",
        value = "My Feature",
        tags = character(0),
        children = list(
          list(
            type = "Scenario",
            value = "smoke scenario",
            tags = c("smoke"),
            children = list(
              list(type = "Step", value = "step one", children = NULL, data = NULL)
            ),
            data = NULL
          ),
          list(
            type = "Scenario",
            value = "fast scenario",
            tags = c("fast"),
            children = list(
              list(type = "Step", value = "step two", children = NULL, data = NULL)
            ),
            data = NULL
          ),
          list(
            type = "Scenario",
            value = "slow scenario",
            tags = c("slow"),
            children = list(
              list(type = "Step", value = "step three", children = NULL, data = NULL)
            ),
            data = NULL
          )
        ),
        data = NULL
      )
    )

    # Act — filter to @smoke OR @fast
    callable <- parse_token(tokens, steps, parameters, tags = c("smoke", "fast"))
    purrr::walk(callable, \(x) x())

    # Assert — smoke and fast ran, slow did not
    mockery::expect_called(spies[[1]], 1)
    mockery::expect_called(spies[[2]], 1)
    mockery::expect_called(spies[[3]], 0)
  })
})

describe("format_step_snippet", {
  it("should generate a snippet with no args for a plain step", {
    result <- format_step_snippet("I log in", get_parameters())
    expect_true(grepl('given("I log in", function(context)', result, fixed = TRUE))
  })

  it("should detect an int and replace it with a placeholder", {
    result <- format_step_snippet("I have 5 cucumbers", get_parameters())
    expect_true(grepl('given("I have {int} cucumbers", function(int, context)', result, fixed = TRUE))
  })

  it("should detect a float and replace it with a placeholder", {
    result <- format_step_snippet("the price is 3.99", get_parameters())
    expect_true(grepl('given("the price is {float}", function(float, context)', result, fixed = TRUE))
  })

  it("should detect a quoted string and replace it with a placeholder", {
    result <- format_step_snippet('I see "hello world"', get_parameters())
    expect_true(grepl('given("I see {string}", function(string, context)', result, fixed = TRUE))
  })

  it("should number duplicate parameter types", {
    result <- format_step_snippet("I have 5 and 10 items", get_parameters())
    expect_true(grepl("function(int_1, int_2, context)", result, fixed = TRUE))
  })

  it("should prefer string over int for quoted numbers", {
    result <- format_step_snippet('I have "5" items', get_parameters())
    expect_true(grepl('given("I have {string} items", function(string, context)', result, fixed = TRUE))
  })

  it("should include pending() in the snippet body", {
    result <- format_step_snippet("I log in", get_parameters())
    expect_true(grepl("pending()", result, fixed = TRUE))
  })
})
