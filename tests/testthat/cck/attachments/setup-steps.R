when("the string {string} is attached as {string}", function(text, media_type, context) {
  context$attach(text, media_type)
})

when("the string {string} is logged", function(text, context) {
  context$log(text)
})

when("text with ANSI escapes is logged", function(context) {
  context$log(
    "This displays a \033[31mr\033[0m\033[91ma\033[0m\033[33mi\033[0m\033[32mn\033[0m\033[34mb\033[0m\033[95mo\033[0m\033[35mw\033[0m"
  )
})

when("the following string is attached as {string}:", function(media_type, text, context) {
  context$attach(text, media_type)
})

when("an array with {int} bytes is attached as {string}", function(size, media_type, context) {
  context$attach(as.raw(seq_len(size) - 1), media_type)
})

when("a PDF document is attached and renamed", function(context) {
  context$attach(readBin("document.pdf", "raw", file.size("document.pdf")), "application/pdf", file_name = "renamed.pdf")
})

when("a link to {string} is attached", function(uri, context) {
  context$link(uri)
})

when("the string {string} is attached as {string} before a failure", function(text, media_type, context) {
  context$attach(text, media_type)
  stop("whoops")
})
