# Behavior-Driven Development

When developing software, a disconnect between what users want and what
the software does can occur. We might’ve delivered working, tested code,
but does it solve the user’s problem?

Behavior-driven development aims to mitigate that risk, by capturing and
testing requirements from the perspective of the external user of the
system.

### How BDD works

Whether we’re working with a Product Owner, with users, or by ourselves,
BDD can help us explore and define the problem in a structured way.

The process is as follows:

1.  We capture a vague wish with a User Story.
2.  We refine the User Story into examples. Those examples describe how
    we can tell if the wish has been fulfilled. Focus on what you want
    to achieve, not how to achieve it.
3.  We create specifications. They are direct translations of examples
    into code.

This helps us move from a vague description to a very precise, testable
specification.

### Capturing a wish with a User Story

Let’s imagine we want to implement a bookstore. The first User Story
could be:

> As a customer, I want to select a book and add it to cart so that I
> can buy it.

### Refining the User Story into examples

Behavior-Driven Development helps us focus on behavior, by using a
language that expresses behavior:

- **Given** some context,
- **When** an event occurs,
- **Then** an outcome should be observed.

In this example, we could write:

- Given I am in the bookstore
- When I select “The Hobbit, J.R.R. Tolkien”
- When I add selected book to the cart
- Then I should see “The Hobbit, J.R.R. Tolkien” in the cart

This description is more precise than the User Story. It describes what
needs to happen, what the user needs to do, and what result the user
should see.

At this level, we don’t know anything about the implementation of the
bookstore. This description fits any implementation of the bookstore:

- it could be a web application,
- it could be a CLI application,
- or it could be a physical store with a robot assistant.

The implementation can be changed at any moment, and executing the
specification should tell us if the system allows the user to achieve
their goal.

### Implementing executable specifications

Executable specifications are readable, state the business goal, hide
implementation details and let test code be reused.

BDD is not about tools, but tools help. {cucumber} is one of them.

## BDD with base R

We can practice BDD with base R. Given examples of how the system should
work, we translate them to code: one function per action a user can
take. Function names follow the natural-language description of the
action, and the functions hide the implementation and make the test code
reusable.

The specification of the bookstore could look like this:

``` r

# tests/acceptance/test-bookstore.R
test_that("Bookstore: Adding a book to cart", {
  # Given
  bookstore <- Bookstore$new()
  # When
  bookstore$select("The Hobbit, J.R.R. Tolkien")
  bookstore$add_to_cart()
  # Then
  bookstore$cart_includes("The Hobbit, J.R.R. Tolkien")
})
#> ── Error: Bookstore: Adding a book to cart ─────────────────────────────────────
#> Error in `eval(code, test_env)`: object 'Bookstore' not found
#> Error:
#> ! Test failed with 1 failure and 0 successes.
```

The test fails because the code doesn’t exist yet. This is a good moment
to try a few versions of the specification and keep the one that
expresses the business goal best.

Behind those actions can be any implementation. For example, a package
with:

- `select_book`: function that returns a tibble with book details,
- `add_to_cart`: function that adds a book with given ID to a storage,
- `get_cart`: function that returns a list with details of books in the
  cart.

A minimal implementation:

``` r

storage <- c()
books <- list(
  tibble::tibble(id = 1, title = "The Hobbit, J.R.R. Tolkien"),
  tibble::tibble(id = 2, title = "The Lord of the Rings, J.R.R. Tolkien")
)

select_book <- function(title) {
  books |>
    purrr::keep(\(x) x$title == title) |>
    purrr::pluck(1)
}

add_to_cart <- function(id) {
  storage <<- c(storage, id)
}

get_cart <- function() {
  books |>
    purrr::keep(\(x) x$id %in% storage)
}
```

We plug it in with R6 objects, which bind the actions together:

``` r

# tests/acceptance/setup-bookstore.R
Bookstore <- R6::R6Class(
  private = list(
    selected_id = NULL
  ),
  public = list(
    select = function(title) {
      private$selected_id <- select_book(title)$id
    },
    add_to_cart = function() {
      add_to_cart(private$selected_id)
    },
    cart_includes = function(title) {
      testthat::expect_in(title, purrr::map_chr(get_cart(), "title"))
    }
  )
)
```

Now the same test passes:

``` r

# tests/acceptance/test-bookstore.R
test_that("Bookstore: Adding a book to cart", {
  # Given
  bookstore <- Bookstore$new()
  # When
  bookstore$select("The Hobbit, J.R.R. Tolkien")
  bookstore$add_to_cart()
  # Then
  bookstore$cart_includes("The Hobbit, J.R.R. Tolkien")
})
#> Test passed with 1 success 😸.
```

As the system grows, we add examples and actions, and reuse the actions
already implemented. The implementation will change, but the
specifications stay focused on the business goal.

## BDD with {cucumber}

The steps of BDD with {cucumber} are the same as with base R. The
difference is in how we express specifications and their implementation.

Specifications are written as text in
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
  storage <<- c(storage, id)
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

## Learning BDD

- Gojko Adzic, *Specification by Example*, and Markus Gärtner, *ATDD by
  Example: A Practical Guide to Acceptance Test-Driven Development*.
- [Continuous Delivery Youtube
  Channel](https://www.youtube.com/watch?v=gXh0iUt4TXA&list=PLwLLcwQlnXByKR1Fo7UnE6gQAbx-JfYJZ)
- [Cucumber](https://cucumber.io/docs/guides/)
