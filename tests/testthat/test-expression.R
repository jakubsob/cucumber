describe("expression_to_pattern", {
  parameters <- .parameters(
    string = .parameter(
      name = "string",
      regexp = "[^\"]*",
      transformer = as.character
    )
  )

  it("should convert an expression to a pattern that detects parameters", {
    # Act
    result <- expression_to_pattern("word {string} word", parameters)

    # Assert
    expect_equal(c(result), "^word ([^\"]*) word$")
    expect_equal(attr(result, "parameters")[[1]]$name, "string")
  })

  it("should make text in parentheses optional", {
    expect_equal(c(expression_to_pattern("cucumber(s)", parameters)), "^cucumber(?:s)?$")
  })

  it("should convert words separated by a slash to alternatives", {
    expect_equal(
      c(expression_to_pattern("the Enter/Return key", parameters)),
      "^the (?:Enter|Return) key$"
    )
  })

  it("should keep an escaped space inside an alternative", {
    expect_equal(
      c(expression_to_pattern("I live in New\\ York/Boston", parameters)),
      "^I live in (?:New York|Boston)$"
    )
  })

  it("should match anything with an anonymous parameter", {
    result <- expression_to_pattern("I am {}", parameters)

    expect_equal(c(result), "^I am (.*)$")
    expect_equal(attr(result, "parameters")[[1]]$name, "")
  })

  it("should match regex special characters literally", {
    expect_equal(c(expression_to_pattern("Is it 5.0? $[x]+", parameters)), "^Is it 5\\.0\\? \\$\\[x\\]\\+$")
  })

  it("should match escaped characters literally", {
    expect_equal(
      c(expression_to_pattern("\\(a\\) \\{b\\} c\\/d \\\\", parameters)),
      "^\\(a\\) \\{b\\} c/d \\\\$"
    )
  })

  it("should use a parameter type's regexp as is", {
    parameters <- .parameters(
      number = .parameter(name = "number", regexp = "\\d+", transformer = as.integer)
    )

    expect_equal(c(expression_to_pattern("{number}", parameters)), "^(\\d+)$")
  })

  it("should match any of a parameter type's regexps", {
    parameters <- .parameters(
      yes = .parameter(name = "yes", regexp = c("yes", "y"), transformer = as.character)
    )

    expect_equal(c(expression_to_pattern("{yes}", parameters)), "^((?:yes)|(?:y))$")
  })

  it("should fail on an undefined parameter type", {
    expect_snapshot(expression_to_pattern("I like {color}", parameters), error = TRUE)
  })

  it("should fail on invalid expressions like Cucumber Expressions", {
    expect_snapshot(expression_to_pattern("three ((very) blind) mice", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("I have ({string})", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("I have ()", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("I visit /about", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("a//b", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("{string}/{string}", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("I have (a/b)", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("I have (a)/b", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("I have {string", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("I have (s", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("I have {a(b}", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("I have \\a", parameters), error = TRUE)
    expect_snapshot(expression_to_pattern("I have \\", parameters), error = TRUE)
  })

  it("should use a description starting with ^ or ending with $ as a regular expression", {
    expect_equal(c(expression_to_pattern("^I have (\\d+)", parameters)), "^I have (\\d+)")
    expect_equal(c(expression_to_pattern("I (.*)$", parameters)), "I (.*)$")
  })

  it("should use a description surrounded by slashes as a regular expression", {
    expect_equal(c(expression_to_pattern("/I have (\\d+)/", parameters)), "I have (\\d+)")
  })

  it("should give a regular expression's capture group the parameter type with the same regexp", {
    parameters <- get_parameters()

    result <- expression_to_pattern("^I have (\\d+) (.*) and (.*?)$", parameters)

    types <- vapply(attr(result, "parameters"), \(p) p$name, character(1))
    expect_equal(types, c("int", "", ".*?"))
  })

  it("should fail when a capture group's regexp is the regexp of several parameter types", {
    parameters <- .parameters(
      a = .parameter(name = "a", regexp = "\\d+", transformer = as.integer),
      b = .parameter(name = "b", regexp = "\\d+", transformer = as.integer)
    )

    expect_snapshot(expression_to_pattern("^(\\d+)$", parameters), error = TRUE)
  })
})

describe("regex_groups", {
  it("should list capture groups with the group they are nested in", {
    result <- regex_groups("^a (b(c)) (?:d(e)) [(] (?<n>f) (?=g) \\(h\\)$")

    expect_equal(result$parent, c(0, 1, 0, 0))
    expect_equal(result$source, c("b(c)", "c", "e", "?<n>f"))
  })
})
