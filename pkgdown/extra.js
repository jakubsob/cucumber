// Highlight Gherkin blocks the way Cucumber's pretty reporter colours a run.
// ponytail: line-based regex tokeniser, swap for a real grammar if Gherkin blocks get exotic.
document.addEventListener("DOMContentLoaded", function () {
  var escape = function (s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  };
  var span = function (cls, s) {
    return '<span class="' + cls + '">' + s + "</span>";
  };
  var feature = /^(\s*)(Feature|Rule|Background|Scenario Outline|Scenario Template|Scenario|Example|Examples|Scenarios)(:)/;
  var step = /^(\s*)(Given|When|Then|And|But|\*)(\s)/;
  var inline = function (s) {
    return escape(s)
      .replace(/"[^"]*"/g, function (m) { return span("gk-string", m); })
      .replace(/&lt;[^&\s]+&gt;/g, function (m) { return span("gk-param", m); })
      .replace(/(^|\s)\|(?=\s|$)/g, function (m, pre) { return pre + span("gk-pipe", "|"); });
  };
  var line = function (l) {
    var m;
    if (/^\s*#/.test(l)) return span("gk-comment", escape(l));
    if (/^\s*@/.test(l)) return escape(l).replace(/@\S+/g, function (t) { return span("gk-tag", t); });
    if ((m = l.match(feature))) return m[1] + span("gk-feature", m[2] + m[3]) + inline(l.slice(m[0].length));
    if ((m = l.match(step))) return m[1] + span("gk-step", m[2]) + inline(l.slice(m[1].length + m[2].length));
    return inline(l);
  };
  document.querySelectorAll("pre.gherkin > code").forEach(function (code) {
    code.innerHTML = code.textContent.split("\n").map(line).join("\n");
  });
});
