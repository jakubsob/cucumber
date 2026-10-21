# nocov start
# Updates the parts of the Gherkin parser that come from the official one:
# R/gherkin_states.R, its state machine, R/sysdata.rda, the keywords of every
# language, and tests/testthat/gherkin, its test data. It's internal, call it from the package root:
#
#   devtools::load_all()
#   update_gherkin()            # latest main
#   update_gherkin("v32.1.0")   # a tag or a commit
#
#
# How the official parser is made
# -------------------------------
#
# The Gherkin grammar lives in gherkin.berp in https://github.com/cucumber/gherkin.
# It is written for berp (https://github.com/gasparnagy/berp), a parser
# generator in C#:
#
#   Feature! := FeatureHeader Background? ScenarioDefinition* Rule*
#   ScenarioDefinition! [#Empty|#Comment|#TagLine->#ScenarioLine] := Tags? Scenario
#
# - `#Name` is a token type: one line, classified by the token matcher.
# - `!` marks a rule that becomes an AST node (startRule/endRule).
# - `[... -> #ScenarioLine]` is a lookahead hint: a tag line is ambiguous, so
#   the parser reads past empty lines, comments and tags to see what follows.
#
# berp compiles the grammar into a state machine and renders it through a
# template per language, into Parser.ts, Parser.java, Parser.cs, ... Each
# state is one function that tries token types in a fixed order:
#
#   private matchTokenAt_3(token, context) {
#     if(this.match_TagLine(context, token)) {
#       if(this.lookahead_0(context, token)) {
#         this.endRule(context);
#         this.startRule(context, RuleType.ScenarioDefinition);
#         this.startRule(context, RuleType.Tags);
#         this.build(context, token);
#         return 11;
#       }
#     }
#     ...
#     const expectedTokens = ["#EOF", "#Empty", ...];
#
# What this script does
# ---------------------
#
# It reads the generated JavaScript parser with regular expressions and
# writes each state as data:
#
#   `3` = list(
#     transitions = list(
#       list("TagLine", 0L, c("end", "start:ScenarioDefinition", "start:Tags", "build"), 11L),
#       ...
#     ),
#     expected = c("#EOF", "#Empty", ...)
#   )
#
# match_token_at() in R/gherkin.R interprets it. For each transition in
# order, it tries the token matcher, then the lookahead if there is one, then
# runs the actions (`start:X` pushes an AST node, `end` pops and transforms
# one, `build` adds the token) and moves to the next state. If no transition
# matches, it records `expected: <expected>, got '<line>'` and stays in the
# state, which is the official error recovery.
#
# Why the official state machine and not a hand-written parser
# ------------------------------------------------------------
#
# A hand-written parser in R would be shorter to read, but it would be our
# own reading of the grammar, and the goal is to behave like the official
# parser:
#
# - Error messages list the tokens each state expects, in the official order
#   (`expected: #EOF, #TableRow, ..., got '...'`), and after an error the
#   parser stays in the same state and keeps going, so it reports every error
#   at once. Matching that by hand means rebuilding the state machine anyway.
# - Edge cases come from the grammar's details, and a hand-written parser
#   gets them subtly different: a tag line is resolved by lookahead to belong
#   to the next Scenario, Examples or Rule; a step-like line right after
#   `Scenario:` is a description but after a step is an error; a Scenario
#   after a Rule belongs to the Rule; a step can have a Data Table and a Doc
#   String in either order.
# - The previous parser was hand-written. It decided structure by indentation
#   and dropped steps, Doc String lines and tables without an error.
# - With the official states, the official test data passes unchanged (the
#   pickles and the exact error messages), and updating to a new Gherkin
#   version is regenerating a table, not re-deriving parser logic.
#
# Why Parser.ts and not gherkin.berp
# ----------------------------------
#
# The grammar only says what is valid. Compiling it is berp's work: numbering
# the states, finding which tokens may follow each one (including after
# optional and repeated parts end), the end/start sequences, the order the
# matchers are tried in (`Other` matches any line, so it goes last), and the
# expected tokens that make up error messages. Doing that in R would mean
# reimplementing berp, and any difference would change parses and errors.
# Parser.ts is berp's output, so copying it gives the official behaviour.
#
# The proper alternative is a gherkin-r.razor template for berp, like the
# official gherkin-javascript.razor. It needs a .NET toolchain, so it is worth
# it only if this script stops working.
#
# Limits
# ------
#
# The script relies on the layout of the generated code: `if(this.match_X(`,
# `if(this.lookahead_N(`, `this.startRule(context, RuleType.X)`,
# `this.endRule(`, `this.build(`, `return N;` and `const expectedTokens = [...]`,
# one per line. If berp changes it, the script stops instead of writing an
# incomplete table:
#
# - every `return N;` of a state, except the last one after the error, must
#   have become a transition;
# - every state must have one `const expectedTokens` line;
# - inside a transition, a `this.` line must be a known action. An unknown
#   action, or a `return` the script doesn't recognize, leaves the transition
#   open until the next `this.` line, so it fails there.
#
# What is not generated
# ---------------------
#
# These are ported by hand and must be updated by hand:
#
# - TOKEN_MATCHERS, tag_items(), table_cells() in R/gherkin.R, from
#   GherkinClassicTokenMatcher.ts and GherkinLine.ts
# - MARKDOWN_TOKEN_MATCHERS in R/gherkin_markdown.R, from
#   GherkinInMarkdownTokenMatcher.ts
# - lookahead() in R/gherkin.R, from lookahead_0/lookahead_1 in Parser.ts
# - transform_node() and table_rows() in R/gherkin.R, from AstBuilder.ts
# - create_pickles(), pickle_steps() and interpolate() in R/pickle.R, from
#   pickles/compile.ts
#
# Updating to a new version of the official parser
# ------------------------------------------------
#
# update_gherkin() does everything that doesn't need a person:
#
# 1. Clones https://github.com/cucumber/gherkin at `ref`.
# 2. Regenerates R/gherkin_states.R from javascript/src/Parser.ts, with the
#    commit in its header.
# 3. Replaces the official test data in tests/testthat/gherkin: the good
#    *.feature files with their .ast.ndjson, .pickles.ndjson and
#    .source.ndjson, the good *.feature.md files the same way, and the bad
#    ones with their .errors.ndjson. scenario_outline_with_value_with_* are
#    renamed to outline_value_with_*, because R CMD check flags paths over
#    100 bytes. It stops if another path is too long.
# 4. Regenerates GHERKIN_DIALECTS in R/sysdata.rda, the keywords of every
#    language, from gherkin-languages.json.
# 5. Writes the changes to the hand-ported files since the commit the states
#    were generated from to a patch file, and returns its path.
# 6. Runs the corpus tests, testthat::test_local(filter = "gherkin"). They compare
#    sources, documents, pickles and exact error messages for every file.
#
# Then port what the patch shows. A new token type needs an entry in
# TOKEN_MATCHERS, a new rule type a case in transform_node() (unless keeping
# the node as is works), a new lookahead a target in lookahead(). Rerun the
# corpus tests until they pass, then devtools::check() and the acceptance
# tests.

