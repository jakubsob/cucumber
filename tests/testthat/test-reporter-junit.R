# The JUnit XML of each sample of the Cucumber Compatibility Kit, in
# tests/testthat/cck, must be the one of the official formatter: its test
# data, in junit.xml, copied by update_junit_xml() in R/tools-update_junit_xml.R.
skip_if_not_installed("jsonlite")

describe("CucumberJunitReporter", {
  for (sample in fs::dir_ls(test_path("cck"), type = "directory")) {
    it(paste("writes the JUnit XML of", fs::path_file(sample)), {
      output <- withr::local_tempfile(fileext = ".xml")

      CucumberJunitReporter$new(output)$report(fs::dir_ls(sample, glob = "*.ndjson"))

      expect_equal(readLines(output, warn = FALSE), readLines(fs::path(sample, "junit.xml"), warn = FALSE))
    })
  }
})
