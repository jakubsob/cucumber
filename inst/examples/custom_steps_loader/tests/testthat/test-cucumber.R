options(box.path = system.file("examples/custom_steps_loader", package = "cucumber"))
box::purge_cache()

box::use(
  cucumber[test],
)

test(
  ".",
  "./cucumber",
  steps_loader = function(steps_dir) {
    box::use(tests/testthat/cucumber[steps])
    steps
  }
)
