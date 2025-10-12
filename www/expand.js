// expand.js
// Improved widget expansion: double-click to expand/collapse a .mm-card.
// On expand: apply .expanded-widget and trigger precise Plotly relayout and resize.
// On collapse: revert margins and resize smaller.

(function(){
  function resizePlotly(el, expanded){
    if (!el || typeof Plotly === 'undefined') return;
    try {
      // Plotly may be attached to a container or directly to the graph div
      var graphDiv = el.querySelector ? el.querySelector('.plotly-graph-div') : el;
      if (!graphDiv) return;
      // first, resize to container
      Plotly.Plots.resize(graphDiv);
      // then adjust margins: fuller margins when expanded, tighter when collapsed
      if (expanded) {
        Plotly.relayout(graphDiv, { 'margin.l': 48, 'margin.r': 48, 'margin.t': 48, 'margin.b': 48 });
      } else {
        Plotly.relayout(graphDiv, { 'margin.l': 36, 'margin.r': 18, 'margin.t': 18, 'margin.b': 18 });
      }
    } catch(e) {
      // ignore errors
    }
  }

  function resizeLeaflet(container){
    var leaf = container.querySelector('.leaflet-container');
    if (leaf && leaf._leaflet_map) {
      try { leaf._leaflet_map.invalidateSize(true); } catch(e) {}
    }
  }

  function triggerResizes(container, expanded){
    // Plotly widgets
    var plots = container.querySelectorAll('.plotly');
    plots.forEach(function(p){ resizePlotly(p, expanded); });
    // Leaflet maps
    resizeLeaflet(container);
    // final window resize event to allow other widgets to react
    setTimeout(function(){ window.dispatchEvent(new Event('resize')); }, 140);
  }

  function findCard(node){
    var el = node;
    while(el && !el.classList.contains('mm-card')) el = el.parentElement;
    return el || null;
  }

  // configurable hover delay (ms); can be tuned globally
  var MM_HOVER_DELAY_MS = 500;

  function toggleCard(card){
    if (!card) return;
    var willExpand = !card.classList.contains('expanded-widget');
    if (willExpand) {
      card.classList.add('expanded-widget');
      // create a close button if not present
      if (!card.querySelector('.expand-close')) {
        var btn = document.createElement('button');
        btn.className = 'expand-close';
        btn.setAttribute('aria-label', 'Close expanded view');
        btn.innerHTML = '&times;';
        btn.addEventListener('click', function(ev){ ev.stopPropagation(); card.classList.remove('expanded-widget'); triggerResizes(card, false); btn.remove(); removeOverlay(); });
        card.appendChild(btn);
      }
      // show overlay when a card expands
      showOverlay();
    } else {
      card.classList.remove('expanded-widget');
      var existing = card.querySelector('.expand-close'); if (existing) existing.remove();
      // remove overlay when collapsing
      removeOverlay();
    }
    // give CSS transition a moment to apply then redraw widgets
    setTimeout(function(){ triggerResizes(card, willExpand); }, willExpand ? 180 : 260);
  }

  function attach(){
    var cards = document.querySelectorAll('.mm-card');
    cards.forEach(function(card){
      // Skip attaching expansion behavior when a card is explicitly opted-out
      if (card.classList && (card.classList.contains('mm-feature') || card.classList.contains('mm-no-expand'))) return;
      if (card._expandAttached) return;
      card._expandAttached = true;
      // dblclick remains as a fallback/power-user gesture
      card.addEventListener('dblclick', function(e){
        var c = findCard(e.target) || card;
        toggleCard(c);
      });
      // Global single-click expand (ignore clicks on links/buttons/inputs)
      card.addEventListener('click', function(e){
        var tag = (e.target && e.target.tagName) ? e.target.tagName.toLowerCase() : '';
        if (tag === 'a' || tag === 'button' || tag === 'input' || (e.target.closest && e.target.closest('a, button, input'))) return;
        var c = findCard(e.target) || card;
        toggleCard(c);
      });
    });
  }

  document.addEventListener('DOMContentLoaded', function(){
    attach();
    // also try re-attaching after UI changes
    setTimeout(attach, 900);
  });

  // ESC key closes expanded cards
  document.addEventListener('keydown', function(e){
    if (e.key === 'Escape'){
      document.querySelectorAll('.expanded-widget').forEach(function(card){
        card.classList.remove('expanded-widget');
        triggerResizes(card, false);
      });
      removeOverlay();
    }
  });

  // Overlay helpers
  function showOverlay(){
    if (document.querySelector('.mm-expand-overlay')) return;
    var ov = document.createElement('div');
    ov.className = 'mm-expand-overlay';
    ov.style.position = 'fixed';
    ov.style.top = '0';
    ov.style.left = '0';
    ov.style.right = '0';
    ov.style.bottom = '0';
    ov.style.background = 'rgba(0,0,0,0.45)';
    ov.style.zIndex = '99990';
    ov.addEventListener('click', function(){
      // clicking overlay closes expanded cards
      document.querySelectorAll('.expanded-widget').forEach(function(card){ card.classList.remove('expanded-widget'); triggerResizes(card, false); });
      removeOverlay();
    });
    document.body.appendChild(ov);
  }

  function removeOverlay(){
    var ov = document.querySelector('.mm-expand-overlay'); if (ov) ov.remove();
  }

  window.__maquerina_attach_expand = attach;
})();
