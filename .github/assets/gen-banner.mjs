/**
 * Generates the JD Plain Dark README banners, a 1600x500 pair the README picks between
 * with <picture> and prefers-color-scheme:
 *   banner.svg / .png       : light, the JDownloader globe on the left, then the
 *                             "JD PLAIN DARK" wordmark and the claim.
 *   banner-dark.svg / .png  : the same on GitHub-dark #0d1117, light text, lightened globe.
 *
 * The wordmark gives the theme name JDownloader's treatment: the giant Myriad Pro Semibold
 * "J" with the crossbar across its top, taken verbatim from the JDOWNLOADER mark, then the
 * rest in Myriad Pro Black caps, so the leading "JD" reads like the one in JDOWNLOADER. It is
 * rendered to flat vector paths with opentype.js. The claim uses Lato (OFL).
 *
 * The Myriad Pro OTFs live in the gitignored .github/assets/_fonts/; only the glyph outlines
 * land in the SVG, as a nominative echo of the product's own mark.
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

const NAME = "JD PLAIN DARK";                                  // caps, like the JD wordmark
const CLAIM = "Dark across every panel.";
const THEMES = [
  { suffix: "",      bg: "#ffffff", name: "#1f2328", claim: "#5a5d5e", darkGlobe: false },
  { suffix: "-dark", bg: "#0d1117", name: "#e6edf3", claim: "#9aa4ad", darkGlobe: true  },
];
const W = 1600, H = 500;
const LH = 470, LW = LH;          // the square globe box, about 400px of ink
const gap = 70;                   // logo-to-text gap (house standard)
const claimSize = 44;

// Source wordmark geometry (JDownloader "Element 1.svg", box height 326.1). The J, the
// crossbar and the caps baseline are reused verbatim so the leading "JD" matches JDOWNLOADER.
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

// Renders a text run to a path at (x, baseline) with optional letter-spacing (em) and returns
// { d, endX }. It reads glyph.path.commands because opentype's Glyph.getPath() mutates a
// reused glyph object, which turns a repeated letter into NaN.
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

// The wordmark is built in the source coordinate system: giant J, crossbar, Black caps.
const jRes = runPath(semi, NAME[0], J_RUN.x, J_RUN.y, J_RUN.size);
const restRes = runPath(black, NAME.slice(1), REST.x, REST.y, REST.size, REST.ls);
const wordmarkPath = jRes.d + restRes.d;
const crossbarPath = `M${CROSSBAR.x} ${CROSSBAR.y} h${CROSSBAR.w} v${CROSSBAR.h} h${-CROSSBAR.w} Z`;
if ((wordmarkPath + crossbarPath).includes("NaN")) throw new Error("NaN path");
const SRC_W = restRes.endX;                     // actual right edge of the wordmark

// The globe is left-anchored at 165 with the wordmark to its right, and the wordmark and
// claim block is centred vertically, sized and placed by the wordmark's real ink bbox.
const startX = 165, LY = (H - LH) / 2;
const textX = startX + LW + gap;
const WM_TARGET = 150;                                     // visual wordmark height (~ the 132px text names)
const bb = new Resvg(
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${Math.ceil(SRC_W) + 40} 400"><path d="${wordmarkPath}${crossbarPath}"/></svg>`,
  { fitTo: { mode: "original" } },
).getBBox();
const s2 = Math.min(WM_TARGET / bb.height, (W - textX - 80) / bb.width);   // height target, width-capped
const wmH = bb.height * s2;
const wmWFit = bb.width * s2;
const claimAsc = lato.ascender * claimSize / lato.unitsPerEm;
const claimDesc = -lato.descender * claimSize / lato.unitsPerEm;
const NAME_CLAIM_GAP = 8;
const blockH = wmH + NAME_CLAIM_GAP + claimAsc + claimDesc;
const top = H / 2 - blockH / 2;
const wmX = textX - bb.x * s2;                             // left-anchor the wordmark's ink at textX
const wmTop = top - bb.y * s2;                             // wordmark visible top -> `top`
const claimBaseline = top + wmH + NAME_CLAIM_GAP + claimAsc;
// The claim is centred under the wordmark, because the giant J would make a left-aligned
// claim start too far left.
const claimStartX = textX + (wmWFit - runWidth(lato, CLAIM, claimSize)) / 2;
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
  <g transform="translate(${wmX.toFixed(2)} ${wmTop.toFixed(2)}) scale(${s2.toFixed(5)})">
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
