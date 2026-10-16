// expand.js — full-screen view for chart cards.
//
// Every `.mm-expandable` card gets an expand button. Clicking it (or pressing
// Enter/Space on it) opens the card in a centered overlay; the close button,
// clicking the backdrop, or Escape closes it. Clicks inside charts and maps are
// left alone so hovering, zooming and panning keep working.
(function () {
  "use strict";

  var ICON_EXPAND =
    '<svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true"><path fill="currentColor" d="M1.5 1h4a.5.5 0 0 1 0 1H2.7l3.6 3.6a.5.5 0 1 1-.7.7L2 2.7v2.8a.5.5 0 0 1-1 0v-4a.5.5 0 0 1 .5-.5Zm9 0h4a.5.5 0 0 1 .5.5v4a.5.5 0 0 1-1 0V2.7l-3.6 3.6a.5.5 0 1 1-.7-.7L13.3 2h-2.8a.5.5 0 0 1 0-1ZM6.3 9.7a.5.5 0 0 1 0 .7L2.7 14h2.8a.5.5 0 0 1 0 1h-4a.5.5 0 0 1-.5-.5v-4a.5.5 0 0 1 1 0v2.8l3.6-3.6a.5.5 0 0 1 .7 0Zm3.4 0a.5.5 0 0 1 .7 0l3.6 3.6v-2.8a.5.5 0 0 1 1 0v4a.5.5 0 0 1-.5.5h-4a.5.5 0 0 1 0-1h2.8l-3.6-3.6a.5.5 0 0 1 0-.7Z"/></svg>';

  function redraw(card) {
    // Let the CSS transition settle, then ask widgets to fit their new size.
    setTimeout(function () {
      if (window.Plotly) {
        card.querySelectorAll(".js-plotly-plot").forEach(function (el) {
          try { window.Plotly.Plots.resize(el); } catch (e) { /* ignore */ }
        });
      }
      card.querySelectorAll(".leaflet-container").forEach(function (el) {
        var widget = window.HTMLWidgets && window.HTMLWidgets.find("#" + el.id);
        var map = widget && widget.getMap && widget.getMap();
        if (map) map.invalidateSize(true);
      });
      window.dispatchEvent(new Event("resize"));
    }, 200);
  }

  function overlay() {
    var ov = document.querySelector(".mm-expand-overlay");
    if (!ov) {
      ov = document.createElement("div");
      ov.className = "mm-expand-overlay";
      ov.addEventListener("click", closeAll);
      document.body.appendChild(ov);
    }
    return ov;
  }

  function open(card) {
    closeAll();
    card.classList.add("expanded-widget");
    card.setAttribute("role", "dialog");
    card.setAttribute("aria-modal", "true");
    var btn = card.querySelector(".mm-expand-btn");
    if (btn) {
      btn.setAttribute("aria-label", "Close full-screen view");
      btn.innerHTML = "&times;";
    }
    overlay();
    document.body.classList.add("mm-noscroll");
    redraw(card);
  }

  function close(card) {
    card.classList.remove("expanded-widget");
    card.removeAttribute("role");
    card.removeAttribute("aria-modal");
    var btn = card.querySelector(".mm-expand-btn");
    if (btn) {
      btn.setAttribute("aria-label", "Expand to full screen");
      btn.innerHTML = ICON_EXPAND;
    }
    redraw(card);
  }

  function closeAll() {
    document.querySelectorAll(".expanded-widget").forEach(close);
    var ov = document.querySelector(".mm-expand-overlay");
    if (ov) ov.remove();
    document.body.classList.remove("mm-noscroll");
  }

  function attach(card) {
    if (card.querySelector(":scope > .mm-expand-btn")) return;
    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "mm-expand-btn";
    btn.setAttribute("aria-label", "Expand to full screen");
    btn.innerHTML = ICON_EXPAND;
    btn.addEventListener("click", function (ev) {
      ev.stopPropagation();
      if (card.classList.contains("expanded-widget")) closeAll();
      else open(card);
    });
    card.insertBefore(btn, card.firstChild);
  }

  function attachAll(root) {
    (root || document).querySelectorAll(".mm-expandable").forEach(attach);
  }

  document.addEventListener("DOMContentLoaded", function () {
    attachAll();
    // Cards rendered later (e.g. inside uiOutput) get buttons too.
    new MutationObserver(function (mutations) {
      mutations.forEach(function (m) {
        m.addedNodes.forEach(function (node) {
          if (node.nodeType !== 1) return;
          if (node.classList.contains("mm-expandable")) attach(node);
          attachAll(node);
        });
      });
    }).observe(document.body, { childList: true, subtree: true });
  });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") closeAll();
  });

  // Close any open card when switching tabs.
  document.addEventListener("shown.bs.tab", closeAll);
})();
