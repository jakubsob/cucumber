# When a step fails, attach a screenshot of the app and its logs to the step
after_step(function(context, step) {
  if (step$status == "failed" && !is.null(context$app)) {
    file <- tempfile(fileext = ".png")
    context$app$get_screenshot(file)
    context$attach(readBin(file, "raw", file.size(file)), "image/png", file_name = "screenshot.png")
    context$log(paste(format(context$app$get_logs()), collapse = "\n"))
  }
})

# Stop the app after each scenario
after(function(context, scenario) {
  if (!is.null(context$app)) context$app$stop()
})
