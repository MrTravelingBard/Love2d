/*
 * mobile-controls.js
 * Phone-friendly sizing and on-screen controls for a love.js web build.
 *
 * - Only activates when the main pointer is touch ("pointer: coarse").
 *   Add ?touch=1 to the URL to force it on (desktop testing) or ?touch=0 to force it off.
 * - Buttons send real keyboard events, so the game needs no changes:
 *       d-pad -> arrow keys    z -> "z"    x -> "x"    start -> Enter ("return" in LÖVE)
 * - The game canvas is scaled with CSS to the largest whole-pixel multiple of the
 *   game's logical resolution that fits, so pixel art stays crisp.
 *
 * Injected by tools/postbuild.js. Logical resolution comes from data-grid (default 128).
 */
(function () {
  'use strict';

  var script = document.currentScript;
  var GRID = parseInt(script && script.getAttribute('data-grid'), 10) || 128;

  var forced = new URLSearchParams(location.search).get('touch');
  var isTouch = forced === '1' ||
    (forced !== '0' && window.matchMedia && window.matchMedia('(pointer: coarse)').matches);
  if (!isTouch) return;

  var canvas = document.getElementById('canvas');
  var html = document.documentElement;

  /* ---------- key injection ---------- */
  var KEYS = {
    left:  { key: 'ArrowLeft',  code: 'ArrowLeft',  kc: 37 },
    up:    { key: 'ArrowUp',    code: 'ArrowUp',    kc: 38 },
    right: { key: 'ArrowRight', code: 'ArrowRight', kc: 39 },
    down:  { key: 'ArrowDown',  code: 'ArrowDown',  kc: 40 },
    z:     { key: 'z',          code: 'KeyZ',       kc: 90 },
    x:     { key: 'x',          code: 'KeyX',       kc: 88 },
    start: { key: 'Enter',      code: 'Enter',      kc: 13 }
  };
  var down = {};

  function fire(type, name) {
    var k = KEYS[name];
    var e = new KeyboardEvent(type, {
      key: k.key, code: k.code, keyCode: k.kc, which: k.kc, bubbles: true, cancelable: true
    });
    if (e.keyCode !== k.kc) { // some browsers ignore keyCode in the init dict
      try {
        Object.defineProperty(e, 'keyCode', { get: function () { return k.kc; } });
        Object.defineProperty(e, 'which', { get: function () { return k.kc; } });
      } catch (err) { /* ignore */ }
    }
    (canvas || document).dispatchEvent(e); // bubbles to document and window
  }

  function mark(name, on) {
    var el = root.querySelector('[data-k="' + name + '"]');
    if (el) el.classList.toggle('on', on);
  }
  function press(name) {
    if (down[name]) return;
    down[name] = true;
    fire('keydown', name);
    mark(name, true);
    if (navigator.vibrate && (name === 'z' || name === 'x' || name === 'start')) navigator.vibrate(6);
  }
  function release(name) {
    if (!down[name]) return;
    down[name] = false;
    fire('keyup', name);
    mark(name, false);
  }
  function releaseAll() { Object.keys(down).forEach(release); }

  /* ---------- styles ---------- */
  var css = [
    'html.mc,html.mc body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;position:fixed;',
    '  overscroll-behavior:none;touch-action:none;-webkit-user-select:none;user-select:none;',
    '  -webkit-touch-callout:none;-webkit-tap-highlight-color:transparent}',
    'html.mc body{background:#1b1b30 !important}',
    'html.mc h1,html.mc footer{display:none !important}',
    /* loading screen: fit it to the width we have */
    'html.mc #loadingCanvas{position:fixed !important;left:var(--gx) !important;top:var(--gy) !important;',
    '  width:var(--gs) !important;height:calc(var(--gs) * 0.75) !important;margin:0 !important;border:0 !important}',
    /* game canvas: SDL reads the canvas CSS size when it creates the window, so leave the size alone
       (default) until the game is live, THEN scale it with CSS. The surface stays at the size from conf.lua. */
    'html.mc #canvas{position:fixed !important;left:0;top:0;margin:0 !important;border:0 !important}',
    'html.mc.live #canvas{left:var(--gx) !important;top:var(--gy) !important;',
    '  width:var(--gs) !important;height:var(--gh) !important;image-rendering:crisp-edges;image-rendering:pixelated}',

    '#mc{position:fixed;left:0;right:0;bottom:0;top:var(--ct);z-index:10;pointer-events:none;font-family:monospace}',
    '#mc>*{position:absolute;pointer-events:auto;touch-action:none}',

    '#mc-dpad{width:var(--d);height:var(--d);display:grid;grid-template:repeat(3,1fr)/repeat(3,1fr)}',
    '#mc-dpad .arm,#mc-dpad .hub{background:#2b2b4d;box-sizing:border-box}',
    '#mc-dpad .arm{position:relative;border:3px solid #0d0d1a}',
    '#mc-dpad .hub{grid-area:2/2}',
    '#mc-dpad .up{grid-area:1/2}#mc-dpad .left{grid-area:2/1}#mc-dpad .right{grid-area:2/3}#mc-dpad .down{grid-area:3/2}',
    '#mc-dpad .arm::after{content:"";position:absolute;inset:26%;background:#8f8cb8;clip-path:polygon(50% 0,100% 100%,0 100%)}',
    '#mc-dpad .left::after{transform:rotate(-90deg)}#mc-dpad .right::after{transform:rotate(90deg)}#mc-dpad .down::after{transform:rotate(180deg)}',
    '#mc-dpad .arm.on{background:#e84d9b}#mc-dpad .arm.on::after{background:#fff}',

    '#mc-ab{width:calc(var(--b) * 2.25);height:calc(var(--b) * 1.6)}',
    '#mc-ab .btn{position:absolute;width:var(--b);height:var(--b);border-radius:50%;border:3px solid #0d0d1a;box-sizing:border-box;',
    '  box-shadow:0 5px 0 #0d0d1a;display:flex;align-items:center;justify-content:center;',
    '  font:700 calc(var(--b) * 0.36) monospace;color:#0d0d1a}',
    '#mc-ab .btn.x{right:0;top:0;background:#3db4e6}',
    '#mc-ab .btn.z{left:0;bottom:0;background:#e84d9b}',
    '#mc-ab .btn.on{transform:translateY(4px);box-shadow:0 1px 0 #0d0d1a;filter:brightness(1.25)}',

    '#mc-start{width:68px;height:28px;border:3px solid #0d0d1a;border-radius:14px;background:#2b2b4d;color:#bcb9d2;',
    '  font:700 11px/22px monospace;text-align:center;box-sizing:border-box}',
    '#mc-start::before{content:"";position:absolute;inset:-12px}', /* bigger touch target */
    '#mc-start.on{background:#ffd84a;color:#0d0d1a}',

    'html.mc.port #mc-dpad{left:var(--pad);top:54%;transform:translateY(-50%)}',
    'html.mc.port #mc-ab{right:var(--pad);top:54%;transform:translateY(-50%)}',
    'html.mc.port #mc-start{left:50%;bottom:calc(14px + var(--sb));transform:translateX(-50%)}',
    'html.mc.land #mc-dpad{left:calc((var(--L) - var(--d)) / 2);top:50%;transform:translateY(-50%)}',
    'html.mc.land #mc-ab{right:calc((var(--L) - var(--b) * 2.25) / 2);top:50%;transform:translateY(-50%)}',
    'html.mc.land #mc-start{right:calc((var(--L) - 68px) / 2);bottom:calc(14px + var(--sb))}'
  ].join('\n');
  var style = document.createElement('style');
  style.textContent = css;
  document.head.appendChild(style);

  /* ---------- controls markup ---------- */
  var root = document.createElement('div');
  root.id = 'mc';
  root.innerHTML =
    '<div id="mc-dpad" role="group" aria-label="Directional pad">' +
      '<i class="arm up" data-k="up"></i><i class="arm left" data-k="left"></i><i class="hub"></i>' +
      '<i class="arm right" data-k="right"></i><i class="arm down" data-k="down"></i></div>' +
    '<div id="mc-start" data-k="start" role="button" aria-label="Start">start</div>' +
    '<div id="mc-ab">' +
      '<div class="btn x" data-k="x" role="button" aria-label="X button">x</div>' +
      '<div class="btn z" data-k="z" role="button" aria-label="Z button">z</div></div>';
  document.body.appendChild(root);
  html.classList.add('mc');
  root.addEventListener('contextmenu', function (e) { e.preventDefault(); });

  function capture(el, e) { try { el.setPointerCapture(e.pointerId); } catch (err) { /* ignore */ } }

  // single buttons: z, x, start
  Array.prototype.forEach.call(root.querySelectorAll('.btn,#mc-start'), function (el) {
    var name = el.getAttribute('data-k');
    el.addEventListener('pointerdown', function (e) { e.preventDefault(); capture(el, e); press(name); });
    ['pointerup', 'pointercancel'].forEach(function (t) {
      el.addEventListener(t, function () { release(name); });
    });
  });

  // d-pad: one touch area, 4 directions, slide a finger to change direction
  var dpad = root.querySelector('#mc-dpad');
  var dir = null, dpadPointer = null;
  function setDir(d) {
    if (d === dir) return;
    if (dir) release(dir);
    dir = d;
    if (d) press(d);
  }
  function dirFrom(e) {
    var r = dpad.getBoundingClientRect();
    var dx = (e.clientX - (r.left + r.width / 2)) / (r.width / 2);
    var dy = (e.clientY - (r.top + r.height / 2)) / (r.height / 2);
    if (Math.sqrt(dx * dx + dy * dy) < 0.22) return null; // dead zone in the middle
    if (Math.abs(dx) > Math.abs(dy)) return dx < 0 ? 'left' : 'right';
    return dy < 0 ? 'up' : 'down';
  }
  dpad.addEventListener('pointerdown', function (e) {
    e.preventDefault(); capture(dpad, e);
    dpadPointer = e.pointerId; setDir(dirFrom(e));
  });
  dpad.addEventListener('pointermove', function (e) {
    if (e.pointerId === dpadPointer) setDir(dirFrom(e));
  });
  ['pointerup', 'pointercancel'].forEach(function (t) {
    dpad.addEventListener(t, function (e) {
      if (e.pointerId === dpadPointer) { dpadPointer = null; setDir(null); }
    });
  });

  // never leave a key stuck down
  window.addEventListener('blur', releaseAll);
  window.addEventListener('pagehide', releaseAll);
  document.addEventListener('visibilitychange', function () { if (document.hidden) releaseAll(); });

  /* ---------- layout ---------- */
  var probe = document.createElement('div'); // reads the safe-area insets (notch, home bar)
  probe.style.cssText = 'position:fixed;left:0;top:0;visibility:hidden;pointer-events:none;' +
    'padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';
  document.body.appendChild(probe);

  var lastSig = '';
  function signature() {
    return [window.innerWidth, window.innerHeight, window.devicePixelRatio, canvas.width, canvas.height].join();
  }

  function layout() {
    var vw = window.innerWidth, vh = window.innerHeight, dpr = window.devicePixelRatio || 1;
    var s = getComputedStyle(probe);
    var ins = {
      t: parseFloat(s.paddingTop) || 0, r: parseFloat(s.paddingRight) || 0,
      b: parseFloat(s.paddingBottom) || 0, l: parseFloat(s.paddingLeft) || 0
    };
    var W = vw - ins.l - ins.r, H = vh - ins.t - ins.b;
    var land = W > H * 1.1;

    // biggest square the screen can spare for the game, leaving room for the controls
    var avail = land ? Math.min(H, W - 300) : Math.min(W, H - 210);
    avail = Math.max(avail, 64);

    // snap to a whole multiple of the game grid in *device* pixels (unless that wastes >12%)
    var k = Math.floor(avail * dpr / GRID), size = avail;
    if (k >= 1 && (GRID * k / dpr) >= avail * 0.88) size = GRID * k / dpr;

    // an untouched canvas is 300x150; anything else means the game has created its window
    var live = canvas.width !== 300 || canvas.height !== 150;
    var gh = live ? size * canvas.height / canvas.width : size;
    var gx = ins.l + (W - size) / 2;
    var gy = ins.t + (land ? (H - gh) / 2 : 0);

    var ct = land ? 0 : gy + gh;
    var d, b, L = 0;
    if (land) {
      L = Math.max(0, Math.min(gx, vw - gx - size));
      d = Math.min(H * 0.6, L * 0.86, 190);
      b = Math.min(d * 0.5, L * 0.4);
    } else {
      var R = vh - ct - ins.b;
      d = Math.min(R * 0.74, W * 0.4, 200);
      b = d * 0.48;
    }

    var st = html.style;
    st.setProperty('--gx', gx + 'px'); st.setProperty('--gy', gy + 'px');
    st.setProperty('--gs', size + 'px'); st.setProperty('--gh', gh + 'px');
    st.setProperty('--ct', ct + 'px'); st.setProperty('--L', L + 'px');
    st.setProperty('--d', Math.max(d, 90) + 'px'); st.setProperty('--b', Math.max(b, 40) + 'px');
    st.setProperty('--pad', (14 + Math.max(ins.l, ins.r)) + 'px');
    st.setProperty('--sb', ins.b + 'px');
    html.classList.toggle('land', land);
    html.classList.toggle('port', !land);
    html.classList.toggle('live', live);
    lastSig = signature();
  }

  // The window "resize" event is also what SDL listens to, and SDL would resize the
  // game's drawing surface to our CSS size. Swallow it here (we run first) and lay out ourselves.
  window.addEventListener('resize', function (e) { e.stopImmediatePropagation(); layout(); }, true);
  window.addEventListener('orientationchange', function () { setTimeout(layout, 150); });
  if (window.visualViewport) window.visualViewport.addEventListener('resize', layout);
  // canvas.width changes when the game creates its window; there is no event for that, so poll cheaply
  setInterval(function () { if (signature() !== lastSig) layout(); }, 400);
  layout();
})();
