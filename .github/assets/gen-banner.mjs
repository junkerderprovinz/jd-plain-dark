/**
 * Generates the JD Plain Dark README banners (theme-adaptive pair) in the JDownloader
 * main-repo house style:
 *   banner.svg / .png       : light 1600x500 - the JDownloader globe on the LEFT, then the
 *                             "JD PLAIN DARK" wordmark + a cheeky claim.
 *   banner-dark.svg / .png  : same layout on GitHub-dark #0d1117, light text + lightened globe.
 * The README serves the pair via <picture> (prefers-color-scheme).
 *
 * Wordmark: the JDownloader treatment applied to the theme name - the signature giant Myriad
 * Pro SEMIBOLD "J" (with the crossbar across its top), reused VERBATIM from the JDOWNLOADER
 * mark, then the rest of the name in Myriad Pro BLACK caps. So the leading "JD" reads exactly
 * like the "JD" in JDOWNLOADER. Rendered to VECTOR PATHS (opentype.js); letters are FLAT
 * (#161616 light / light on dark). The claim uses Lato (OFL).
 *
 * The Myriad Pro OTFs live at .github/assets/_fonts/ (gitignored - NEVER committed; only the
 * glyph outlines land in the SVG). Nominative use echoing the product's own mark.
 *
 * Deps: `npm i -g @resvg/resvg-js opentype.js`. Run: node .github/assets/gen-banner.mjs
 */
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";
import { createRequire } from "node:module";
import { execSync } from "node:child_process";

const require = createRequire(import.meta.url);
const gRoot = execSync("npm root -g").toString().trim();
const opentype = require(`${gRoot}/opentype.js`);
const { Resvg } = require(`${gRoot}/@resvg/resvg-js`);
const __dir = dirname(fileURLToPath(import.meta.url));

// ---- content -----------------------------------------------------------------
const NAME = "JD PLAIN DARK";                                  // rendered ALL CAPS, JD-wordmark style
const CLAIM = "Dark across every panel.";
const THEMES = [
  { suffix: "",      bg: "#ffffff", name: "#161616", claim: "#5a5d5e", darkGlobe: false },
  { suffix: "-dark", bg: "#0d1117", name: "#e6edf3", claim: "#9aa4ad", darkGlobe: true  },
];
const W = 1600, H = 500;
const LH = 386, LW = LH;          // globe on the left (square) — enlarged to the user's refined size
const gap = 48;
const claimSize = 40;
const WM_H = 214;                 // nominal wordmark height in the banner
const MAX_GROUP = W - 150;

// Source wordmark geometry (JDownloader "Element 1.svg"; source box height 326.1). The J +
// crossbar + the caps baseline are reused VERBATIM so the leading "JD" matches JDOWNLOADER.
const SRC_H = 326.1;
const CROSSBAR = { x: 27.78, y: 48.9, w: 70.62, h: 24.14 };
const J_RUN  = { text: "J", x: 0, y: 251.1, size: 300 };        // giant Semibold J
const REST   = { x: 101.22, y: 205.77, size: 190, ls: -0.04 };  // the rest, Black caps

const black = opentype.parse(readFileSync(join(__dir, "_fonts", "MyriadPro-Black.otf")).buffer);
const semi  = opentype.parse(readFileSync(join(__dir, "_fonts", "MyriadPro-Semibold.otf")).buffer);
const latoFile = join(tmpdir(), "JD-Lato-Regular.ttf");
if (!existsSync(latoFile)) {
  const r = await fetch("https://github.com/google/fonts/raw/main/ofl/lato/Lato-Regular.ttf");
  if (!r.ok) throw new Error(`Lato fetch ${r.status}`);
  writeFileSync(latoFile, Buffer.from(await r.arrayBuffer()));
}
const lato = opentype.parse(readFileSync(latoFile).buffer);

