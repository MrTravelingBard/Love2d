#!/usr/bin/env node
/*
 * Post-processes a love.js build.
 *
 *   node tools/postbuild.js <game-folder> [--grid 128]
 *
 * Reads  <game-folder>/build          (output of `love.js`)
 * Writes <game-folder>/build          mobile layout + touch controls added   -> GitHub Pages
 *        <game-folder>/build-itch     same, minus the love.js title/footer   -> itch.io
 *
 * --grid is the game's logical resolution in pixels (128 for the PICO-8 style games).
 * No dependencies; needs Node 16.7+.
 */
const fs = require('fs');
const path = require('path');

function fail(msg) { console.error('postbuild: ' + msg); process.exit(1); }

const game = process.argv[2];
if (!game || game.startsWith('--')) fail('usage: node tools/postbuild.js <game-folder> [--grid 128]');
const gi = process.argv.indexOf('--grid');
const grid = gi > -1 ? parseInt(process.argv[gi + 1], 10) : 128;
if (!grid) fail('--grid needs a number, e.g. --grid 128');

const build = path.join(game, 'build');
const itch = path.join(game, 'build-itch');
const indexPath = path.join(build, 'index.html');
if (!fs.existsSync(indexPath)) fail(indexPath + ' not found. Run love.js first.');

let html = fs.readFileSync(indexPath, 'utf8');

// 1. let the page draw under the notch; the controls script pads for the safe areas itself
html = html.replace(/(<meta name="viewport" content=")([^"]*)(")/, (m, a, b, c) =>
  b.includes('viewport-fit') ? m : a + b + ', viewport-fit=cover' + c);

// 2. add the mobile layer (skip if this build was already processed)
fs.copyFileSync(path.join(__dirname, 'mobile-controls.js'), path.join(build, 'mobile-controls.js'));
if (!html.includes('mobile-controls.js')) {
  if (!html.includes('</body>')) fail('no </body> found in ' + indexPath);
  html = html.replace('</body>', `  <script src="mobile-controls.js" data-grid="${grid}"></script>\n  </body>`);
}
fs.writeFileSync(indexPath, html);

// 3. itch.io copy: itch supplies the title and fullscreen button, so drop love.js's
//    <h1> title and footer (fullscreen button, credit, reload hint)
const itchHtml = html
  .replace(/<footer>[\s\S]*?<\/footer>\s*/, '')
  .replace(/<h1>[\s\S]*?<\/h1>\s*/, '');
if (/Go Fullscreen/.test(itchHtml) || /<h1>/.test(itchHtml)) {
  fail('could not strip the love.js title/footer; the love.js template may have changed');
}
fs.rmSync(itch, { recursive: true, force: true });
fs.cpSync(build, itch, { recursive: true });
fs.writeFileSync(path.join(itch, 'index.html'), itchHtml);

console.log(`postbuild: ${build} (+ mobile controls) and ${itch} ready`);
