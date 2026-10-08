describe("define_parameter_type", {
  it("should add parameter to options", {
    withr::with_options(
      list2(!!getOption(".cucumber_parameters_option") := .parameters()),
      {
        define_parameter_type("string", "[:print:]+", as.character)

        expect_length(get_parameters(), 1)
      }
    )
  })

  it("should allow adding multiple parameters to options", {
    withr::with_options(
      list2(!!getOption(".cucumber_parameters_option") := .parameters()),
      {
        define_parameter_type("string", "[:print:]+", as.character)
        define_parameter_type("int", "[:digit:]+", as.integer)

        expect_length(get_parameters(), 2)
      }
    )
  })
})

# Match a step against one parameter and return the value passed to the step
# with the parameters registered by `local_steps()`
match_parameter <- function(text, expression) {
  withr::local_options(test_steps = NULL)
  given(expression, function(value, context) {})
  step <- new_pickle_step(keyword = "Given", type = "Context", text = text)
  matched <- match_single_step(step)
  if (identical(matched$status, "undefined")) return(NULL)
  matched$arguments()[[1]]
}

describe("int", {
  local_steps()

  it("should match integers like Cucumber Expressions", {
    expect_identical(match_parameter("1", "{int}"), 1L)
    expect_identical(match_parameter("-10", "{int}"), -10L)
    expect_null(match_parameter("+1", "{int}"))
    expect_null(match_parameter("1.1", "{int}"))
    expect_null(match_parameter(".1", "{int}"))
  })

  it("should fail on an integer out of R's integer range", {
    expect_error(match_parameter("3000000000", "{int}"), "out of range")
  })
})

describe("float", {
  local_steps()

  it("should match floats and integers", {
    x <- c("+1.1", "-1.1", "1.1", ".1", "+1", "-1", "1", "1.5E3")

    result <- vapply(x, \(x) match_parameter(x, "{float}"), numeric(1), USE.NAMES = FALSE)

    expect_equal(result, c(1.1, -1.1, 1.1, .1, 1, -1, 1, 1500))
  })
})

describe("string", {
  local_steps()

  it("should match strings in single or double quotes and remove the quotes", {
    expect_identical(match_parameter("'a b'", "{string}"), "a b")
    expect_identical(match_parameter('"a b"', "{string}"), "a b")
    expect_identical(match_parameter('""', "{string}"), "")
    expect_null(match_parameter("a", "{string}"))
  })

  it("should unescape escaped quotes", {
    expect_identical(match_parameter('"say \\"hi\\""', "{string}"), 'say "hi"')
    expect_identical(match_parameter("'it\\'s'", "{string}"), "it's")
  })
})

describe("word", {
  local_steps()

  it("should match anything without whitespace", {
    expect_identical(match_parameter("foo-bar", "{word}"), "foo-bar")
    expect_identical(match_parameter("alnum.word", "{word}"), "alnum.word")
    expect_null(match_parameter("banana split", "{word}"))
  })
})

describe("custom parameter types", {
  it("should use the regexp as is", {
    local_steps()
    define_parameter_type("version", "\\d+\\.\\d+", as.character)

    expect_identical(match_parameter("1.2", "{version}"), "1.2")
  })

  it("should pass the text of each capture group to the transformer", {
    local_steps()
    define_parameter_type("point", "(\\d+),(\\d+)", \(x, y) as.integer(c(x, y)))

    expect_identical(match_parameter("1,2", "{point}"), c(1L, 2L))
  })
})
