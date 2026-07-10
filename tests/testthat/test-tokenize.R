describe("tokenize", {
  it("should tokenize feature string into a list of scenarios", {
    # Arrange
    lines <- c(
      "Feature: Guess the word",
      "",
      "  Scenario: Maker starts a game",
      "    When the Maker starts a game",
      "    Then the Maker waits for a Breaker to join",
      "  Scenario: Breaker joins a game",
      "    Given the Maker has started a game with the word 'silky'",
      "    When the Breaker joins the Maker's game",
      "    Then the Breaker must guess a word with 5 characters"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Feature",
          value = "Guess the word",
          tags = character(0),
          children = list(
            new_token(
              type = "Scenario",
              value = "Maker starts a game",
              tags = character(0),
              children = list(
                new_token(
                  type = "When",
                  value = "the Maker starts a game",
                  data = NULL
                ),
                new_token(
                  type = "Then",
                  value = "the Maker waits for a Breaker to join",
                  data = NULL
                )
              ),
              data = NULL
            ),
            new_token(
              type = "Scenario",
              value = "Breaker joins a game",
              tags = character(0),
              children = list(
                new_token(
                  type = "Given",
                  value = "the Maker has started a game with the word 'silky'",
                  data = NULL
                ),
                new_token(
                  type = "When",
                  value = "the Breaker joins the Maker's game",
                  data = NULL
                ),
                new_token(
                  type = "Then",
                  value = "the Breaker must guess a word with 5 characters",
                  data = NULL
                )
              ),
              data = NULL
            )
          ),
          data = NULL
        )
      )
    )
  })

  it("should ignore comments and newlines", {
    # Arrange
    lines <- c(
      "# This is a comment",
      "",
      "Feature: Guess the word",
      "",
      "",
      "  # The first example has two steps",
      "  Scenario: Maker starts a game",
      "",
      "",
      "",
      "    When the Maker starts a game",
      "",
      "    # This is a Then step",
      "    Then the Maker waits for a Breaker to join",
      "",
      "  # The second example has three steps",
      ""
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Feature",
          value = "Guess the word",
          tags = character(0),
          children = list(
            new_token(
              type = "Scenario",
              value = "Maker starts a game",
              tags = character(0),
              children = list(
                new_token(
                  type = "When",
                  value = "the Maker starts a game",
                  data = NULL
                ),
                new_token(
                  type = "Then",
                  value = "the Maker waits for a Breaker to join",
                  data = NULL
                )
              ),
              data = NULL
            )
          ),
          data = NULL
        )
      )
    )
  })

  it("should tokenize a feature with Background", {
    # Arrange
    lines <- c(
      "Feature: Multiple site support",
      "",
      "  Background:",
      "",
      "    Given a global administrator named \"Greg\"",
      "    And a blog named \"Greg's anti-tax rants\"",
      "    And a customer named \"Dr. Bill\"",
      "    And a blog named \"Expensive Therapy\" owned by \"Dr. Bill\"",
      "",
      "  Scenario: Dr. Bill posts to his own blog",
      "    Given I am logged in as Dr. Bill",
      "    When I try to post to \"Expensive Therapy\"",
      "    Then I should see \"Your article was published.\"",
      "",
      "  Scenario: Dr. Bill tries to post to somebody else's blog, and fails",
      "    Given I am logged in as Dr. Bill",
      "    When I try to post to \"Greg's anti-tax rants\"",
      "    Then I should see \"Hey! That's not your blog!\""
    )

    # Act
    result <- tokenize(lines)

    expect_equal(
      result,
      list(
        new_token(
          type = "Feature",
          value = "Multiple site support",
          tags = character(0),
          children = list(
            new_token(
              type = "Background",
              value = "",
              tags = character(0),
              children = list(
                new_token(
                  type = "Given",
                  value = "a global administrator named \"Greg\"",
                  data = NULL
                ),
                new_token(
                  type = "Given",
                  value = "a blog named \"Greg's anti-tax rants\"",
                  data = NULL
                ),
                new_token(
                  type = "Given",
                  value = "a customer named \"Dr. Bill\"",
                  data = NULL
                ),
                new_token(
                  type = "Given",
                  value = "a blog named \"Expensive Therapy\" owned by \"Dr. Bill\"",
                  data = NULL
                )
              ),
              data = NULL
            ),
            new_token(
              type = "Scenario",
              value = "Dr. Bill posts to his own blog",
              tags = character(0),
              children = list(
                new_token(
                  type = "Given",
                  value = "I am logged in as Dr. Bill",
                  data = NULL
                ),
                new_token(
                  type = "When",
                  value = "I try to post to \"Expensive Therapy\"",
                  data = NULL
                ),
                new_token(
                  type = "Then",
                  value = "I should see \"Your article was published.\"",
                  data = NULL
                )
              ),
              data = NULL
            ),
            new_token(
              type = "Scenario",
              value = "Dr. Bill tries to post to somebody else's blog, and fails",
              tags = character(0),
              children = list(
                new_token(
                  type = "Given",
                  value = "I am logged in as Dr. Bill",
                  data = NULL
                ),
                new_token(
                  type = "When",
                  value = "I try to post to \"Greg's anti-tax rants\"",
                  data = NULL
                ),
                new_token(
                  type = "Then",
                  value = "I should see \"Hey! That's not your blog!\"",
                  data = NULL
                )
              ),
              data = NULL
            )
          ),
          data = NULL
        )
      )
    )
  })

  it("should tokenize Scenario Outline", {
    # Arrange
    lines <- c(
      "Scenario Outline: eating",
      "  Given there are <start> cucumbers",
      "  When I eat <eat> cucumbers",
      "  Then I should have <left> cucumbers",
      "  Examples:",
      "    | start | eat | left |",
      "    |    12 |   5 |    7 |",
      "    |    20 |   5 |   15 |"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Scenario Outline",
          value = "eating",
          tags = character(0),
          children = list(
            new_token(
              type = "Given",
              value = "there are <start> cucumbers",
              data = NULL
            ),
            new_token(
              type = "When",
              value = "I eat <eat> cucumbers",
              data = NULL
            ),
            new_token(
              type = "Then",
              value = "I should have <left> cucumbers",
              data = NULL
            ),
            new_token(
              type = "Scenarios",
              value = "",
              tags = character(0),
              data = c(
                "| start | eat | left |",
                "|    12 |   5 |    7 |",
                "|    20 |   5 |   15 |"
              )
            )
          ),
          data = NULL
        )
      )
    )
  })

  it("should tokenize docstring with triple quote marks", {
    # Arrange
    lines <- c(
      "Scenario: blog",
      "  Given a blog post named \"Random\" with Markdown body",
      "    \"\"\"",
      "    Some Title, Eh?",
      "    ===============",
      "    Here is the first paragraph of my blog post. Lorem ipsum dolor sit amet,",
      "    consectetur adipiscing elit.",
      "    \"\"\""
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Scenario",
          value = "blog",
          tags = character(0),
          children = list(
            new_token(
              type = "Given",
              value = "a blog post named \"Random\" with Markdown body",
              data = c(
                "\"\"\"",
                "Some Title, Eh?",
                "===============",
                "Here is the first paragraph of my blog post. Lorem ipsum dolor sit amet,",
                "consectetur adipiscing elit.",
                "\"\"\""
              )
            )
          ),
          data = NULL
        )
      )
    )
  })

  it("should tokenize docstring with triple single-quotes", {
    # Arrange
    lines <- c(
      "Scenario: blog",
      "  Given a blog post named \"Random\" with Markdown body",
      "    '''",
      "    Some Title, Eh?",
      "    ===============",
      "    Here is the first paragraph of my blog post. Lorem ipsum dolor sit amet,",
      "    consectetur adipiscing elit.",
      "    '''"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Scenario",
          value = "blog",
          tags = character(0),
          children = list(
            new_token(
              type = "Given",
              value = "a blog post named \"Random\" with Markdown body",
              data = c(
                "'''",
                "Some Title, Eh?",
                "===============",
                "Here is the first paragraph of my blog post. Lorem ipsum dolor sit amet,",
                "consectetur adipiscing elit.",
                "'''"
              )
            )
          ),
          data = NULL
        )
      )
    )
  })

  it("should tokenize docstring with backticks", {
    # Arrange
    lines <- c(
      "Scenario: blog",
      "  Given a blog post named \"Random\" with Markdown body",
      "    ```",
      "    Some Title, Eh?",
      "    ===============",
      "    Here is the first paragraph of my blog post. Lorem ipsum dolor sit amet,",
      "    consectetur adipiscing elit.",
      "    ```"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Scenario",
          value = "blog",
          tags = character(0),
          children = list(
            new_token(
              type = "Given",
              value = "a blog post named \"Random\" with Markdown body",
              data = c(
                "```",
                "Some Title, Eh?",
                "===============",
                "Here is the first paragraph of my blog post. Lorem ipsum dolor sit amet,",
                "consectetur adipiscing elit.",
                "```"
              )
            )
          ),
          data = NULL
        )
      )
    )
  })

  it("should tokenize docstring no matter the delimiter indentation", {
    # Arrange
    lines <- c(
      "Scenario: blog",
      "  Given a blog post named \"Random\" with Markdown body",
      "```",
      "Some Title, Eh?",
      "===============",
      "Here is the first paragraph of my blog post. Lorem ipsum dolor sit amet,",
      "consectetur adipiscing elit.",
      "```"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Scenario",
          value = "blog",
          tags = character(0),
          children = list(
            new_token(
              type = "Given",
              value = "a blog post named \"Random\" with Markdown body",
              data = c(
                "```",
                "Some Title, Eh?",
                "===============",
                "Here is the first paragraph of my blog post. Lorem ipsum dolor sit amet,",
                "consectetur adipiscing elit.",
                "```"
              )
            )
          ),
          data = NULL
        )
      )
    )
  })

  it("should tokenize a Data Table", {
    # Arrange
    lines <- c(
      "Given the following users exist:",
      "  | name  | email            |",
      "  | Jane  | janedoe@jane.com |"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Given",
          value = "the following users exist:",
          data = c(
            "| name  | email            |",
            "| Jane  | janedoe@jane.com |"
          )
        )
      )
    )
  })

  it("should tokenize a Data Table no matter the indentation", {
    # Arrange
    lines <- c(
      "Given the following users exist:",
      "         | name  | email            |",
      "         | Jane  | janedoe@jane.com |"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Given",
          value = "the following users exist:",
          data = c(
            "       | name  | email            |",
            "       | Jane  | janedoe@jane.com |"
          )
        )
      )
    )
  })

  it("should tokenize Data Table and ignore commented lines", {
    # Arrange
    lines <- c(
      "Feature: Guess the word",
      "  # Scenario: Breaker joins a game",
      "  #   Given the Maker has started a game with the word 'silky'",
      "  #   When the Breaker joins the Maker's game",
      "",
      "  Scenario: Maker starts a game",
      "    When the Maker starts a game",
      "    Then the Maker waits for a Breaker to join",
      "      | x | y |",
      "      | 1 | 2 |",
      "",
      "# Scenario: Breaker joins a game",
      "#   Given the Maker has started a game with the word 'silky'",
      "#   When the Breaker joins the Maker's game"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Feature",
          value = "Guess the word",
          tags = character(0),
          children = list(
            new_token(
              type = "Scenario",
              value = "Maker starts a game",
              tags = character(0),
              children = list(
                new_token(
                  type = "When",
                  value = "the Maker starts a game",
                  data = NULL
                ),
                new_token(
                  type = "Then",
                  value = "the Maker waits for a Breaker to join",
                  data = c("| x | y |", "| 1 | 2 |")
                )
              ),
              data = NULL
            )
          ),
          data = NULL
        )
      )
    )
  })

  it("should tokenize feature files with 4 spaces indent", {
    # Arrange
    lines <- c(
      "Feature: Guess the word",
      "    Scenario: Maker starts a game",
      "        When the Maker starts a game",
      "        Then the Maker waits for a Breaker to join"
    )
    indent <- "^\\s{4}"

    # Act
    withr::with_options(list(cucumber.indent = indent), {
      result <- tokenize(lines)
    })

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Feature",
          value = "Guess the word",
          tags = character(0),
          children = list(
            new_token(
              type = "Scenario",
              value = "Maker starts a game",
              tags = character(0),
              children = list(
                new_token(
                  type = "When",
                  value = "the Maker starts a game",
                  data = NULL
                ),
                new_token(
                  type = "Then",
                  value = "the Maker waits for a Breaker to join",
                  data = NULL
                )
              ),
              data = NULL
            )
          ),
          data = NULL
        )
      )
    )
  })

  it("should read free-form text after Feature, Background, Scenario, Scenario Outline keywords", {
    # Arrange
    lines <- c(
      "Feature: Guess the word",
      "",
      "  This is a freeform text after Feature",
      "",
      "  Background:",
      "",
      "    This is a freeform text after Background",
      "",
      "    Given a global administrator named \"Greg\"",
      "",
      "  Scenario: Maker starts a game",
      "",
      "    This is a freeform text after Scenario",
      "",
      "    When the Maker starts a game",
      "    Then the Maker waits for a Breaker to join",
      "",
      "  Scenario Outline: eating",
      "",
      "    This is a freeform text after Scenario Outline",
      "",
      "    Given there are <start> cucumbers",
      "    When I eat <eat> cucumbers",
      "    Then I should have <left> cucumbers",
      "    Examples:",
      "      | start | eat | left |",
      "      |    12 |   5 |    7 |",
      "      |    20 |   5 |   15 |"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(
      result,
      list(
        new_token(
          type = "Feature",
          value = "Guess the word",
          tags = character(0),
          children = list(
            new_token(
              type = "Background",
              value = "",
              tags = character(0),
              children = list(
                new_token(
                  type = "Given",
                  value = "a global administrator named \"Greg\"",
                  data = NULL
                )
              ),
              data = "This is a freeform text after Background"
            ),
            new_token(
              type = "Scenario",
              value = "Maker starts a game",
              tags = character(0),
              children = list(
                new_token(
                  type = "When",
                  value = "the Maker starts a game",
                  data = NULL
                ),
                new_token(
                  type = "Then",
                  value = "the Maker waits for a Breaker to join",
                  data = NULL
                )
              ),
              data = "This is a freeform text after Scenario"
            ),
            new_token(
              type = "Scenario Outline",
              value = "eating",
              tags = character(0),
              children = list(
                new_token(
                  type = "Given",
                  value = "there are <start> cucumbers",
                  data = NULL
                ),
                new_token(
                  type = "When",
                  value = "I eat <eat> cucumbers",
                  data = NULL
                ),
                new_token(
                  type = "Then",
                  value = "I should have <left> cucumbers",
                  data = NULL
                ),
                new_token(
                  type = "Scenarios",
                  value = "",
                  tags = character(0),
                  data = c(
                    "| start | eat | left |",
                    "|    12 |   5 |    7 |",
                    "|    20 |   5 |   15 |"
                  )
                )
              ),
              data = "This is a freeform text after Scenario Outline"
            )
          ),
          data = "This is a freeform text after Feature"
        )
      )
    )
  })

  it("should throw an error on unknown keyword", {
    # Arrange
    lines <- c(
      "Feature: Guess the word",
      "",
      "  Unknown: Maker starts a game",
      "    When the Maker starts a game",
      "    Then the Maker waits for a Breaker to join"
    )

    # Act & Assert
    expect_error(tokenize(lines))
  })

  it("should attach a single tag to a Scenario", {
    # Arrange
    lines <- c(
      "Feature: Guess the word",
      "  @smoke",
      "  Scenario: Maker starts a game",
      "    When the Maker starts a game"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(result[[1]]$children[[1]]$tags, c("smoke"))
  })

  it("should attach multiple tags from one line to a Scenario", {
    # Arrange
    lines <- c(
      "Feature: Guess the word",
      "  @smoke @fast",
      "  Scenario: Maker starts a game",
      "    When the Maker starts a game"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(result[[1]]$children[[1]]$tags, c("smoke", "fast"))
  })

  it("should attach tags from multiple lines to a Scenario", {
    # Arrange
    lines <- c(
      "Feature: Guess the word",
      "  @smoke",
      "  @fast",
      "  Scenario: Maker starts a game",
      "    When the Maker starts a game"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(result[[1]]$children[[1]]$tags, c("smoke", "fast"))
  })

  it("should attach tags to Feature", {
    # Arrange
    lines <- c(
      "@suite",
      "Feature: Guess the word",
      "  Scenario: Maker starts a game",
      "    When the Maker starts a game"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(result[[1]]$tags, c("suite"))
  })

  it("should not include tag lines in freeform data", {
    # Arrange
    lines <- c(
      "Feature: Guess the word",
      "",
      "  This is a description",
      "",
      "  @smoke",
      "  Scenario: Maker starts a game",
      "    When the Maker starts a game"
    )

    # Act
    result <- tokenize(lines)

    # Assert
    expect_equal(result[[1]]$data, "This is a description")
  })
})
