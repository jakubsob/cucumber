.with_example_dir <- function(path, code) {
  withr::with_dir(
    system.file(fs::path("examples", path), package = "cucumber"),
    code
  )
}

.expect_snapshot <- purrr::partial(
  testthat::expect_snapshot,
  transform = function(lines) {
    lines |>
      # Remove pickle IDs which are generated dynamically
      stringr::str_replace_all("pickle-\\d+", "pickle-<id>")
  }
)

describe("preview", {
  it("should preview a simple feature", {
    .with_example_dir("one_feature", {
      result <- preview("tests/acceptance")
      .expect_snapshot(print(result))
    })
  })

  it("should preview with file filter", {
    .with_example_dir("multiple_features", {
      result <- preview("tests/acceptance", filter = "addition")
      .expect_snapshot(print(result))
    })
  })

  it("should preview scenario outlines with expanded examples", {
    .with_example_dir("scenario_outline", {
      result <- preview("tests/acceptance")
      .expect_snapshot(print(result))
    })
  })

  it("should preview with tag filter", {
    .with_example_dir("tags", {
      result <- preview("tests/acceptance", tags = "@fast")
      .expect_snapshot(print(result))
    })
  })

  it("should preview with complex tag expression", {
    .with_example_dir("tags", {
      result <- preview("tests/acceptance", tags = "@smoke and not @slow")
      .expect_snapshot(print(result))
    })
  })

  it("should show step details including data tables", {
    .with_example_dir("table", {
      result <- preview("tests/acceptance")
      .expect_snapshot(print(result))
    })
  })

  it("should show step details including docstrings", {
    .with_example_dir("docstring", {
      result <- preview("tests/acceptance")
      .expect_snapshot(print(result))
    })
  })

  it("should error when no feature files found", {
    .with_example_dir("one_feature", {
      expect_error(preview("nonexistent_directory"), "no such file or directory")
    })
  })
})
