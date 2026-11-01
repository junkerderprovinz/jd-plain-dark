/**
 * Renders the README banner that points JDownloader users at KnightLoader, in the
 * style of KnightLoader's own notices: 1920x640, the crest and the name large so the
 * app is known at a glance, the downloads page on the right. The file is the same in
 * every repo that carries the banner; logo and screenshot come from the KnightLoader repo.
 *
 * Needs playwright-core installed globally and Chrome.
 * Run: node .github/assets/gen-knightloader-ad.mjs
 */
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { execSync } from "node:child_process";

const require = createRequire(import.meta.url);
const { chromium } = require(`${execSync("npm root -g").toString().trim()}/playwright-core`);

const here = dirname(fileURLToPath(import.meta.url));

async function cached(file, url) {
  const path = join(tmpdir(), `knightloader-ad-${file}`);
  if (!existsSync(path)) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`${file}: fetch ${res.status}`);
    writeFileSync(path, Buffer.from(await res.arrayBuffer()));
  }
  return readFileSync(path);
}

const dataUrl = (buf, type) => `data:${type};base64,${buf.toString("base64")}`;
const fonts = "https://github.com/google/fonts/raw/main/ofl";
const kl = "https://raw.githubusercontent.com/junkerderprovinz/knightloader/main/.github/assets";
const bree = dataUrl(await cached("BreeSerif-Regular.ttf", `${fonts}/breeserif/BreeSerif-Regular.ttf`), "font/ttf");
const lato = dataUrl(await cached("Lato-Regular.ttf", `${fonts}/lato/Lato-Regular.ttf`), "font/ttf");
const latoBold = dataUrl(await cached("Lato-Bold.ttf", `${fonts}/lato/Lato-Bold.ttf`), "font/ttf");
const mark = dataUrl(await cached("logo.svg", `${kl}/logo.svg`), "image/svg+xml");
const shot = dataUrl(await cached("downloads.png", `${kl}/screenshots/knightloader-2-downloads.png`), "image/png");

// The screenshot is a 3840x2000 marketing picture; the window sits at these fractions of it.
const win = { left: 0.322, top: 0.083, width: 0.666, height: 0.843 };
const winWidth = 700;
const winHeight = Math.round(((winWidth / win.width) * win.height * 2000) / 3840);

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
@font-face { font-family: "Bree Serif"; src: url(${bree}); }
@font-face { font-family: Lato; src: url(${lato}); font-weight: 400; }
@font-face { font-family: Lato; src: url(${latoBold}); font-weight: 700; }
* { box-sizing: border-box; margin: 0; }
body { position: relative; width: 1920px; height: 640px; overflow: hidden; font-family: Lato, sans-serif; background: #0c0c0b; }
.wall { position: absolute; inset: 0; background: radial-gradient(55% 60% at 62% 35%, #26231d, #0f0e0c 72%); }
.relief { position: absolute; width: 34%; left: 52%; top: -26%; transform: rotate(-10deg); opacity: .32;
  filter: grayscale(1) brightness(.36) contrast(1.2) drop-shadow(-2px -2px 0 rgba(255,255,255,.16)) drop-shadow(12px 18px 26px rgba(0,0,0,.85)); }
.vignette { position: absolute; inset: 0; box-shadow: inset 0 0 200px rgba(0,0,0,.6); }
.crest { position: absolute; left: 72px; top: 85px; height: 470px; filter: drop-shadow(0 20px 40px rgba(0,0,0,.6)); }
.copy { position: absolute; left: 400px; top: 0; bottom: 0; width: 760px; display: flex; flex-direction: column; justify-content: center; align-items: flex-start; gap: 22px; }
.label { padding: 8px 18px; border-radius: 8px; background: #FCC419; color: #141414; font: 700 22px/1 Lato, sans-serif; letter-spacing: .12em; text-transform: uppercase; }
.name { font: 400 118px/1 "Bree Serif", serif; color: #f4f4f4; white-space: nowrap; }
h1 { font: 400 44px/1.1 "Bree Serif", serif; color: #f4f4f4; }
h1 em { font-style: normal; color: #FCC419; }
.go { margin-top: 10px; padding: 20px 38px; border-radius: 18px; background: #FCC419; color: #141414; font: 700 32px/1 Lato, sans-serif;
  box-shadow: 0 0 0 6px rgba(252,196,25,.18), 0 18px 40px rgba(0,0,0,.5); }
.window { position: absolute; right: 48px; top: 50%; width: ${winWidth}px; height: ${winHeight}px; overflow: hidden; border-radius: 14px;
  transform: translateY(-50%) perspective(1800px) rotateY(-9deg); box-shadow: 0 30px 60px rgba(0,0,0,.75), 0 0 0 1px rgba(255,255,255,.06); }
.window img { position: absolute; width: ${winWidth / win.width}px; left: ${(-win.left * winWidth) / win.width}px; top: ${(-win.top * winWidth * 2000) / (win.width * 3840)}px; }
</style></head><body>
<div class="wall"></div><img class="relief" src="${mark}"><div class="vignette"></div>
<img class="crest" src="${mark}" alt="">
<div class="window"><img src="${shot}"></div>
<div class="copy">
  <span class="label">New from the same knight</span>
  <div class="name">KnightLoader</div>
  <h1>Downloads everything.<br><em>And looks good doing it.</em></h1>
  <span class="go">Why don't you try? &rarr;</span>
</div>
</body></html>`;

// Rendered at twice the size and scaled down, which keeps the type crisp.
const browser = await chromium.launch({ channel: "chrome" });
const big = await browser.newPage({ viewport: { width: 1920, height: 640 }, deviceScaleFactor: 2 });
await big.setContent(html);
await big.evaluate(() => document.fonts.ready);
const png = await big.screenshot();
const small = await browser.newPage({ viewport: { width: 1920, height: 640 } });
await small.setContent(`<body style="margin:0"><img src="${dataUrl(png, "image/png")}" style="display:block;width:1920px;height:640px">`);
await small.locator("img").evaluate((img) => img.decode());
await small.screenshot({ path: join(here, "knightloader-ad.png") });
await browser.close();
console.log("knightloader-ad.png written");
