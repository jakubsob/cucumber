# cucumber Options

Internally used, package-specific options. They allow overriding the
default behavior of the package.

## Details

The following options are available:

- `cucumber.path`

  Directory with `.feature` files that
  [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  runs and
  [`features_rd()`](https://jakubsob.github.io/cucumber/dev/reference/features_rd.md)
  reads when called without `path`.

  default: `"tests/acceptance"`

- `cucumber.language`

  Language of the feature files without a `# language:` line, like
  `"fr"`.

  default: `"en"`

- `cucumber.docstring_as_lines`

  If `TRUE`, step definitions get a Doc String as a character vector of
  lines, like in cucumber 2.x, instead of one string.

  default: `FALSE`

- `cucumber.reporter_max_docstring_lines`

  Max docstring lines
  [CucumberPrettyReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberPrettyReporter.md)
  prints per step before truncating.

  default: `Inf`

- `cucumber.reporter_max_table_lines`

  Max data table rows
  [CucumberPrettyReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberPrettyReporter.md)
  prints per step before truncating.

  default: `Inf`

- `cucumber.rd_tags`

  Tag expression of the scenarios
  [`features_rd()`](https://jakubsob.github.io/cucumber/dev/reference/features_rd.md)
  puts in help pages.

  default: `"@rd"`

- `cucumber.rd_section`

  Name of the section
  [`features_rd()`](https://jakubsob.github.io/cucumber/dev/reference/features_rd.md)
  puts scenarios in.

  default: `"Behavior"`

See [`base::options()`](https://rdrr.io/r/base/options.html) and
[`base::getOption()`](https://rdrr.io/r/base/options.html) on how to
work with options.

## Behavior

```
```

### Feature: Language

A `# language:` line at the top of a feature file sets the language of
its keywords, like in the official Gherkin parser. The languages are the
ones in the official gherkin-languages.json. Step definitions don't
change, because steps are matched without their keyword. The
`cucumber.language` option sets the language of feature files without a
`# language:` line.

#### Background:

- Given a package

#### Scenario: The cucumber.language option sets the language of feature files without a language line

- Given a file named "features/addition.feature" with

      Fonctionnalité: Addition
        Scénario: Adding one
          Soit I have 1
          Quand I add 1
          Alors I should have 2

- And a file named "features/subtraction.feature" with

  ``` gherkin
  # language: en
  Feature: Subtraction
    Scenario: Taking one
      Given I have 2
      When I add -1
      Then I should have 1
  ```

- And a file named "features/setup-steps.R" with

      given("I have {int}", function(n, context) {
        context$n <- n
      })
      when("I add {int}", function(n, context) {
        context$n <- context$n + n
      })
      then("I should have {int}", function(n, context) {
        expect_equal(context$n, n)
      })

- When I run

      withr::with_options(list(cucumber.language = "fr"), test("features"))

- Then the scenarios have these results:

  |            |        |
  |------------|--------|
  | scenario   | status |
  | Adding one | passed |
  | Taking one | passed |

Source: `tests/acceptance/language.feature`
