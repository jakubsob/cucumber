// Tabs that name the same thing, like Console, switch together across the page and the session.
document.addEventListener("DOMContentLoaded", function () {
  var buttons = Array.from(document.querySelectorAll(".ide-tabs [data-bs-toggle='tab']"));
  var label = function (b) { return b.textContent.trim(); };
  var show = function (name, except) {
    buttons.forEach(function (b) {
      if (b !== except && label(b) === name) bootstrap.Tab.getOrCreateInstance(b).show();
    });
  };
  var stored = function () {
    try { return sessionStorage.getItem("cucumber-tab"); } catch (e) { return null; }
  };
  buttons.forEach(function (b) {
    b.addEventListener("shown.bs.tab", function (e) {
      // Only labels like "Console" repeat; the feature and step files are named by their paths
      if (!e.isTrusted) return;
      try { sessionStorage.setItem("cucumber-tab", label(b)); } catch (err) {}
      show(label(b), b);
    });
  });
  var name = stored();
  if (name) show(name);
});

// The articles in the navbar's order, each with a link to the next and the previous.
document.addEventListener("DOMContentLoaded", function () {
  var main = document.querySelector("main");
  var links = Array.from(document.querySelectorAll(".navbar .dropdown-menu a[href*='articles/']"))
    .filter(function (a) { return !/migration/.test(a.getAttribute("href")); });
  if (!main || !/\/articles\//.test(location.pathname)) return;
  var here = links.findIndex(function (a) { return a.pathname === location.pathname; });
  if (here < 0) return;
  var pager = document.createElement("nav");
  pager.className = "article-pager";
  pager.setAttribute("aria-label", "Articles");
  [[here - 1, "prev", "Previous"], [here + 1, "next", "Next"]].forEach(function (p) {
    var a = links[p[0]];
    if (!a) return;
    var link = document.createElement("a");
    link.className = p[1];
    link.href = a.href;
    link.innerHTML = "<small>" + p[2] + "</small>" + a.textContent.trim();
    pager.appendChild(link);
  });
  main.appendChild(pager);
});

// Keywords in Gherkin examples link to their section of the Gherkin reference.
document.addEventListener("DOMContentLoaded", function () {
  var reference = document.querySelector(".navbar a[href$='reference-gherkin.html']");
  if (!reference) return;
  var sections = {
    "feature": "feature", "ability": "feature", "business need": "feature",
    "rule": "rule", "background": "background", "example": "example", "scenario": "example",
    "scenario outline": "scenario-outline", "scenario template": "scenario-outline",
    "examples": "examples", "scenarios": "examples",
    "given": "given", "when": "when", "then": "then", "and": "and-but", "but": "and-but", "*": "asterisk"
  };
  document.querySelectorAll("pre.gherkin code span.kw, pre.gherkin code span.fu").forEach(function (span) {
    var word = span.textContent.replace(/:$/, "");
    var id = sections[word.toLowerCase()];
    if (!id) return;
    var link = document.createElement("a");
    link.className = "gherkin-keyword";
    link.href = reference.href.replace(/#.*/, "") + "#" + id;
    link.textContent = span.textContent;
    span.textContent = "";
    span.appendChild(link);
  });
});
