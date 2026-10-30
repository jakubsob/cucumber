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

// A stepper over a run: each frame of its JSON says which feature and code lines are in play,
// the state of `context` and the messages emitted so far. Play steps through them on a timer.
document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll(".stepper").forEach(function (root) {
    var data = JSON.parse(root.querySelector("script[type='application/json']").textContent);
    var frames = data.frames;
    var el = function (tag, cls, text) {
      var e = document.createElement(tag);
      if (cls) e.className = cls;
      if (text !== undefined) e.textContent = text;
      return e;
    };
    var pane = function (title, cls) {
      var box = el("div", "stepper-pane " + cls);
      box.appendChild(el("div", "stepper-title", title));
      var body = el("pre", "stepper-body");
      box.appendChild(body);
      return { box: box, body: body };
    };
    var lines = function (pane, source) {
      return source.map(function (text) {
        var line = el("span", "stepper-line", text);
        pane.body.appendChild(line);
        return line;
      });
    };
    var feature = pane(data.featureFile || "features/basket.feature", "stepper-feature");
    var code = pane(data.codeFile || "features/setup-basket.R", "stepper-code");
    var context = pane("context", "stepper-context");
    var log = pane("messages", "stepper-log");
    var featureLines = lines(feature, data.feature);
    var codeLines = lines(code, data.code);

    var title = el("div", "stepper-heading");
    var comment = el("p", "stepper-comment");
    comment.setAttribute("aria-live", "polite");
    var counter = el("span", "stepper-counter");
    var button = function (label, onclick) {
      var b = el("button", "stepper-button", label);
      b.type = "button";
      b.addEventListener("click", onclick);
      return b;
    };
    var timer = null;
    var index = 0;
    var stop = function () {
      clearInterval(timer);
      timer = null;
      play.textContent = "Play";
    };
    var show = function (i) {
      index = Math.max(0, Math.min(frames.length - 1, i));
      var frame = frames[index];
      var start = index;
      while (start > 0 && !frames[start].r) start--;
      var passed = frames.slice(start, index + 1).map(function (f) { return f.p; });
      featureLines.forEach(function (l, n) {
        l.classList.toggle("active", (frame.f || []).indexOf(n + 1) >= 0);
        l.classList.toggle("passed", passed.indexOf(n + 1) >= 0);
      });
      codeLines.forEach(function (l, n) {
        l.classList.toggle("active", (frame.k || []).indexOf(n + 1) >= 0);
      });
      var last = frames.slice(0, index + 1).filter(function (f) { return f.x !== undefined; }).pop();
      context.body.textContent = last ? last.x : "(no context yet)";
      log.body.textContent = frames.slice(0, index + 1).reduce(function (all, f) {
        return all.concat(f.m || []);
      }, []).join("\n");
      log.body.scrollTop = log.body.scrollHeight;
      title.textContent = frame.t;
      comment.innerHTML = frame.c;
      counter.textContent = (index + 1) + " / " + frames.length;
      prev.disabled = index === 0;
      next.disabled = index === frames.length - 1;
      if (next.disabled) stop();
    };
    var prev = button("Previous", function () { stop(); show(index - 1); });
    var next = button("Next", function () { stop(); show(index + 1); });
    var play = button("Play", function () {
      if (timer) return stop();
      if (index === frames.length - 1) show(0);
      play.textContent = "Pause";
      timer = setInterval(function () { show(index + 1); }, 3000);
    });
    var restart = button("Restart", function () { stop(); show(0); });

    var controls = el("div", "stepper-controls");
    [prev, play, next, restart, counter].forEach(function (c) { controls.appendChild(c); });
    var grid = el("div", "stepper-grid");
    var left = el("div", "stepper-col");
    left.appendChild(feature.box);
    var right = el("div", "stepper-col");
    right.appendChild(context.box);
    right.appendChild(log.box);
    grid.appendChild(left);
    grid.appendChild(right);
    [controls, title, comment, code.box, grid].forEach(function (c) { root.appendChild(c); });
    root.tabIndex = 0;
    root.addEventListener("keydown", function (e) {
      if (e.key === "ArrowRight") { stop(); show(index + 1); }
      if (e.key === "ArrowLeft") { stop(); show(index - 1); }
    });
    show(0);
  });
});
