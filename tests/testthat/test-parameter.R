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

describe("int", {
  it("should detect integers", {
    # Arrange
    x <- c("1", "-1", "+1", "10", "-10", "+10", ".1", "1.1", "a")
    int <- get_parameters()$int

    # Act
    result <- stringr::str_extract(x, int$regex)

    # Assert
    expect_equal(
      result,
      c("1", "-1", "+1", "10", "-10", "+10", NA, NA, NA)
    )
  })
})

describe("float", {
  it("should detect floats", {
    # Arrange
    x <- c(
      "+1.1", "-1.1", "1.1",
      "+11.1", "-11.1", "11.1",
      ".1",
      "+1", "-1", "1",
      "a"
    )
    param <- get_parameters()$float

    # Act
    result <- x |>
      stringr::str_subset(param$regex) |>
      param$transformer()

    # Assert
    expect_equal(
      result,
      c(
        1.1, -1.1, 1.1,
        11.1, -11.1, 11.1,
        .1
      )
    )
  })
})

describe("string", {
  it("should detect strings in single quotes", {
    # Arrange
    x <- c("'a'", "'1'", "'1.1'", "'a1'", "'1a'", "'1.1a'")
    param <- get_parameters()$string

    # Act
    result <- x |>
      stringr::str_subset(param$regex) |>
      param$transformer()

    # Assert
    expect_equal(
      result,
      c("a", "1", "1.1", "a1", "1a", "1.1a")
    )
  })

  it("should detect strings with double quotes", {
    # Arrange
    x <- c("\"a\"", "\"1\"", "\"1.1\"", "\"a1\"", "\"1a\"", "\"1.1a\"")
    param <- get_parameters()$string

    # Act
    result <- x |>
      stringr::str_subset(param$regex) |>
      param$transformer()

    # Assert
    expect_equal(
      result,
      c("a", "1", "1.1", "a1", "1a", "1.1a")
    )
  })

  it("shouldn't detect strings without single or double quotes", {
    # Arrange
    x <- c("a", "1", "1.1", "a1", "1a", "1.1a")
    param <- get_parameters()$string

    # Act
    result <- x |>
      stringr::str_subset(param$regex) |>
      param$transformer()

    # Assert
    expect_equal(result, character(0))
  })
})

describe("word", {
  it("should detect words", {
    # Arrange
    x <- c("word", "word_2", "num_1_word", "alnum.word", "1")
    param <- get_parameters()$word

    # Act
    result <- x |>
      stringr::str_subset(
        stringr::str_replace_all(param$regex, stringr::fixed("\\\\"), "\\")
      ) |>
      param$transformer()

    # Assert
    expect_equal(
      result,
      c("word", "word_2", "num_1_word", "alnum.word", "1")
    )
  })
})
