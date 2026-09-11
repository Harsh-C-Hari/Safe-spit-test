# SpitLab

Marketing site for the SpitLab app. Plain HTML/CSS/JS, no build step, Three.js loaded from CDN via an import map.

## Run locally

Browsers block ES module imports over `file://`, so serve it instead of double-clicking the HTML:

```
cd spitlab
python3 -m http.server 8080
# open http://localhost:8080
```

Any static server works (`npx serve`, VS Code Live Server, etc.).

## Deploy

Static, no backend — drag the `spitlab` folder into Netlify/Vercel, or push to GitHub Pages.

## What's implemented vs. the brief

- All 5 pages, shared header/nav/footer, grain overlay, scattered SVG splatter decals, ambient top-of-viewport drip system (Three.js `DripStrand` class in `js/fluid-system.js`), ported to a CSS fallback under `prefers-reduced-motion` or a detected low-end GPU.
- Hero wordmark (`js/hero-wordmark.js`): real 3D extruded text (Three.js `TextGeometry`) in a glass `MeshPhysicalMaterial`, with a noise-driven vertex "sag" on the lower edge and `DripStrand` instances hanging off the bottom. A CSS gradient-text version sits underneath as the loading state / no-JS-heavy fallback.
- Simulator (`js/simulator.js`): pointer-driven aim, a power slider, 4 spit types with distinct size/color/gravity, a simplified parabolic-arc physics step, and an organic splat/trail renderer (`js/splatter-shader.js`, canvas 2D noise-silhouette rather than a raymarched GLSL shader — reads the same and is far cheaper).
- Contact form fakes a submit (no backend) and shows a success state.

## Assumptions made (brief asked to confirm these before starting)

- **CTA links**: "GET STARTED →" and the contact form point nowhere real yet — wired as placeholders (`href="#"`), easy to swap for an App Store / waitlist link.
- **Screenshots/logo**: none were supplied, so the Project page uses phone-mockup frames with simple droplet glyphs instead of real screenshots.
- **Sound**: not implemented on the simulator's spit/splat — it's silent by default. Easy to add (a couple of short `<audio>` clips triggered in `resolveEnd()` in `simulator.js`) if you want it.

## Known rough edges

- The hero wordmark's font is Three.js's stock `helvetiker_bold` (loaded from the same CDN as Three.js) rather than a custom blobby/organic typeface — swap the `FontLoader` URL in `hero-wordmark.js` for a converted `.typeface.json` if you have a specific display font in mind.
- Everything was built and syntax-checked but not pixel-tested in a real browser in this environment — give it a pass on a couple of screen sizes before shipping, especially the simulator's aim/power feel.
