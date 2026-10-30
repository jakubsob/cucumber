# Gherkin Reference

This is a modified copy of the official [Gherkin
reference](https://cucumber.io/docs/gherkin/reference/) from Cucumber
project, adjusted to specific features of the
[cucumber](https://github.com/jakubsob/cucumber) package.

------------------------------------------------------------------------

Gherkin uses a set of special [keywords](#keywords) to give structure
and meaning to executable specifications.

Most lines in a Gherkin document start with one of the
[keywords](#keywords).

Comments are only permitted at the start of a new line, anywhere in the
feature file. They begin with zero or more spaces, followed by a hash
sign (`#`) and some text.

Block comments are currently not supported by Gherkin.

Indentation doesn’t change the meaning of a line, the keyword it starts
with does. You can indent with spaces or tabs, the recommended
indentation level is two spaces.

- features/indent.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Indentation
Scenario: Flat
Given I have 1
Then I should have 1
    Scenario: Tabs and a step deeper than the previous one
    Given I have 1
        Then I should have 1
```

``` r

given("I have {int}", function(n, context) {
  context$n <- n
})
then("I should have {int}", function(n, context) {
  expect_equal(context$n, n)
})
```

``` r

test("features")
```

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               2 | Indentation

────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  4 steps (4 passed)
  0m00.058s (executing steps: 0m00.007s)
────────────────────────────────────────────────────────────────────────────────
```

Some keywords *are* followed by a colon (`:`) and some *are not*. If you
add a colon after a keyword that should not be followed by one, like
`Given: x`, it isn’t a step: after a step the feature file fails to
parse, and right under `Scenario:` the line is read as part of the
description.

Every feature file is parsed before anything runs. If any of them can’t
be parsed, no scenario runs, and every error is reported with its file,
line and column:

- features/broken.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Broken
  Scenario: Junk between steps
    Given a step
    this line is not a step
    Then a step
  Scenario: A ragged table
    Given a step
      | a | b |
      | c |
```

``` r

given("a step", function(context) {})
```

``` r

test("features", stop_on_failure = FALSE)
```

``` console-output
  Error:
    Can't parse feature files
    ✖ Parse error in "broken.feature" (4:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'this line is not a step'
    ✖ Parse error in "broken.feature" (9:7): inconsistent cell count within the table

────────────────────────────────────────────────────────────────────────────────
Summary
  0 scenarios
  0 steps
────────────────────────────────────────────────────────────────────────────────
```

## Keywords

Each line that isn’t a blank line has to start with a Gherkin *keyword*,
followed by any text you like. The only exceptions are the free-form
descriptions placed underneath `Example/Scenario`, `Background` and
`Scenario Outline` lines.

The primary keywords are:

- [`Feature`](#feature)
- [`Rule`](#rule)
- [`Example`](#example) (or `Scenario`)
- [`Given`](#given), [`When`](#when), [`Then`](#then), [`And`,
  `But`](#and-but) for [steps](#steps) (or `*`)
- [`Background`](#background)
- [`Scenario Outline`](#scenario-outline) (or `Scenario Template`)
- [`Examples`](#examples) (or `Scenarios`)

There are a few secondary keywords as well:

- `"""` ([Doc Strings](#doc-strings))
- `|` ([Data Tables](#data-tables))
- `@` ([Tags](#tags))
- `#` (Comments)

## Feature

The purpose of the `Feature` keyword is to provide a high-level
description of a software feature, and to group related scenarios.

The first primary keyword in a Gherkin document must always be `Feature`
(or `Ability`, or `Business Need`), followed by a `:` and a short text
that describes the feature.

You can add free-form text underneath Feature to add more description.
These description lines are ignored by Cucumber at runtime.

The name and the optional description have no special meaning to
Cucumber. Their purpose is to provide a place for you to document
important aspects of the feature, such as a brief explanation and a list
of business rules (general acceptance criteria).

The free format description for Feature ends when you start a line with
the keyword `Background`, `Rule`, `Example` or `Scenario Outline` (or
their alias keywords).

You can only have a single `Feature` in a `.feature` file. A file
without a `Feature`, or a `Feature` without scenarios, runs nothing.

- features/empty.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Not written yet
  Scenarios will come later.
```

``` r

given("a step", function(context) {})
```

``` r

test("features")
```

``` console-output
────────────────────────────────────────────────────────────────────────────────
Summary
  0 scenarios
  0 steps
  0m00.001s (executing steps: 0m00.000s)
────────────────────────────────────────────────────────────────────────────────
```

## Descriptions

Free-form descriptions (as described above for `Feature`) can also be
placed underneath `Rule`, `Example/Scenario`, `Background`,
`Scenario Outline` and `Examples`.

You can write anything you like, as long as no line starts with a
keyword.

## Example

This is a *concrete example* that *illustrates* a business rule. It
consists of a list of [steps](#steps).

The keyword `Scenario` is a synonym of the keyword `Example`.

You can have as many steps as you like, but we recommend 3-5 steps per
example. Having too many steps will cause the example to lose its
expressive power as a specification and documentation.

In addition to being a specification and documentation, an example is
also a *test*. As a whole, your examples are an *executable
specification* of the system.

Examples follow this same pattern:

- Describe an initial context (`Given` steps)
- Describe an event (`When` steps)
- Describe an expected outcome (`Then` steps)

## Rule

The `Rule` keyword groups together several scenarios that belong to one
*business rule*. A `Rule` should contain one or more scenarios that
illustrate the particular rule.

- features/rule.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Basket
  Rule: Items can be added
    Scenario: Add one item
      Given the basket has 0 items
      When I add 1 item
      Then the basket should have 1 items

  Rule: Items can be removed
    Example: Remove one item
      Given the basket has 2 items
      When I remove 1 item
      Then the basket should have 1 items
```

``` r

given("the basket has {int} items", function(n, context) {
  context$items <- n
})
when("I add {int} item", function(n, context) {
  context$items <- context$items + n
})
when("I remove {int} item", function(n, context) {
  context$items <- context$items - n
})
then("the basket should have {int} items", function(n, context) {
  expect_equal(context$items, n)
})
```

``` r

test("features")
```

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               2 | Basket

────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  6 steps (6 passed)
  0m00.036s (executing steps: 0m00.009s)
────────────────────────────────────────────────────────────────────────────────
```

A `Rule` can have its own `Background`. It runs after the `Feature`’s
`Background`, only for the scenarios of that `Rule`.

- features/rule.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Basket
  Background:
    Given the basket has 0 items

  Scenario: Outside any rule
    Then the basket should have 0 items

  Rule: A full basket
    Background:
      When I add 5 item

    Scenario: Full basket
      Then the basket should have 5 items

    Scenario Outline: Removing from a full basket
      When I remove <n> item
      Then the basket should have <left> items

      Examples:
        | n | left |
        | 1 | 4    |
        | 2 | 3    |
```

``` r

given("the basket has {int} items", function(n, context) {
  context$items <- n
})
when("I add {int} item", function(n, context) {
  context$items <- context$items + n
})
when("I remove {int} item", function(n, context) {
  context$items <- context$items - n
})
then("the basket should have {int} items", function(n, context) {
  expect_equal(context$items, n)
})
```

``` r

test("features", reporter = CucumberPrettyReporter$new())
```

``` console-output
Feature: Basket
  Scenario: Outside any rule
    ✔ Given the basket has 0 items
    ✔ Then the basket should have 0 items
  Rule: A full basket
  Scenario: Full basket
    ✔ Given the basket has 0 items
    ✔ When I add 5 item
    ✔ Then the basket should have 5 items
  Scenario Outline: Removing from a full basket
    ✔ Given the basket has 0 items
    ✔ When I add 5 item
    ✔ When I remove 1 item
    ✔ Then the basket should have 4 items
  Scenario Outline: Removing from a full basket
    ✔ Given the basket has 0 items
    ✔ When I add 5 item
    ✔ When I remove 2 item
    ✔ Then the basket should have 3 items


────────────────────────────────────────────────────────────────────────────────
Summary
  4 scenarios (4 passed)
  13 steps (13 passed)
  0m00.068s (executing steps: 0m00.012s)
────────────────────────────────────────────────────────────────────────────────
```

## Steps

Each step starts with `Given`, `When`, `Then`, `And`, or `But`.

Cucumber executes each step in a scenario one at a time, in the sequence
you’ve written them in. When Cucumber tries to execute a step, it looks
for a matching step definition to execute.

Keywords are not taken into account when looking for a step definition.
This means you cannot have a `Given`, `When`, `Then`, `And` or `But`
step with the same text as another step.

Cucumber considers the following steps duplicates:

``` gherkin
Given there is money in my account
Then there is money in my account
```

This might seem like a limitation, but it forces you to come up with a
less ambiguous, more clear domain language:

``` gherkin
Given my account has a balance of £430
Then my account should have a balance of £430
```

### Given

`Given` steps are used to describe the initial context of the system -
the *scene* of the scenario. It is typically something that happened in
the *past*.

When Cucumber executes a `Given` step, it will configure the system to
be in a well-defined state, such as creating and configuring objects or
adding data to a test database.

The purpose of `Given` steps is to **put the system in a known state**
before the user (or external system) starts interacting with the system
(in the `When` steps). Avoid talking about user interaction in
`Given`’s. If you were creating use cases, `Given`’s would be your
preconditions.

It’s okay to have several `Given` steps (use `And` or `But` for number 2
and upwards to make it more readable).

Examples:

- Mickey and Minnie have started a game
- I am logged in
- Joe has a balance of £42

### When

`When` steps are used to describe an event, or an *action*. This can be
a person interacting with the system, or it can be an event triggered by
another system.

Examples:

- Guess a word
- Invite a friend
- Withdraw money

Most software does something people could do manually (just not as
efficiently).

Try hard to come up with examples that don’t make any assumptions about
technology or user interface. Imagine it’s 1922, when there were no
computers.

Implementation details should be hidden in the step definitions (see
[`?step`](https://jakubsob.github.io/cucumber/dev/reference/step.md)).

### Then

`Then` steps are used to describe an *expected* outcome, or result.

The step definition of a `Then` step should use an *assertion* to
compare the *actual* outcome (what the system actually does) to the
*expected* outcome (what the step says the system is supposed to do).

An outcome *should* be on an **observable** output. That is, something
that comes *out* of the system (report, user interface, message), and
not a behavior deeply buried inside the system (like a record in a
database).

Examples:

- See that the guessed word was wrong
- Receive an invitation
- Card should be swallowed

While it might be tempting to implement `Then` steps to look in the
database - resist that temptation!

You should only verify an outcome that is observable for the user (or
external system), and changes to a database are usually not.

### And, But

If you have successive `Given`’s or `Then`’s, you *could* write:

``` gherkin
Example: Multiple Givens
  Given one thing
  Given another thing
  Given yet another thing
  When I open my eyes
  Then I should see something
  Then I shouldn't see something else
```

Or, you could make the example more fluidly structured by replacing the
successive `Given`’s or `Then`’s with `And`’s and `But`’s:

``` gherkin
Example: Multiple Givens
  Given one thing
  And another thing
  And yet another thing
  When I open my eyes
  Then I should see something
  But I shouldn't see something else
```

### \*

Gherkin also supports using an asterisk (`*`) in place of any of the
normal step keywords. This can be helpful when you have some steps that
are effectively a *list of things*, so you can express it more like
bullet points where otherwise the natural language of `And` etc might
not read so elegantly.

For example:

``` gherkin
Scenario: All done
  Given I am out shopping
  And I have eggs
  And I have milk
  And I have butter
  When I check my list
  Then I don't need anything
```

Could be expressed as:

``` gherkin
Scenario: All done
  Given I am out shopping
  * I have eggs
  * I have milk
  * I have butter
  When I check my list
  Then I don't need anything
```

## Background

Occasionally you’ll find yourself repeating the same `Given` steps in
all of the scenarios in a `Feature`.

Since it is repeated in every scenario, this is an indication that those
steps are not *essential* to describe the scenarios; they are
*incidental details*. You can literally move such `Given` steps to the
background, by grouping them under a `Background` section.

A `Background` allows you to add some context to the scenarios that
follow it. It can contain one or more `Given` steps, which are run
before *each* scenario, but after any
[`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hooks (see
[`?hook`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)).

A `Background` is placed before the first `Scenario`/`Example`, at the
same level of indentation.

For example:

- features/background.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Background example
  Background:
    Given the value is 10

  Scenario: First scenario
    Then I get 10

  Scenario: Second scenario
    Then I get 10
```

``` r

given("the value is {int}", function(n, context) {
  context$value <- n
})
then("I get {int}", function(n, context) {
  expect_equal(context$value, n)
})
```

``` r

test("features", reporter = CucumberPrettyReporter$new())
```

``` console-output
Feature: Background example
  Scenario: First scenario
    ✔ Given the value is 10
    ✔ Then I get 10
  Scenario: Second scenario
    ✔ Given the value is 10
    ✔ Then I get 10


────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  4 steps (4 passed)
  0m00.025s (executing steps: 0m00.004s)
────────────────────────────────────────────────────────────────────────────────
```

You can only have one set of `Background` steps per `Feature` or `Rule`.
If you need different `Background` steps for different scenarios,
consider breaking up your set of scenarios into more `Rule`s or
`Feature`s.

For a less explicit alternative to `Background`, check out
[`?hook`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)

### Tips for using Background

- Don’t use `Background` to set up complicated states, unless that state
  is actually something the client needs to know.
  - For example, if the user and site names don’t matter to the client,
    use a higher-level step such as
    `Given I am logged in as a site owner`.
- Keep your `Background` section short.
  - The client needs to actually remember this stuff when reading the
    scenarios. If the `Background` is more than 4 lines long, consider
    moving some of the irrelevant details into higher-level steps.
- Make your `Background` section vivid.
  - Use colourful names, and try to tell a story. The human brain keeps
    track of stories much better than it keeps track of names like
    `"User A"`, `"User B"`, `"Site 1"`, and so on.
- Keep your scenarios short, and don’t have too many.
  - If the `Background` section has scrolled off the screen, the reader
    no longer has a full overview of what’s happening. Think about using
    higher-level steps, or splitting the `*.feature` file.

## Scenario Outline

The `Scenario Outline` keyword can be used to run the same `Scenario`
multiple times, with different combinations of values.

The keyword `Scenario Template` is a synonym of the keyword
`Scenario Outline`.

Copying and pasting scenarios to use different values quickly becomes
tedious and repetitive. A `Scenario Outline` is a template with
`< >`-delimited parameters, run once for each row of its `Examples`:

- features/addition.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Addition
  Scenario Outline: Adding numbers
    Given I have <a>
    When I add <b>
    Then I get <result>

    Examples:
      | a | b | result |
      | 1 | 2 | 3      |
      | 4 | 5 | 9      |
      | 0 | 0 | 0      |
```

``` r

given("I have {int}", function(n, context) {
  context$value <- n
})
when("I add {int}", function(n, context) {
  context$value <- context$value + n
})
then("I get {int}", function(n, context) {
  expect_equal(context$value, n)
})
```

``` r

test("features", reporter = CucumberPrettyReporter$new())
```

``` console-output
Feature: Addition
  Scenario Outline: Adding numbers
    ✔ Given I have 1
    ✔ When I add 2
    ✔ Then I get 3
  Scenario Outline: Adding numbers
    ✔ Given I have 4
    ✔ When I add 5
    ✔ Then I get 9
  Scenario Outline: Adding numbers
    ✔ Given I have 0
    ✔ When I add 0
    ✔ Then I get 0


────────────────────────────────────────────────────────────────────────────────
Summary
  3 scenarios (3 passed)
  9 steps (9 passed)
  0m00.036s (executing steps: 0m00.009s)
────────────────────────────────────────────────────────────────────────────────
```

## Examples

A `Scenario Outline` must contain one or more `Examples` (or
`Scenarios`) section(s). `Examples` under a `Scenario` make it a
`Scenario Outline` too. Its steps are interpreted as a template which is
never directly run. Instead, the `Scenario Outline` is run *once for
each row* in the `Examples` section beneath it (not counting the first
header row).

The steps can use `<>` delimited *parameters* that reference headers in
the examples table. Cucumber will replace these parameters with values
from the table *before* it tries to match the step against a step
definition.

If our step definitions use `{string}` parameters, the substituted text
must be quoted: either put quotes around the placeholder in the step
(`"<start>"`) or around the values in the table.

- Quotes in the step
- Quotes in the table

- features/eating.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Eating
  Scenario Outline: eating
    Given there are "<start>" cucumbers
    When I eat "<eat>" cucumbers
    Then I should have "<left>" cucumbers

    Examples:
      | start  | eat  | left    |
      | twelve | five | seven   |
      | twenty | five | fifteen |
```

``` r

numbers <- c(five = 5, seven = 7, twelve = 12, fifteen = 15, twenty = 20)
given("there are {string} cucumbers", function(start, context) {
  context$cucumbers <- numbers[[start]]
})
when("I eat {string} cucumbers", function(eat, context) {
  context$cucumbers <- context$cucumbers - numbers[[eat]]
})
then("I should have {string} cucumbers", function(left, context) {
  expect_equal(context$cucumbers, numbers[[left]])
})
```

``` r

test("features", reporter = CucumberPrettyReporter$new())
```

``` console-output
Feature: Eating
  Scenario Outline: eating
    ✔ Given there are "twelve" cucumbers
    ✔ When I eat "five" cucumbers
    ✔ Then I should have "seven" cucumbers
  Scenario Outline: eating
    ✔ Given there are "twenty" cucumbers
    ✔ When I eat "five" cucumbers
    ✔ Then I should have "fifteen" cucumbers


────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  6 steps (6 passed)
  0m00.032s (executing steps: 0m00.006s)
────────────────────────────────────────────────────────────────────────────────
```

- features/eating.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Eating
  Scenario Outline: eating
    Given there are <start> cucumbers
    When I eat <eat> cucumbers
    Then I should have <left> cucumbers

    Examples:
      | start    | eat    | left      |
      | 'twelve' | 'five' | 'seven'   |
      | 'twenty' | 'five' | 'fifteen' |
```

``` r

numbers <- c(five = 5, seven = 7, twelve = 12, fifteen = 15, twenty = 20)
given("there are {string} cucumbers", function(start, context) {
  context$cucumbers <- numbers[[start]]
})
when("I eat {string} cucumbers", function(eat, context) {
  context$cucumbers <- context$cucumbers - numbers[[eat]]
})
then("I should have {string} cucumbers", function(left, context) {
  expect_equal(context$cucumbers, numbers[[left]])
})
```

``` r

test("features", reporter = CucumberPrettyReporter$new())
```

``` console-output
Feature: Eating
  Scenario Outline: eating
    ✔ Given there are 'twelve' cucumbers
    ✔ When I eat 'five' cucumbers
    ✔ Then I should have 'seven' cucumbers
  Scenario Outline: eating
    ✔ Given there are 'twenty' cucumbers
    ✔ When I eat 'five' cucumbers
    ✔ Then I should have 'fifteen' cucumbers


────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  6 steps (6 passed)
  0m00.030s (executing steps: 0m00.006s)
────────────────────────────────────────────────────────────────────────────────
```

This Scenario Outline results in two Scenarios being run, both named
`eating`. Scenarios that share a name are numbered in test results:
`eating (1)`, `eating (2)`.

You can use parameters in the `Scenario Outline` name as well, to give
each scenario its own name, for example
`Scenario Outline: eat <eat> out of <start>`.

You can also use parameters in [multiline step
arguments](#step-arguments): they’re replaced in Doc Strings and Data
Tables too.

- features/outline.feature
- features/setup-steps.R
- Console

```` gherkin
Feature: Outlines
  Scenario Outline: Greeting <name>
    Given a greeting
      ```
      Hello, <name>!
      ```
    And a person
      | name   |
      | <name> |
    Then the greeting is for the person

    Examples: People
      These are the people we greet.
      | name  |
      | Alice |
      | Bob   |
````

``` r

given("a greeting", function(greeting, context) {
  context$greeting <- greeting
})
given("a person", function(person, context) {
  context$name <- person$name
})
then("the greeting is for the person", function(context) {
  expect_equal(context$greeting, paste0("Hello, ", context$name, "!"))
})
```

``` r

test("features", reporter = CucumberPrettyReporter$new())
```

```` console-output
Feature: Outlines
  Scenario Outline: Greeting Alice
    ✔ Given a greeting
      ```
      Hello, Alice!
      ```
    ✔ And a person
      | name  |
      | Alice |
    ✔ Then the greeting is for the person
  Scenario Outline: Greeting Bob
    ✔ Given a greeting
      ```
      Hello, Bob!
      ```
    ✔ And a person
      | name |
      | Bob  |
    ✔ Then the greeting is for the person


────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  6 steps (6 passed)
  0m00.033s (executing steps: 0m00.006s)
────────────────────────────────────────────────────────────────────────────────
````

## Step Arguments

In some cases you might want to pass more data to a step than fits on a
single line. For this purpose Gherkin has `Doc Strings` and
`Data Tables`.

## Doc Strings

`Doc Strings` are handy for passing a larger piece of text to a step
definition.

The text should be offset by delimiters consisting of three double-quote
marks on lines of their own:

- features/docstring.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Doc Strings
  Scenario: Step with a Doc String
    Given a message
      """
      Hello, world!
      """
    Then the message is "Hello, world!"
```

``` r

given("a message", function(message, context) {
  context$message <- message
})
then("the message is {string}", function(expected, context) {
  expect_identical(context$message, expected)
})
```

``` r

test("features")
```

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               1 | Doc Strings

────────────────────────────────────────────────────────────────────────────────
Summary
  1 scenario (1 passed)
  2 steps (2 passed)
  0m00.016s (executing steps: 0m00.002s)
────────────────────────────────────────────────────────────────────────────────
```

Doc strings also support using three backticks as the delimiter, like in
the examples below.

In your step definition, there’s no need to find this text and match it
in your pattern.

It is passed to the step definition as one string, its lines joined by
`"\n"`, after the step’s parameters and before `context`:

- features/docstring.feature
- features/setup-steps.R
- Console

```` gherkin
Feature: Doc Strings
  Scenario: Doc String with a parameter
    Given file "greeting.txt" contains
      ```
      Hello!
      ```
    Then file "greeting.txt" has content "Hello!"
````

``` r

given("file {string} contains", function(filename, content, context) {
  context$files <- c(context$files, setNames(list(content), filename))
})
then("file {string} has content {string}", function(filename, expected, context) {
  expect_identical(context$files[[filename]], expected)
})
```

``` r

test("features")
```

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               1 | Doc Strings

────────────────────────────────────────────────────────────────────────────────
Summary
  1 scenario (1 passed)
  2 steps (2 passed)
  0m00.018s (executing steps: 0m00.002s)
────────────────────────────────────────────────────────────────────────────────
```

To get a character vector of lines instead, set
`options(cucumber.docstring_as_lines = TRUE)`, see
[`?opts`](https://jakubsob.github.io/cucumber/dev/reference/opts.md).

Indentation of the opening `"""` is unimportant, although common
practice is two spaces in from the enclosing step. The indentation
inside the triple quotes, however, is significant. Each line of the Doc
String will be dedented according to the opening `"""`. Indentation
beyond the column of the opening `"""` will therefore be preserved.

- features/docstring.feature
- features/setup-steps.R
- Console

```` gherkin
Feature: Doc Strings
  Scenario: Delimiter indented past the step
    Given a message
      ```
      foo:
      - bar: bar_value
        baz: baz_value
      ```
    Then the message is the indented yaml
  Scenario: Delimiter aligned with the step
    Given a message
    ```
    foo:
    - bar: bar_value
      baz: baz_value
    ```
    Then the message is the indented yaml
````

``` r

given("a message", function(message, context) {
  context$message <- message
})
then("the message is the indented yaml", function(context) {
  expect_equal(context$message, "foo:\n- bar: bar_value\n  baz: baz_value")
})
```

``` r

test("features")
```

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               2 | Doc Strings

────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  4 steps (4 passed)
  0m00.024s (executing steps: 0m00.003s)
────────────────────────────────────────────────────────────────────────────────
```

You can specify the content type of a Doc String after the opening
delimiter, for example `"""markdown`. The step definition gets it in the
`media_type` attribute of the Doc String: `attr(body, "media_type")`.

- features/docstring.feature
- features/setup-steps.R
- Console

```` gherkin
Feature: Doc Strings
  Scenario: A request body
    Given a body
      ```json
      {"id": 1}
      ```
    Then the body is JSON
  Scenario: Text without a media type
    Given a body
      ```
      Hello
      ```
    Then the body has no media type
````

``` r

given("a body", function(body, context) {
  context$body <- body
})
then("the body is JSON", function(context) {
  expect_equal(attr(context$body, "media_type"), "json")
  expect_equal(c(context$body), "{\"id\": 1}")
})
then("the body has no media type", function(context) {
  expect_null(attr(context$body, "media_type"))
})
```

``` r

test("features")
```

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               2 | Doc Strings

────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  4 steps (4 passed)
  0m00.039s (executing steps: 0m00.017s)
────────────────────────────────────────────────────────────────────────────────
```

## Data Tables

`Data Tables` are handy for passing a list of values to a step
definition.

Just like `Doc Strings`, `Data Tables` are passed to the step definition
after the step’s parameters and before `context`, as a tibble whose
column names are its first row. See
[`?step`](https://jakubsob.github.io/cucumber/dev/reference/step.md) for
details.

- features/table.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Tables
  Scenario: Step with table
    Given a list of numbers
      | value |
      | 1     |
      | 2     |
      | 3     |
    Then the sum is 6
```

``` r

given("a list of numbers", function(table, context) {
  expect_s3_class(table, "tbl_df")
  context$numbers <- as.integer(table$value)
})
then("the sum is {int}", function(n, context) {
  expect_equal(sum(context$numbers), n)
})
```

``` r

test("features")
```

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               1 | Tables

────────────────────────────────────────────────────────────────────────────────
Summary
  1 scenario (1 passed)
  2 steps (2 passed)
  0m00.017s (executing steps: 0m00.002s)
────────────────────────────────────────────────────────────────────────────────
```

Every row of a Data Table must have the same number of cells, or the
feature file fails to parse.

A step can have both a Data Table and a Doc String. The step definition
gets them in the order they are written:

- features/arguments.feature
- features/setup-steps.R
- Console

```` gherkin
Feature: Step arguments
  Scenario: Both arguments
    Given a request
      | header | value |
      | Accept | json  |
      ```json
      {"id": 1}
      ```
    Then the request is ready
````

``` r

given("a request", function(headers, body, context) {
  context$headers <- headers
  context$body <- body
})
then("the request is ready", function(context) {
  expect_equal(list(context$headers$value, c(context$body)), list("json", "{\"id\": 1}"))
})
```

``` r

test("features")
```

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               1 | Step arguments

────────────────────────────────────────────────────────────────────────────────
Summary
  1 scenario (1 passed)
  2 steps (2 passed)
  0m00.016s (executing steps: 0m00.002s)
────────────────────────────────────────────────────────────────────────────────
```

### Table Cell Escaping

If you want to use a newline character in a table cell, you can write
this as `\n`. If you need a `|` as part of the cell, you can escape it
as `\|`. And finally, if you need a `\`, you can escape that with `\\`.

- features/table.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Escapes
  Scenario: Escaped cells
    Given cells
      | text |
      | a\nb |
      | a\|b |
      | a\\b |
    Then the cells are unescaped
```

``` r

given("cells", function(table, context) {
  context$cells <- table$text
})
then("the cells are unescaped", function(context) {
  expect_equal(context$cells, c("a\nb", "a|b", "a\\b"))
})
```

``` r

test("features")
```

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               1 | Escapes

────────────────────────────────────────────────────────────────────────────────
Summary
  1 scenario (1 passed)
  2 steps (2 passed)
  0m00.020s (executing steps: 0m00.002s)
────────────────────────────────────────────────────────────────────────────────
```

## Tags

Tags organise features and scenarios. Use them to:

- run a subset of scenarios,
- restrict hooks to a subset of scenarios.

A feature or scenario can have as many tags as you like. Separate them
with spaces, like `@smoke @fast`.

Tags can be placed above the following Gherkin elements:

- `Feature`
- `Rule`
- `Scenario`
- `Scenario Outline`
- `Examples`

In `Scenario Outline`, you can use tags on different sets of examples:

- features/outline.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Platforms
  Scenario Outline: Running on <n>
    Given I have <n>
    Then I get <n>

    @mobile
    Examples:
      | n |
      | 1 |
      | 2 |

    @desktop
    Examples:
      | n |
      | 3 |
```

``` r

given("I have {int}", function(n, context) {
  context$value <- n
})
then("I get {int}", function(n, context) {
  expect_equal(context$value, n)
})
```

``` r

test("features", tags = "@mobile", reporter = CucumberPrettyReporter$new())
```

``` console-output
Feature: Platforms
  Scenario Outline: Running on 1
    ✔ Given I have 1
    ✔ Then I get 1
  Scenario Outline: Running on 2
    ✔ Given I have 2
    ✔ Then I get 2


────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  4 steps (4 passed)
  0m00.023s (executing steps: 0m00.004s)
────────────────────────────────────────────────────────────────────────────────
```

Tags above a `Background` or a step make the feature file fail to parse:

``` gherkin
Feature: Invalid tag usage
  @invalid-here
  Background:
    Given setup step

  Scenario: Test
    @also-invalid
    Given a step
```

### Tag inheritance

Tags are inherited by child elements. Tags placed above a `Feature` will
be inherited by `Rule`, `Scenario`, `Scenario Outline`, or `Examples`.
Tags placed above a `Rule` will be inherited by its scenarios.
Similarly, tags placed above a `Scenario Outline` will be inherited by
`Examples`.

- features/tagged.feature
- features/untagged.feature
- features/setup-steps.R
- Console

``` gherkin
@smoke
Feature: Tagged
  Scenario: First
    Given I have 1
    Then I get 1

  Scenario: Second
    Given I have 2
    Then I get 2
```

``` gherkin
Feature: Untagged
  Scenario: Third
    Given I have 3
    Then I get 3
```

``` r

given("I have {int}", function(n, context) {
  context$value <- n
})
then("I get {int}", function(n, context) {
  expect_equal(context$value, n)
})
```

``` r

test("features", tags = "@smoke", reporter = CucumberPrettyReporter$new())
```

``` console-output
Feature: Tagged
  Scenario: First
    ✔ Given I have 1
    ✔ Then I get 1
  Scenario: Second
    ✔ Given I have 2
    ✔ Then I get 2


────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  4 steps (4 passed)
  0m00.022s (executing steps: 0m00.004s)
────────────────────────────────────────────────────────────────────────────────
```

### Running a subset of scenarios

You can use the `tags` parameter in
[`cucumber::test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
or
[`cucumber::run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
to only run scenarios with particular tags.

Using tag expressions:

``` r

# Run only scenarios tagged with @smoke
cucumber::test("tests/acceptance", tags = "@smoke")

# Run scenarios tagged with both @smoke and @fast
cucumber::test("tests/acceptance", tags = "@smoke and @fast")

# Run scenarios tagged with @wip but not @slow
cucumber::test("tests/acceptance", tags = "@wip and not @slow")

# Run scenarios tagged with either @gui or @database
cucumber::test("tests/acceptance", tags = "@gui or @database")
```

- features/tagged.feature
- features/setup-steps.R
- Console

``` gherkin
Feature: Tagged
  @smoke @fast
  Scenario: Smoke and fast
    Given I have 1
    Then I get 1

  @smoke @slow
  Scenario: Smoke and slow
    Given I have 2
    Then I get 2

  @ui @fast
  Scenario: UI and fast
    Given I have 3
    Then I get 3

  @ui @slow
  Scenario: UI and slow
    Given I have 4
    Then I get 4

  Scenario: Untagged
    Given I have 5
    Then I get 5
```

``` r

given("I have {int}", function(n, context) {
  context$value <- n
})
then("I get {int}", function(n, context) {
  expect_equal(context$value, n)
})
```

``` r

test("features", tags = "@smoke", reporter = CucumberPrettyReporter$new())
```

``` console-output
Feature: Tagged
  Scenario: Smoke and fast
    ✔ Given I have 1
    ✔ Then I get 1
  Scenario: Smoke and slow
    ✔ Given I have 2
    ✔ Then I get 2


────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  4 steps (4 passed)
  0m00.036s (executing steps: 0m00.005s)
────────────────────────────────────────────────────────────────────────────────
```

### Tag expressions

A tag expression is an infix boolean expression with the lowercase
operators `and`, `or` and `not`, and parentheses for grouping. `not`
binds tighter than `and`, and `and` tighter than `or`:

``` r

cucumber::test("tests/acceptance", tags = "(@smoke or @ui) and (not @slow)")
```

`AND` is read as a tag, so `@smoke AND @fast` is a syntax error.

#### Tag names

In a tag expression, a tag is everything up to whitespace or a
parenthesis. To use a parenthesis, whitespace or a backslash in a tag,
escape it with a backslash. In an R string the backslash itself is
escaped: `tags = "@wip\\(x\\)"`.

Tag names are case-sensitive: `@Smoke` and `@smoke` are different tags.

### Using tags for documentation

Tags can refer to IDs in external systems such as issue trackers, or
mark where a feature is in the development process:

``` gherkin
@BJ-x98.77 @qa_ready
Feature: Convert transaction
```

Custom reporting can turn these tags into links.

## Spoken Languages

The language you choose for Gherkin should be the same language your
users and domain experts use when they talk about the domain.

To write a feature file in another language, put a `# language:` header
on the first line, followed by the language code:

- features/addition.feature
- features/setup-steps.R
- Console

``` gherkin
# language: fr
Fonctionnalité: Addition
  Contexte:
    Soit I have 1

  Scénario: Adding one
    Quand I add 1
    Alors I should have 2

  Plan du scénario: Adding more
    Quand I add <n>
    Et I add <n>
    Alors I should have <total>

    Exemples:
      | n | total |
      | 2 | 5     |
```

``` r

given("I have {int}", function(n, context) {
  context$n <- n
})
when("I add {int}", function(n, context) {
  context$n <- context$n + n
})
then("I should have {int}", function(n, context) {
  expect_equal(context$n, n)
})
```

``` r

test("features", reporter = CucumberPrettyReporter$new())
```

``` console-output
Fonctionnalité: Addition
  Scénario: Adding one
    ✔ Soit I have 1
    ✔ Quand I add 1
    ✔ Alors I should have 2
  Plan du scénario: Adding more
    ✔ Soit I have 1
    ✔ Quand I add 2
    ✔ Et I add 2
    ✔ Alors I should have 5


────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  7 steps (7 passed)
  0m00.035s (executing steps: 0m00.010s)
────────────────────────────────────────────────────────────────────────────────
```

A file without the header is in the language of the `cucumber.language`
option, `"en"` by default, like `options(cucumber.language = "fr")`.
Every language from Cucumber’s
[gherkin-languages.json](https://github.com/cucumber/gherkin/blob/main/gherkin-languages.json)
is supported. See the [Gherkin
reference](https://cucumber.io/docs/gherkin/languages/) for the keywords
of each language.

Step definitions don’t change: steps are matched without their keyword,
so `given("I have {int}", ...)` matches `Soit I have 1`.

## Markdown with Gherkin

Feature files can be Markdown documents: `.feature.md` files, written in
[Markdown with
Gherkin](https://github.com/cucumber/gherkin/blob/main/MARKDOWN_WITH_GHERKIN.md).
They run like `.feature` files, and can be run together with them.

Use them when a specification should read as a document: it renders on
GitHub, on a pkgdown site or in any Markdown viewer, and it can have
prose, lists and tables between its scenarios that aren’t part of the
test.

A Markdown document is Gherkin with these changes:

- Headers are the `Feature`, `Rule`, `Background`, `Scenario`,
  `Scenario Outline` and `Examples`, like `# Feature: Basket` or
  `## Scenario: Add an item`.
- List items that start with a step keyword are steps, like
  `* Given an empty basket` or `- When I add an apple`. A list item that
  doesn’t start with a step keyword is ignored.
- Code blocks under a step are Doc Strings. Their language, like
  ```` ```json ````, is the Doc String’s media type.
- Tables indented 2 to 5 spaces are Data Tables, under a step, and
  Examples, under an `Examples` header. The separator row under the
  header, `| --- |`, isn’t a row. A table that isn’t indented, or is
  indented more, is ignored.
- Tags are written in backticks, on the line above the header they tag:
  `` `@smoke` ``.
- Everything else, like paragraphs, images and unindented tables, is
  ignored.

A Markdown document runs like a feature file:

- features/basket.feature.md
- features/setup-steps.R
- Console

``` markdown
# Feature: Basket

A basket holds the items a customer wants to buy.
This table isn't Gherkin, because it isn't indented:

| item  | price |
| ----- | ----- |
| apple | 1     |

## Scenario Outline: Add <n> apples

* Given an empty basket
* When I add <n> apples
* Then the basket has <n> items

### Examples:

  | n |
  | - |
  | 1 |
  | 2 |
```

``` r

given("an empty basket", function(context) {
  context$items <- 0
})
when("I add {int} apples", function(n, context) {
  context$items <- context$items + n
})
then("the basket has {int} items", function(n, context) {
  expect_equal(context$items, n)
})
```

``` r

test("features", reporter = CucumberPrettyReporter$new())
```

``` console-output
Feature: Basket
  Scenario Outline: Add 1 apples
    ✔ Given an empty basket
    ✔ When I add 1 apples
    ✔ Then the basket has 1 items
  Scenario Outline: Add 2 apples
    ✔ Given an empty basket
    ✔ When I add 2 apples
    ✔ Then the basket has 2 items


────────────────────────────────────────────────────────────────────────────────
Summary
  2 scenarios (2 passed)
  6 steps (6 passed)
  0m00.029s (executing steps: 0m00.005s)
────────────────────────────────────────────────────────────────────────────────
```

Code blocks and indented tables under a step are its Doc Strings and
Data Tables, and a code block’s language is in the Doc String’s
`media_type` attribute:

- features/basket.feature.md
- features/setup-steps.R
- Console

```` markdown
# Feature: Basket

## Scenario: Add items

* Given these items:
  | item   | price |
  | ------ | ----: |
  | apple  | 1     |
  | banana | 2     |
* When I add a note:
  ```json
  {"gift": true}
  ```
````

``` r

given("these items:", function(table, context) {
  expect_equal(table$item, c("apple", "banana"))
})
when("I add a note:", function(note, context) {
  expect_equal(as.character(note), '{"gift": true}')
  expect_equal(attr(note, "media_type"), "json")
})
```

``` r

test("features")
```

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               1 | Basket

────────────────────────────────────────────────────────────────────────────────
Summary
  1 scenario (1 passed)
  2 steps (2 passed)
  0m00.017s (executing steps: 0m00.002s)
────────────────────────────────────────────────────────────────────────────────
```

A Markdown document can’t start with `# language:`, as it would be a
header. Set the language of Markdown documents with the
`cucumber.language` option, like `options(cucumber.language = "fr")`.

The snapshots of `basket.feature.md` are in `_snaps/basket.feature.md`,
like those of `basket.feature`. So the two can’t be in the same
directory: the run stops with an error that names both.
