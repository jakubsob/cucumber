if (covr::in_covr()) {
  cucumber::test(
    ".",
    "steps/",
    steps_loader =  function(steps_dir) {
      get_steps()
    }
  )
} else {
  cucumber::test(".", "steps/")
}
