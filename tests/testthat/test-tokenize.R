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
        list(
          type = "Feature",
          value = "Guess the word",
          children = list(
            list(
              type = "Scenario",
              value = "Maker starts a game",
              children = list(
                list(
                  type = "Step",
                  value = "the Maker starts a game",
                  children = NULL,
                  data = NULL
                ),
                list(
                  type = "Step",
                  value = "the Maker waits for a Breaker to join",
                  children = NULL,
                  data = NULL
                )
              ),
              data = NULL
            ),
            list(
              type = "Scenario",
              value = "Breaker joins a game",
              children = list(
                list(
                  type = "Step",
                  value = "the Maker has started a game with the word 'silky'",
                  children = NULL,
                  data = NULL
                ),
                list(
                  type = "Step",
                  value = "the Breaker joins the Maker's game",
                  children = NULL,
                  data = NULL
                ),
                list(
                  type = "Step",
                  value = "the Breaker must guess a word with 5 characters",
                  children = NULL,
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
        list(
          type = "Feature",
          value = "Guess the word",
          children = list(
            list(
              type = "Scenario",
              value = "Maker starts a game",
              children = list(
                list(
                  type = "Step",
                  value = "the Maker starts a game",
                  children = NULL,
                  data = NULL
                ),
                list(
                  type = "Step",
                  value = "the Maker waits for a Breaker to join",
                  children = NULL,
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
                  value = "I am logged in as Dr. Bill",
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
                  value = "I am logged in as Dr. Bill",
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
        list(
          type = "Scenario",
          value = "blog",
          children = list(
            list(
              type = "Step",
              value = "a blog post named \"Random\" with Markdown body",
              children = NULL,
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
        list(
          type = "Scenario",
          value = "blog",
          children = list(
            list(
              type = "Step",
              value = "a blog post named \"Random\" with Markdown body",
              children = NULL,
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
        list(
          type = "Scenario",
          value = "blog",
          children = list(
            list(
              type = "Step",
              value = "a blog post named \"Random\" with Markdown body",
              children = NULL,
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
        list(
          type = "Scenario",
          value = "blog",
          children = list(
            list(
              type = "Step",
              value = "a blog post named \"Random\" with Markdown body",
              children = NULL,
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
        list(
          type = "Step",
          value = "the following users exist:",
          children = NULL,
          data = c("| name  | email            |", "| Jane  | janedoe@jane.com |")
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
        list(
          type = "Step",
          value = "the following users exist:",
          children = NULL,
          data = c("| name  | email            |", "| Jane  | janedoe@jane.com |")
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
        list(
          type = "Feature",
          value = "Guess the word",
          children = list(
            list(
              type = "Scenario",
              value = "Maker starts a game",
              children = list(
                list(
                  type = "Step",
                  value = "the Maker starts a game",
                  children = NULL,
                  data = NULL
                ),
                list(
                  type = "Step",
                  value = "the Maker waits for a Breaker to join",
                  children = NULL,
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
        list(
          type = "Feature",
          value = "Guess the word",
          children = list(
            list(
              type = "Scenario",
              value = "Maker starts a game",
              children = list(
                list(
                  type = "Step",
                  value = "the Maker starts a game",
                  children = NULL,
                  data = NULL
                ),
                list(
                  type = "Step",
                  value = "the Maker waits for a Breaker to join",
                  children = NULL,
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
        list(
          type = "Feature",
          value = "Guess the word",
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
                )
              ),
              data = "This is a freeform text after Background"
            ),
            list(
              type = "Scenario",
              value = "Maker starts a game",
              children = list(
                list(
                  type = "Step",
                  value = "the Maker starts a game",
                  children = NULL,
                  data = NULL
                ),
                list(
                  type = "Step",
                  value = "the Maker waits for a Breaker to join",
                  children = NULL,
                  data = NULL
                )
              ),
              data = "This is a freeform text after Scenario"
            ),
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
})
