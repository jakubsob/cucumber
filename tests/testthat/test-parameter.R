describe("define_parameter_type", {
  it("should add parameter to options", {
    withr::with_options(
      list(
        parameters = .parameters()
      ), {
        define_parameter_type("string", "[:print:]+", as.character)

        expect_length(getOption("parameters"), 1)
      }
    )
  })

  it("should allow adding multiple parameters to options", {
    withr::with_options(
      list(
        parameters = .parameters()
      ), {
        define_parameter_type("string", "[:print:]+", as.character)
        define_parameter_type("int", "[:digit:]+", as.integer)

        expect_length(getOption("parameters"), 2)
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
    x <- c("+1.1", "-1.1", "1.1", ".1", "+1", "-1", "1", "a")
    float <- get_parameters()$float

    # Act
    result <- stringr::str_extract(x, float$regex)

    # Assert
    expect_equal(
      result,
      c("+1.1", "-1.1", "1.1", ".1", NA, NA, NA, NA)
    )
  })
})

describe("string", {
  it("should detect strings", {
    # Arrange
    x <- c("a", "1", "1.1", "a1", "1a", "1.1a")
    string <- get_parameters()$string

    # Act
    result <- stringr::str_extract(x, string$regex)

    # Assert
    expect_equal(
      result,
      c("a", "1", "1.1", "a1", "1a", "1.1a")
    )
  })
})