GHERKIN_REPO <- "https://github.com/cucumber/gherkin.git"

# Files ported by hand, see "What is not generated"
HAND_PORTED <- c(
  "javascript/src/GherkinClassicTokenMatcher.ts",
  "javascript/src/GherkinInMarkdownTokenMatcher.ts",
  "javascript/src/GherkinLine.ts",
  "javascript/src/AstBuilder.ts",
  "javascript/src/pickles/compile.ts"
)

#' Update the parser from the official Gherkin parser
#'
#' See the comment at the top of R/tools-update_gherkin.R.
#'
#' @param ref Branch, tag or commit of https://github.com/cucumber/gherkin.
#' @param pkg Path to the package source.
#' @return Path to the patch of the hand-ported files to port, invisibly.
#' @keywords internal
#' @noRd
update_gherkin <- function(ref = "main", pkg = ".") {
  repo <- file.path(tempdir(), "gherkin")
  unlink(repo, recursive = TRUE)
  run_git("clone", "--quiet", "--filter=blob:none", GHERKIN_REPO, repo)
  run_git("-C", repo, "checkout", "--quiet", ref)
  commit <- run_git("-C", repo, "rev-parse", "--short", "HEAD")

  states <- file.path(pkg, "R", "gherkin_states.R")
  previous <- sub(
    ".*commit ([0-9a-f]+).*",
    "\\1",
    readLines(states, n = 2)[[2]]
  )

  write_states(
    file.path(repo, "javascript", "src", "Parser.ts"),
    commit,
    states
  )
  copy_test_data(repo, file.path(pkg, "tests", "testthat", "gherkin"))
  write_dialects(
    file.path(repo, "gherkin-languages.json"),
    file.path(pkg, "R", "sysdata.rda")
  )
  patch <- hand_ported_changes(repo, previous, commit)

  testthat::test_local(pkg, filter = "gherkin")
  invisible(patch)
}

