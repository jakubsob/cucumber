# Migration to cucumber 2.0.0

Cucumber 2.0.0 introduces a new way of running specifications. Instead
of relying on `testthat` or `devtools` test commands to run the tests,
cucumber now owns the test execution process.

Follow the steps below to migrate your cucumber tests to the new
version.

## 1. Remove `test-cucumber.R` file.

In the previous versions, you had to create a `test-cucumber.R` file
with
[`cucumber::test()`](https://jakubsob.github.io/cucumber/reference/test.md)
call to run the tests.

Now, you can run the tests directly from the console or from the R
script using the same
[`cucumber::test()`](https://jakubsob.github.io/cucumber/reference/test.md)
function. It now has a new interface and behavior that very similar to
`devtools::test` and
[`testthat::test_package`](https://testthat.r-lib.org/reference/test_package.html)
as it now also calls
[`testthat::test_dir`](https://testthat.r-lib.org/reference/test_dir.html)
internally.

## 2. Move steps definitions to [`setup-*.R` files](https://testthat.r-lib.org/articles/special-files.html#setup-files).

[`cucumber::test()`](https://jakubsob.github.io/cucumber/reference/test.md)
no longer is responsible for loading step definitions.

Instead it is recommended to store step definitions in
[`setup-*.R`](https://testthat.r-lib.org/articles/special-files.html#setup-files)
files in tests directory, alongside `.feature` files.

Convert your directory structure from:

    tests/
    ├── acceptance/
    │   ├── steps/
    │   │   ├── steps1.R
    │   │   ├── steps2.R
    │   ├── feature1.feature
    │   ├── feature2.feature

to

    tests/
    ├── acceptance/
    │   ├── feature1.feature
    │   ├── feature2.feature
    │   ├── setup-steps1.R
    │   ├── setup-steps2.R

All `test-*.R` files that are in the directory will be ignored by
[`cucumber::test()`](https://jakubsob.github.io/cucumber/reference/test.md).
To run them use another call to
[`testthat::test_dir()`](https://testthat.r-lib.org/reference/test_dir.html).
