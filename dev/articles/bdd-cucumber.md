# BDD with cucumber

New to the method?
[`vignette("bdd")`](https://jakubsob.github.io/cucumber/dev/articles/bdd.md)
explains it without any tool, and builds the bookstore used here. This
article moves its specification from R code into Gherkin.

## From R code to Gherkin

The steps of BDD are the same as with base R. The difference is in how
we express specifications and their implementation.

Examples are written as text in
[Gherkin](https://cucumber.io/docs/gherkin/reference/), not in code.
That separates the specification from the implementation.

We start by writing a feature file:

``` gherkin
# tests/acceptance/bookstore.feature
Feature: Bookstore
  Scenario: Adding a book to cart
    Given I am in the bookstore
    When I select "The Hobbit, J.R.R. Tolkien"
    When I add selected book to the cart
    Then I should see "The Hobbit, J.R.R. Tolkien" in the cart
```

We implement actions with `given`, `when`, and `then` functions:

``` r

# tests/acceptance/setup-steps.R
given("I am in the bookstore", function(context) {
})

when("I select {string}", function(title, context) {
  context$selected_id <- select_book(title)$id
})

when("I add selected book to the cart", function(context) {
  add_to_cart(context$selected_id)
})

then("I should see {string} in the cart", function(title, context) {
  expect_in(title, purrr::map_chr(get_cart(), "title"))
})
```

We can run those tests with:

``` r

cucumber::test()
#>   |  F  P  U  S  OK | Feature
#> ✔ |               1 | Bookstore
#>
#> Summary
#>   1 scenario (1 passed)
#>   4 steps (4 passed)
```

[`cucumber::test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
reads the feature files, finds the step definitions and runs them in
order. See
[`vignette("how-it-works")`](https://jakubsob.github.io/cucumber/dev/articles/how-it-works.md).

Similar to what we did with base R, we can extend the feature file with
a scenario that checks if we can add multiple books to the cart:

``` gherkin
# tests/acceptance/bookstore.feature
Feature: Bookstore
  Scenario: Adding a book to cart
    Given I am in the bookstore
    When I select "The Hobbit, J.R.R. Tolkien"
    When I add selected book to the cart
    Then I should see "The Hobbit, J.R.R. Tolkien" in the cart

  Scenario: Adding multiple books to cart
    Given I am in the bookstore
    When I select "The Hobbit, J.R.R. Tolkien"
    When I add selected book to the cart
    When I select "The Lord of the Rings, J.R.R. Tolkien"
    When I add selected book to the cart
    Then I should see "The Hobbit, J.R.R. Tolkien" in the cart
    Then I should see "The Lord of the Rings, J.R.R. Tolkien" in the cart
```

Both scenarios pass:

``` r

cucumber::test()
#>   |  F  P  U  S  OK | Feature
#> ✔ |               2 | Bookstore
#>
#> Summary
#>   2 scenarios (2 passed)
#>   11 steps (11 passed)
```

## Specifications as documentation

Specifications describe how the system behaves, in a language its users
read. That’s what documentation should say too, so let the
specifications be the documentation of your package. Readers get
examples that are true, because they run.

Describe the feature in the feature file, and tag the scenarios that
illustrate it with `@rd`:

``` gherkin
# tests/acceptance/bookstore.feature
Feature: Bookstore
  A customer selects books and adds them to the cart to buy them.

  @rd
  Scenario: Adding a book to cart
    Given I am in the bookstore
    When I select "The Hobbit, J.R.R. Tolkien"
    When I add selected book to the cart
    Then I should see "The Hobbit, J.R.R. Tolkien" in the cart

  Scenario: Adding multiple books to cart
    ...
```

Then put them in the help page of the function they document with
[`features_rd()`](https://jakubsob.github.io/cucumber/dev/reference/features_rd.md):

``` r

#' Add the selected book to the cart
#'
#' @param id ID of the book, from `select_book()`.
#' @eval cucumber::features_rd(features = "bookstore.feature")
#' @export
add_to_cart <- function(id) {
  cart$ids <- c(cart$ids, id)
}
```

`devtools::document()` adds a section named `"Behavior"` by default to
`?add_to_cart`, with the feature’s name, its description and the tagged
scenarios, as they’re written. On the pkgdown site, steps are a list and
tables are tables, unless you pass `markdown = FALSE`.

The help pages of {cucumber} are written this way, like
[`?hook`](https://jakubsob.github.io/cucumber/reference/hook.html) or
[`?test`](https://jakubsob.github.io/cucumber/reference/test.html). What
we learned writing them:

- Explain the behavior in the feature’s description, not in roxygen.
  It’s what readers see first, above the scenarios. Keep roxygen for
  what feature files can’t say: the title, a sentence of what the
  function is for, a line for each argument, and examples.
- Tag the scenarios that illustrate a rule. Leave the edge cases
  untagged: they test the system, but readers don’t need them to
  understand it. One or two scenarios per rule is enough.
- Tag a `Rule` or a `Feature` when all of it illustrates the function.
  Its scenarios inherit the tag, like they do when you run them by tag.
- To document a function with several features, pass them all:
  `features_rd(features = c("hooks.feature", "tagged_hooks.feature"))`
  puts each in the section, one after the other.
- Write steps that show the outcome. Be specific, but omit unnecessary
  details.

Choose other scenarios with the `tags`, `name` and `features` arguments
of
[`features_rd()`](https://jakubsob.github.io/cucumber/dev/reference/features_rd.md),
like you choose the scenarios to run with
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md).