run_git <- function(...) {
  args <- c(...)
  out <- suppressWarnings(system2("git", args, stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(out, "status"))) {
    stop(
      "git ",
      paste(args, collapse = " "),
      " failed:\n",
      paste(out, collapse = "\n")
    )
  }
  out
}

copy_test_data <- function(repo, to) {
  expected <- list(
    good = c(".ast.ndjson", ".pickles.ndjson", ".source.ndjson"),
    bad = ".errors.ndjson"
  )
  for (kind in names(expected)) {
    from <- file.path(repo, "testdata", kind)
    features <- list.files(from, pattern = "\\.feature(\\.md)?$")
    names <- sub(
      "^scenario_outline_with_value_with_",
      "outline_value_with_",
      features
    )

    long <- paste0(
      "cucumber/tests/testthat/gherkin/",
      kind,
      "/",
      rep(names, each = length(expected[[kind]])),
      expected[[kind]]
    )
    long <- long[nchar(long, type = "bytes") > 100]
    if (length(long) > 0) {
      stop(
        "Paths over 100 bytes, add a rename to copy_test_data():\n",
        paste(long, collapse = "\n")
      )
    }

    out <- file.path(to, kind)
    unlink(out, recursive = TRUE)
    dir.create(out, recursive = TRUE)
    copied <- file.copy(
      file.path(from, c(features, outer(features, expected[[kind]], paste0))),
      file.path(out, c(names, outer(names, expected[[kind]], paste0)))
    )
    if (!all(copied)) {
      stop("Missing official ", kind, " test data files")
    }
  }
  file.copy(
    file.path(repo, "LICENSE"),
    file.path(to, "LICENSE"),
    overwrite = TRUE
  )
}

# Keywords of every language, like the dialects of GherkinClassicTokenMatcher.ts.
# A step keyword of more than one type (like `* `) has an unknown type, and
# step keywords are tried longest first.
read_dialects <- function(languages) {
  lapply(jsonlite::read_json(languages), \(dialect) {
    titles <- list(
      FeatureLine = unlist(dialect$feature),
      RuleLine = unlist(dialect$rule),
      BackgroundLine = unlist(dialect$background),
      ScenarioLine = c(unlist(dialect$scenario), unlist(dialect$scenarioOutline)),
      ExamplesLine = unlist(dialect$examples)
    )
    types <- c(
      given = "Context",
      when = "Action",
      then = "Outcome",
      and = "Conjunction",
      but = "Conjunction"
    )
    keywords <- unlist(lapply(names(types), \(type) unlist(dialect[[type]])))
    keyword_types <- rep(
      types,
      vapply(names(types), \(type) length(dialect[[type]]), integer(1))
    )
    steps <- unique(keywords)
    steps <- steps[order(-nchar(steps))]
    steps <- vapply(
      steps,
      \(keyword) {
        type <- keyword_types[keywords == keyword]
        if (length(type) > 1) "Unknown" else unname(type)
      },
      character(1)
    )
    list(titles = titles, steps = steps)
  })
}

write_dialects <- function(languages, out) {
  GHERKIN_DIALECTS <- read_dialects(languages)
  save(GHERKIN_DIALECTS, file = out, compress = "xz")
}

