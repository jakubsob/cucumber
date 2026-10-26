Feature: Attachments
  A step or a hook attaches data to the report with its `context`: `context$attach()` attaches
  a string or a raw vector with its media type, `context$log()` attaches text and
  `context$link()` a URL. The attachments are reported as Cucumber Messages, and the reports
  show them, like the HTML report. The pretty reporter prints them under their step.

  Background:
    Given a package

  @rd
  Scenario: A step attaches data, a log and a link
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {
        context$attach('{"items": 1}', "application/json")
        context$attach(as.raw(c(1, 2, 3)), "application/octet-stream", file_name = "basket.bin")
        context$log("Added an item")
        context$link("https://example.com/basket")
      })
      """
    When I run
      """
      test("features")
      """
    Then the attachments are:
      | step                | media_type                | body                       | encoding | file_name   |
      | When I add an item  | application/json          | {"items": 1}               | IDENTITY |            |
      | When I add an item  | application/octet-stream  | AQID                       | BASE64   | basket.bin |
      | When I add an item  | text/x.cucumber.log+plain | Added an item              | IDENTITY |            |
      | When I add an item  | text/uri-list             | https://example.com/basket | IDENTITY |            |

  @rd
  Scenario: A step attaches images
    Read an image, like a screenshot, with `readBin()` and attach it with its media type.
    It's base64 encoded, and the HTML report shows it.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      read_file <- function(path) readBin(path, "raw", file.size(path))

      when("I add an item", function(context) {
        png("basket.png")
        plot(1:3)
        dev.off()
        context$attach(read_file("basket.png"), "image/png", file_name = "basket.png")

        jpeg("basket.jpg")
        plot(1:3)
        dev.off()
        context$attach(read_file("basket.jpg"), "image/jpeg", file_name = "basket.jpg")
      })
      """
    When I run
      """
      test("features")
      """
    Then the attachments are:
      | step               | media_type | encoding | file_name  |
      | When I add an item | image/png  | BASE64   | basket.png |
      | When I add an item | image/jpeg | BASE64   | basket.jpg |

  @rd
  Scenario: Hooks attach data too
    `before_all()` and `after_all()` hooks get a `context` to attach with when they take one argument.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before_all(function(context) context$log("Started the server"))
      before(function(context, scenario) context$log("Opened the browser"))
      when("I add an item", function(context) {})
      after(function(context, scenario) context$attach("<html></html>", "text/html", file_name = "page.html"))
      """
    When I run
      """
      test("features")
      """
    Then the attachments are:
      | step      | media_type                | body               |
      | BeforeAll | text/x.cucumber.log+plain | Started the server |
      | Before    | text/x.cucumber.log+plain | Opened the browser |
      | After     | text/html                 | <html></html>      |

  Scenario: A step that attaches data fails afterwards
    The data attached before the failure is kept.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {
        context$log("Adding an item")
        stop("The basket is full")
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step               | status |
      | When I add an item | failed |
    And the attachments are:
      | step               | body           |
      | When I add an item | Adding an item |

  Scenario: A raw vector must have a media type
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) context$attach(as.raw(1)))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step               | status |
      | When I add an item | failed |
    And the error message includes "A raw vector attachment must have a `media_type`."

  Scenario Outline: An attachment's <argument> must be a string
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) context$attach("<html></html>", <argument> = 1))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the scenario "Add an item" errored with
      """
      Error: Step "I add an item" failed
      i Feature: basket.feature
      i Scenario: Add an item
      i Step defined at: setup-steps.R:1
      Caused by error in `attachment_message()`:
      ! Assertion on '<argument>' failed: Must be of type 'string' (or 'NULL'), not 'double'.
      """

    Examples:
      | argument   | example        |
      | media_type | image/png      |
      | file_name  | screenshot.png |

  Scenario: An attachment must be a string or a raw vector
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) context$attach(1:3))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step               | status |
      | When I add an item | failed |
    And the error message includes "An attachment must be a string or a raw vector."

  Scenario: The pretty reporter prints the logs and links under their step
    Other data is printed with its media type and file name.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) context$log("Opened the browser"))
      when("I add an item", function(context) {
        context$log("Added an item")
        context$link("https://example.com/basket")
        context$attach(as.raw(1), "image/png", file_name = "basket.png")
      })
      """
    When I run
      """
      test("features", reporter = CucumberPrettyReporter$new())
      """
    Then the output includes
      """
      Scenario: Add an item
      Opened the browser
      v When I add an item
      Added an item
      https://example.com/basket
      Attachment (image/png): basket.png
      """