// Render a text run to a path at (x, baseline) with optional letter-spacing (em). Returns
// { d, endX }. Reads glyph.path.commands (read-only) so a REPEATED letter doesn't come back NaN
// (opentype's Glyph.getPath() mutates a reused glyph object).
function runPath(font, text, x, baseline, size, lsEm = 0) {
  const s = size / font.unitsPerEm, ls = lsEm * size, n = (v) => v.toFixed(2);
  let d = "", cx = x;
  for (const ch of text) {
    const g = font.charToGlyph(ch);
    for (const c of g.path.commands) {
      if (c.type === "M") d += `M${n(cx + c.x * s)} ${n(baseline - c.y * s)}`;
      else if (c.type === "L") d += `L${n(cx + c.x * s)} ${n(baseline - c.y * s)}`;
      else if (c.type === "C") d += `C${n(cx + c.x1 * s)} ${n(baseline - c.y1 * s)} ${n(cx + c.x2 * s)} ${n(baseline - c.y2 * s)} ${n(cx + c.x * s)} ${n(baseline - c.y * s)}`;
      else if (c.type === "Q") d += `Q${n(cx + c.x1 * s)} ${n(baseline - c.y1 * s)} ${n(cx + c.x * s)} ${n(baseline - c.y * s)}`;
      else if (c.type === "Z") d += "Z";
    }
    cx += g.advanceWidth * s + ls;
  }
  return { d, endX: cx - (text.length ? ls : 0) };   // don't count the trailing letter-spacing
}
function runWidth(font, text, size) {
  const s = size / font.unitsPerEm;
  let w = 0;
  for (const ch of text) w += font.charToGlyph(ch).advanceWidth * s;
  return w;
}

// Build the wordmark in the SOURCE coordinate system: giant J + crossbar + Black-caps remainder.
const jRes = runPath(semi, NAME[0], J_RUN.x, J_RUN.y, J_RUN.size);
const restRes = runPath(black, NAME.slice(1), REST.x, REST.y, REST.size, REST.ls);
const wordmarkPath = jRes.d + restRes.d;
const crossbarPath = `M${CROSSBAR.x} ${CROSSBAR.y} h${CROSSBAR.w} v${CROSSBAR.h} h${-CROSSBAR.w} Z`;
if ((wordmarkPath + crossbarPath).includes("NaN")) throw new Error("NaN path");
const SRC_W = restRes.endX;                     // actual right edge of the wordmark

// Scale the wordmark to WM_H and lay out globe + wordmark + claim (fit to MAX_GROUP).
// FIXED layout, matching the user's hand-refined banner (viewBox 1600x500): the globe box sits at a
// fixed left so its circle centre lands at (293, 242); the wordmark starts at a fixed x=522 (its
// crossbar aligns to the user's x), 214px tall; the claim is centred under the wordmark. Names
// shorter than "JD HIGHLIGHTER" simply leave more room on the right — the same slightly
// left-weighted balance the user chose. (LW/gap/MAX_GROUP now only bound the safety downscale.)
const startX = 108, LY = 57;                               // globe box -> circle centre (293, 242)
const textX = 522, wmTop = 138.7;                          // crossbar top -> y=170.8, caps baseline -> y=273.7
const claimBaseline = 350;                                 // claim baseline, below the wordmark
const s2 = Math.min(WM_H / SRC_H, (W - textX - 60) / SRC_W);   // 214px tall, capped so it can't overflow right
const wmWFit = SRC_W * s2;
const claimAsc = lato.ascender * claimSize / lato.unitsPerEm;
const claimW = runWidth(lato, CLAIM, claimSize);
const claimStartX = textX + (wmWFit - claimW) / 2;         // centre the claim under the wordmark
const claimPath = runPath(lato, CLAIM, claimStartX, claimBaseline, claimSize).d;

// Globe: the light card keeps the Carbon-dark body; the dark card lightens it to read on #0d1117.
const iconRaw = readFileSync(join(__dir, "icon.svg"), "utf8").replace(/<\?xml[^>]*\?>\s*/, "");
const placeLogo = (svgStr) => svgStr.replace(/<svg[\s\S]*?>/,
  `<svg x="${startX.toFixed(1)}" y="${LY.toFixed(1)}" width="${LW}" height="${LH}" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">`);

for (const t of THEMES) {
  const icon = t.darkGlobe
    ? iconRaw.replace(/#161616/gi, "#2d333b").replace(/#0b0b0b/gi, "#21262d")
    : iconRaw;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-label="${NAME}">
  <rect width="${W}" height="${H}" fill="${t.bg}"/>
  ${placeLogo(icon)}
  <g transform="translate(${textX.toFixed(2)} ${wmTop.toFixed(2)}) scale(${s2.toFixed(5)})">
    <path d="${wordmarkPath}" fill="${t.name}"/>
    <path d="${crossbarPath}" fill="${t.name}"/>
  </g>
  <path d="${claimPath}" fill="${t.claim}"/>
</svg>
`;
  writeFileSync(join(__dir, `banner${t.suffix}.svg`), svg);
  const png = new Resvg(svg, { fitTo: { mode: "width", value: W }, background: t.bg }).render().asPng();
  writeFileSync(join(__dir, `banner${t.suffix}.png`), png);
  console.log(`wrote banner${t.suffix}.svg + .png (wordmark ${Math.round(wmWFit)}x${Math.round(SRC_H * s2)})`);
}