hand_ported_changes <- function(repo, from, to) {
  patch <- file.path(tempdir(), "gherkin-hand-ported.diff")
  writeLines(run_git("-C", repo, "diff", from, to, "--", HAND_PORTED), patch)
  stat <- run_git("-C", repo, "diff", "--stat", from, to, "--", HAND_PORTED)
  if (length(stat) == 0) {
    message("No changes to port by hand between ", from, " and ", to, ".")
  } else {
    message(
      "Port these changes by hand, see ",
      patch,
      ":\n",
      paste(stat, collapse = "\n")
    )
  }
  patch
}


write_states <- function(parser, commit, out) {
  source <- readLines(parser)

  starts <- grep("^  private matchTokenAt_\\d+\\(", source)
  ends <- c(starts[-1], grep("^  private match_EOF\\(", source)) - 1

  quote <- function(x) paste0('"', x, '"', collapse = ", ")

  states <- vapply(
    seq_along(starts),
    function(i) {
      body <- trimws(source[starts[i]:ends[i]])
      state <- sub(".*matchTokenAt_(\\d+)\\(.*", "\\1", body[1])
      comment <- sub("^\\s*//\\s*", "", source[starts[i] - 1])
      transitions <- character()
      match <- NA_character_
      lookahead <- "NA"
      actions <- character()
      for (line in body) {
        if (grepl("^if\\(this\\.match_", line)) {
          match <- sub("^if\\(this\\.match_(\\w+)\\(.*", "\\1", line)
          lookahead <- "NA"
          actions <- character()
        } else if (grepl("^if\\(this\\.lookahead_", line)) {
          lookahead <- paste0(
            sub("^if\\(this\\.lookahead_(\\d+)\\(.*", "\\1", line),
            "L"
          )
        } else if (grepl("^this\\.startRule\\(", line)) {
          actions <- c(
            actions,
            sub(".*RuleType\\.(\\w+)\\).*", "start:\\1", line)
          )
        } else if (grepl("^this\\.endRule\\(", line)) {
          actions <- c(actions, "end")
        } else if (grepl("^this\\.build\\(", line)) {
          actions <- c(actions, "build")
        } else if (grepl("^this\\.", line) && !is.na(match)) {
          stop(
            "State ",
            state,
            ": unexpected line in a transition `",
            line,
            "`"
          )
        } else if (grepl("^return \\d+;", line) && !is.na(match)) {
          to <- sub("^return (\\d+);.*", "\\1", line)
          transitions <- c(
            transitions,
            sprintf(
              "      list(\"%s\", %s, c(%s), %sL)",
              match,
              lookahead,
              quote(actions),
              to
            )
          )
          match <- NA_character_
        }
      }
      # Every state ends with one more return, after the error
      returns <- sum(grepl("^return \\d+;", body))
      if (length(transitions) != returns - 1) {
        stop(
          "State ",
          state,
          ": ",
          returns - 1,
          " transitions, ",
          length(transitions),
          " parsed"
        )
      }
      expected <- grep("const expectedTokens", body, value = TRUE)
      if (length(expected) != 1) {
        stop("State ", state, ": ", length(expected), " expectedTokens lines")
      }
      expected <- sub(".*= \\[(.*)\\];", "\\1", expected)
      sprintf(
        "  # %s\n  `%s` = list(\n    transitions = list(\n%s\n    ),\n    expected = c(%s)\n  )",
        comment,
        state,
        paste(transitions, collapse = ",\n"),
        expected
      )
    },
    character(1)
  )

  writeLines(
    c(
      "# Generated by update_gherkin() in R/tools-update_gherkin.R from the official",
      paste0(
        "# Gherkin parser (cucumber/gherkin, javascript/src/Parser.ts, commit ",
        commit,
        "). Do not edit by hand."
      ),
      "#",
      "# Each state lists the token types it accepts, in the order they are tried.",
      "# A transition is list(token type, lookahead or NA, actions, next state).",
      "GHERKIN_STATES <- list(",
      paste(states, collapse = ",\n"),
      ")"
    ),
    out
  )
}
# nocov end
