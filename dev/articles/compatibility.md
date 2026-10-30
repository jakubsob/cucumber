# Compatibility with Cucumber

cucumber doesn’t just follow the Cucumber documentation. Its tests run
the official projects’ own test data, copied from their repositories,
and expect the same results:

| Official project | What cucumber checks against it |
|----|----|
| [Compatibility Kit](https://github.com/cucumber/compatibility-kit) | Each of its 47 runnable samples runs with `CucumberMessagesReporter`, and the messages must be the ones the official implementations give: the same messages, in the same order, with the same ids, statuses, pickles, attachments and results. The JUnit XML of each sample is compared too |
| [Gherkin](https://github.com/cucumber/gherkin) | Every good and bad file of its test data must give the official source, document, pickles and errors |
| [Cucumber Expressions](https://github.com/cucumber/cucumber-expressions) | Its test data for matching, parsing and tokenizing must give the official results and errors |
| [Tag expressions](https://github.com/cucumber/tag-expressions) | Its evaluation test data |
| [Messages](https://github.com/cucumber/messages) | Every message cucumber writes must follow the official JSON schema |
| [HTML formatter](https://github.com/cucumber/html-formatter) | `CucumberHtmlReporter` embeds the official report |

The differences are few, and each is deliberate:

- Fields that depend on the machine or the language are not compared:
  where files are, timestamps, durations, error messages and stack
  traces, and the text of snippets, which are R code.
- R signals
  [`pending()`](https://jakubsob.github.io/cucumber/dev/reference/pending.md)
  and
  [`skip_scenario()`](https://jakubsob.github.io/cucumber/dev/reference/skip_scenario.md)
  as conditions, so those results have an exception, unlike the samples
  where the step returns the status.
- `{bigdecimal}` and `{biginteger}` aren’t built in, as R has no numbers
  of any precision.
- Cucumber’s Markdown parser gives a header-less first line a `Feature`
  without a keyword, which its own schema rejects. cucumber does the
  same and exempts that one document from the schema.

Step definitions are R functions, so what the official projects say
about types of a specific language, like Java’s, doesn’t apply.
