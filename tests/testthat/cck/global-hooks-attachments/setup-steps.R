before_all(function(context) {
  context$attach("Attachment from BeforeAll hook", "text/plain")
})

when("a step passes", function(context) {})

after_all(function(context) {
  context$attach("Attachment from AfterAll hook", "text/plain")
})
