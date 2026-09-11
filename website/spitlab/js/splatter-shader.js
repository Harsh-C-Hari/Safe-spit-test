/* ============================================
   SPITLAB — splatter-shader.js
   Organic splat blob generator, shared by the
   simulator's impact effect and any decorative
   splat-spawn moments. Not a GPU shader — a cheap
   noise-silhouette drawn with canvas 2D, which reads
   as "fluid splatter" without a raymarch cost.
   ============================================ */

(function () {
  'use strict';

  /** deterministic-ish value noise over angle, so the blob edge looks organic not circular */
  function blobRadii(points, roughness) {
    const radii = [];
    const seeds = [];
    for (let i = 0; i < 4; i++) seeds.push(Math.random() * Math.PI * 2);
    for (let i = 0; i < points; i++) {
      const t = (i / points) * Math.PI * 2;
      let n = 0;
      n += Math.sin(t * 2 + seeds[0]) * 0.35;
      n += Math.sin(t * 3.3 + seeds[1]) * 0.22;
      n += Math.sin(t * 5.1 + seeds[2]) * 0.14;
      n += Math.sin(t * 8.7 + seeds[3]) * 0.08;
      radii.push(1 + n * roughness);
    }
    return radii;
  }

  function drawBlobPath(ctx, cx, cy, baseRadius, radii) {
    const points = radii.length;
    ctx.beginPath();
    for (let i = 0; i <= points; i++) {
      const idx = i % points;
      const t = (idx / points) * Math.PI * 2;
      const r = baseRadius * radii[idx];
      const x = cx + Math.cos(t) * r;
      const y = cy + Math.sin(t) * r * 0.86;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.closePath();
  }

  /**
   * Draw one splat onto a 2D canvas context. Includes a soft core, a few
   * satellite droplets flung outward, and a faint rim highlight so it
   * reads as backlit/wet rather than a flat ink blot.
   */
  function drawSplat(ctx, opts) {
    const {
      x, y,
      radius = 40,
      color = '#d8d8d8',
      accentColor = null,
      alpha = 0.85,
      satellites = 6,
    } = opts;

    ctx.save();
    ctx.globalAlpha = alpha;

    // core blob
    const radii = blobRadii(18, 0.45);
    const grad = ctx.createRadialGradient(x - radius * 0.2, y - radius * 0.25, radius * 0.1, x, y, radius);
    grad.addColorStop(0, lighten(color, 18));
    grad.addColorStop(0.55, color);
    grad.addColorStop(1, darken(color, 30));
    ctx.fillStyle = grad;
    drawBlobPath(ctx, x, y, radius, radii);
    ctx.fill();

    // rim highlight (single hard light, top-left)
    ctx.globalAlpha = alpha * 0.5;
    ctx.strokeStyle = lighten(color, 55);
    ctx.lineWidth = Math.max(1, radius * 0.03);
    ctx.beginPath();
    ctx.ellipse(x - radius * 0.18, y - radius * 0.22, radius * 0.75, radius * 0.6, -0.5, Math.PI * 1.1, Math.PI * 1.9);
    ctx.stroke();

    // satellite droplets
    ctx.globalAlpha = alpha * 0.9;
    for (let i = 0; i < satellites; i++) {
      const ang = Math.random() * Math.PI * 2;
      const dist = radius * (1.1 + Math.random() * 1.3);
      const sx = x + Math.cos(ang) * dist;
      const sy = y + Math.sin(ang) * dist * 0.75;
      const sr = radius * (0.06 + Math.random() * 0.12);
      const sg = ctx.createRadialGradient(sx, sy, 0, sx, sy, sr);
      const c = accentColor && Math.random() < 0.25 ? accentColor : color;
      sg.addColorStop(0, lighten(c, 20));
      sg.addColorStop(1, darken(c, 20));
      ctx.fillStyle = sg;
      ctx.beginPath();
      ctx.ellipse(sx, sy, sr, sr * 0.85, ang, 0, Math.PI * 2);
      ctx.fill();
    }

    ctx.restore();
  }

  function hexToRgb(hex) {
    const h = hex.replace('#', '');
    const n = parseInt(h.length === 3 ? h.split('').map((c) => c + c).join('') : h, 16);
    return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
  }
  function rgbToHex(r, g, b) {
    const c = (v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, '0');
    return `#${c(r)}${c(g)}${c(b)}`;
  }
  function lighten(hex, amt) {
    const { r, g, b } = hexToRgb(hex);
    return rgbToHex(r + amt * 2.2, g + amt * 2.2, b + amt * 2.2);
  }
  function darken(hex, amt) {
    const { r, g, b } = hexToRgb(hex);
    return rgbToHex(r - amt * 2, g - amt * 2, b - amt * 2);
  }

  window.SPITLAB = window.SPITLAB || {};
  window.SPITLAB.drawSplat = drawSplat;
})();
