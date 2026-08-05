# Define extra parameters to use in Cucumber steps.

The following parameter types are available by default:

|  |  |
|----|----|
| **Type** | **Description** |
| `{int}` | Matches integers, for example `71` or `-19`. Converts value with `as.integer`. |
| `{float}` | Matches floats, for example `3.6`, `.8` or `-9.2`. Converts value with `as.double`. |
| `{word}` | Matches words without whitespace, for example `banana` (but not `banana split`). |
| `{string}` | Matches single-quoted or double-quoted strings, for example `"banana split"` or `'banana split'` (but not `banana split`). Only the text between the quotes will be extracted. The quotes themselves are discarded. |

To use custom parameter types, call `define_parameter_type` before
[`cucumber::test`](https://jakubsobolewski.com/cucumber/reference/test.md)
is called.

## Usage

``` r
define_parameter_type(name, regexp, transformer)
```

## Arguments

- name:

  The name of the parameter.

- regexp:

  A regular expression that the parameter will match on. Note that if
  you want to escape a special character, you need to use four
  backslashes.

- transformer:

  A function that will transform the parameter from a string to the
  desired type. Must be a function that requires only a single argument.

## Value

An object of class `parameter`, invisibly. Function should be called for
side effects.

## Examples

``` r
define_parameter_type("color", "red|blue|green", as.character)
define_parameter_type(
  name = "sci_number",
  regexp = "[+-]?\\\\d*\\\\.?\\\\d+(e[+-]?\\\\d+)?",
  transform = as.double
)

if (FALSE) { # \dontrun{
#' tests/testthat/test-cucumber.R
cucumber::define_parameter_type("color", "red|blue|green", as.character)
cucumber::test(".", "./steps")
} # }
```
