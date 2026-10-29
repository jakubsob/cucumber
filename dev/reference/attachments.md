# Attach data, logs and links to the report

The `context` of a step or a hook attaches data to the report, e.g. a
screenshot or what the page showed:

- `context$attach(data, media_type, file_name)` attaches a string, or a
  raw vector, like a file read with
  [`readBin()`](https://rdrr.io/r/base/readBin.html). `media_type` is
  its [media
  type](https://www.iana.org/assignments/media-types/media-types.xhtml),
  like `"image/png"` or `"application/json"`. It defaults to
  `"text/plain"` for a string, and is required for a raw vector.
  `file_name` is the name of the file the reports offer to download it
  as.

- `context$log(text)` attaches text to read, like a log line.

- `context$link(...)` attaches one or more links. Each argument is a
  URL, or a character vector of URLs, and they're attached together as
  one attachment, like
  `context$link("https://example.com/basket", "https://example.com/checkout")`
  or `context$link(urls)`.

## Behavior

```
```

### Feature: Attachments

A step or a hook attaches data to the report with its `context`:
`context$attach()` attaches a string or a raw vector with its media
type, `context$log()` attaches text and `context$link()` a URL. The
attachments are reported as Cucumber Messages, and the reports show
them, like the HTML report. The pretty reporter prints them under their
step.

#### Background:

- Given a package

#### Scenario: A step attaches data, a log and a link

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      when("I add an item", function(context) {
        context$attach('{"items": 1}', "application/json")
        context$attach(as.raw(c(1, 2, 3)), "application/octet-stream", file_name = "basket.bin")
        context$log("Added an item")
        context$link("https://example.com/basket")
      })

- When I run

      test("features")

- Then the attachments are:

  |  |  |  |  |  |
  |----|----|----|----|----|
  | step | media_type | body | encoding | file_name |
  | When I add an item | application/json | {"items": 1} | IDENTITY |  |
  | When I add an item | application/octet-stream | AQID | BASE64 | basket.bin |
  | When I add an item | text/x.cucumber.log+plain | Added an item | IDENTITY |  |
  | When I add an item | text/uri-list | https://example.com/basket | IDENTITY |  |

#### Scenario: A step attaches several links at once

Each argument of `context$link()` is a URL or a character vector of
URLs. They're attached together, one URL per line.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Check out
      When I check out
  ```

- And a file named "features/setup-steps.R" with

      when("I check out", function(context) {
        context$link("https://example.com/basket", "https://example.com/checkout")
        context$link(c("https://example.com/help", "https://example.com/terms"))
      })

- When I run

      test("features")

- Then the attachments are:

  |  |  |  |  |  |
  |----|----|----|----|----|
  | step | media_type | body | encoding | file_name |
  | When I check out | text/uri-list | https://example.com/basket\nhttps://example.com/checkout | IDENTITY |  |
  | When I check out | text/uri-list | https://example.com/help\nhttps://example.com/terms | IDENTITY |  |

#### Scenario: A step attaches images

Read an image, like a screenshot, with
[`readBin()`](https://rdrr.io/r/base/readBin.html) and attach it with
its media type. It's base64 encoded, and the HTML report shows it.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      read_file <- function(path) readBin(path, "raw", file.size(path))when("I add an item", function(context) {
        png("basket.png")
        plot(1:3)
        dev.off()
        context$attach(read_file("basket.png"), "image/png", file_name = "basket.png")  jpeg("basket.jpg")
        plot(1:3)
        dev.off()
        context$attach(read_file("basket.jpg"), "image/jpeg", file_name = "basket.jpg")
      })

- When I run

      test("features")

- Then the attachments are:

  |                    |            |          |            |
  |--------------------|------------|----------|------------|
  | step               | media_type | encoding | file_name  |
  | When I add an item | image/png  | BASE64   | basket.png |
  | When I add an item | image/jpeg | BASE64   | basket.jpg |

#### Scenario: Hooks attach data too

[`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
and
[`after_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hooks get a `context` to attach with when they take one argument.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      before_all(function(context) context$log("Started the server"))
      before(function(context, scenario) context$log("Opened the browser"))
      when("I add an item", function(context) {})
      after(function(context, scenario) context$attach("<html></html>", "text/html", file_name = "page.html"))

- When I run

      test("features")

- Then the attachments are:

  |           |                           |                    |
  |-----------|---------------------------|--------------------|
  | step      | media_type                | body               |
  | BeforeAll | text/x.cucumber.log+plain | Started the server |
  | Before    | text/x.cucumber.log+plain | Opened the browser |
  | After     | text/html                 | \<html\>\</html\>  |

Source: `tests/acceptance/attachments.feature`

## See also

The [Reports
article](https://jakubsob.github.io/cucumber/articles/reporting.html),
[`vignette("reporting", package = "cucumber")`](https://jakubsob.github.io/cucumber/dev/articles/reporting.md),
attaches screenshots and logs of a failing shinytest2 scenario to the
HTML report.

## Examples

``` r
if (FALSE) { # \dontrun{
when("I open the basket", function(context) {
  context$session$go_to("/basket")
  context$log("Opened /basket")
  context$link("https://example.com/basket")
})

when("I check out", function(context) {
  context$link("https://example.com/basket", "https://example.com/checkout")
})

after(function(context, scenario) {
  if (scenario$status == "failed") {
    file <- tempfile(fileext = ".png")
    context$session$screenshot(file)
    context$attach(readBin(file, "raw", file.size(file)), "image/png", file_name = "screenshot.png")
  }
})
} # }
```
