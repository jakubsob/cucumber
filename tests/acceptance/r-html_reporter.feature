@rd
Feature: HTML reporter
  `CucumberHtmlReporter` writes the official Cucumber HTML report of a run when the run ends,
  even when it fails. The page is one file, with the report's script and styles and the
  messages of the run, so it works offline. It can be searched and filtered by status, text and tags.

  Background:
    Given a package

  Scenario: Each step is shown with its result and the error of a step that didn't pass
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
          Then the basket has 1 item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) context$items <- 0)
      when("I add an item", function(context) context$items <- context$items + 1)
      then("the basket has {int} item(s)", function(int, context) expect_equal(context$items, 2))
      """
    When I run
      """
      test("features", reporter = CucumberHtmlReporter$new("report.html"), stop_on_failure = FALSE)
      """
    Then the HTML report "report.html" shows these steps:
      | step                       | status | error                                                    |
      | Given an empty basket      | passed |                                                          |
      | When I add an item         | passed |                                                          |
      | Then the basket has 1 item | failed | expectation_failure Expected `context$items` to equal 2. |

  Scenario: The report is written to cucumber-report.html by default
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) context$items <- 0)
      """
    When I run
      """
      test("features", reporter = CucumberHtmlReporter$new())
      """
    Then the HTML report "cucumber-report.html" shows these steps:
      | step                  | status |
      | Given an empty basket | passed |

  Scenario: Text of the messages can't end the report's script
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add a <!--<script> to the basket
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) context$items <- 0)
      """
    When I run
      """
      test("features", reporter = CucumberHtmlReporter$new("report.html"))
      """
    Then the HTML report "report.html" shows these steps:
      | step                  | status |
      | Given an empty basket | passed |

  Scenario: The attachments of a step are shown under it
    A screenshot and the logs attached when a step fails are shown under the step that failed.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) stop("The basket is full"))
      after_step(function(context, step) {
        if (step$status == "failed") {
          png("basket.png")
          plot(1:3)
          dev.off()
          context$attach(readBin("basket.png", "raw", file.size("basket.png")), "image/png", file_name = "basket.png")
          context$log("Opened the basket")
        }
      })
      """
    When I run
      """
      test("features", reporter = CucumberHtmlReporter$new("report.html"), stop_on_failure = FALSE)
      """
    Then the HTML report "report.html" shows these attachments:
      | step               | kind  | content           |
      | When I add an item | image | basket.png        |
      | When I add an item | text  | Opened the basket |
