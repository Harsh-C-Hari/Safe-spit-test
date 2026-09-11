/* ============================================
   SPITLAB — fluid-system.js
   Ambient top-of-viewport drip layer, mounted once
   per page behind all content. Exposes DripStrand so
   hero-wordmark.js and simulator.js can reuse it.
   ============================================ */

import * as THREE from 'three';

(function () {
  'use strict';

  if (window.SPITLAB && window.SPITLAB.useFallback) return; // CSS fallback handles this page

  const COLOR_HI = 0xd8d8d8;
  const COLOR_LO = 0x1a1a1a;
  const COLOR_ACCENT = 0xa8a23a;

  /** cheap smoothed value-noise, 1D, seeded per-strand */
  function makeNoise1D(seed) {
    const perm = [];
    let s = seed * 9301 + 49297;
    for (let i = 0; i < 256; i++) {
      s = (s * 9301 + 49297) % 233280;
      perm.push(s / 233280);
    }
    return function (x) {
      const i = Math.floor(x) % 256;
      const f = x - Math.floor(x);
      const a = perm[((i % 256) + 256) % 256];
      const b = perm[(((i + 1) % 256) + 256) % 256];
      const t = f * f * (3 - 2 * f);
      return a + (b - a) * t;
    };
  }

  /**
   * A single drip strand: grows a wobbling tube downward from an anchor
   * point at the top of the viewport, then either (a) detaches its tip
   * into a falling droplet, or (b) snaps back and restarts.
   */
  class DripStrand {
    constructor(scene, opts) {
      this.scene = scene;
      this.anchorX = opts.anchorX;
      this.anchorY = opts.anchorY || 0;
      this.viewH = opts.viewH;
      this.accent = !!opts.accent;
      this.noise = makeNoise1D(Math.random() * 1000);
      this.material = new THREE.MeshPhysicalMaterial({
        color: this.accent ? COLOR_ACCENT : COLOR_HI,
        roughness: 0.12,
        metalness: 0,
        transmission: 0.55,
        thickness: 1.2,
        ior: 1.33,
        transparent: true,
        opacity: this.accent ? 0.55 : 0.4,
        emissive: this.accent ? COLOR_ACCENT : COLOR_LO,
        emissiveIntensity: 0.06,
      });
      this.mesh = null;
      this.droplet = null;
      this.dropletVy = 0;
      this.dropletY = 0;
      this.reset();
    }

    reset() {
      this.length = 0;
      this.maxLength = this.viewH * (0.14 + Math.random() * 0.4);
      this.growSpeed = this.viewH * (0.05 + Math.random() * 0.05);
      this.width = 1.6 + Math.random() * 1.6;
      this.noiseOffset = Math.random() * 100;
      this.mode = Math.random() < 0.55 ? 'detach' : 'snapback';
      this.frame = 0;
    }

    buildGeometry(t) {
      const segs = 7;
      const pts = [];
      for (let i = 0; i <= segs; i++) {
        const p = i / segs;
        const y = this.anchorY + this.length * p; // camera space is y-down: growing = larger y
        const wob = (this.noise(p * 6 + t * 0.6 + this.noiseOffset) - 0.5) * 6 * p;
        pts.push(new THREE.Vector3(this.anchorX + wob, y, 0));
      }
      const curve = new THREE.CatmullRomCurve3(pts);
      const geo = new THREE.TubeGeometry(curve, 10, this.width * (1 - 0.3), 6, false);
      return geo;
    }

    update(dt, elapsed) {
      this.frame++;
      if (this.length < this.maxLength) {
        this.length += this.growSpeed * dt;
      }

      if (this.frame % 2 === 0 || !this.mesh) {
        const geo = this.buildGeometry(elapsed);
        if (this.mesh) {
          this.mesh.geometry.dispose();
          this.mesh.geometry = geo;
        } else {
          this.mesh = new THREE.Mesh(geo, this.material);
          this.scene.add(this.mesh);
        }
      }

      if (this.length >= this.maxLength) {
        if (this.mode === 'detach' && !this.droplet) {
          this.spawnDroplet();
        } else if (this.mode === 'snapback') {
          this.reset();
        }
      }

      if (this.droplet) {
        this.dropletVy += 380 * dt;
        this.dropletY += this.dropletVy * dt;
        this.droplet.position.y = this.dropletY;
        this.droplet.material.opacity *= 0.995;
        if (this.dropletY > this.viewH * 1.2) {
          this.scene.remove(this.droplet);
          this.droplet.geometry.dispose();
          this.droplet = null;
          this.reset();
        }
      }
    }

    spawnDroplet() {
      const geo = new THREE.SphereGeometry(this.width * 1.4, 10, 8);
      const mat = this.material.clone();
      this.droplet = new THREE.Mesh(geo, mat);
      this.droplet.position.set(this.anchorX, this.anchorY + this.length, 0);
      this.dropletY = this.anchorY + this.length;
      this.dropletVy = 20;
      this.scene.add(this.droplet);
      // strand snaps back up while the droplet falls on its own
      this.length = this.length * 0.35;
    }

    dispose() {
      if (this.mesh) { this.scene.remove(this.mesh); this.mesh.geometry.dispose(); }
      if (this.droplet) { this.scene.remove(this.droplet); this.droplet.geometry.dispose(); }
    }
  }

  window.SPITLAB = window.SPITLAB || {};
  window.SPITLAB.DripStrand = DripStrand;

  /* ---------- mount the ambient layer ---------- */
  function init() {
    const canvas = document.getElementById('drip-canvas');
    if (!canvas) return;

    const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true, powerPreference: 'low-power' });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));

    const scene = new THREE.Scene();
    let w = window.innerWidth, h = window.innerHeight;
    const camera = new THREE.OrthographicCamera(0, w, 0, h, -1000, 1000);
    camera.position.z = 100;

    const hemi = new THREE.HemisphereLight(0xffffff, 0x111111, 1.1);
    scene.add(hemi);
    const key = new THREE.DirectionalLight(0xffffff, 0.6);
    key.position.set(-200, 200, 300);
    scene.add(key);

    const maxStrands = window.innerWidth < 720 ? 5 : 9;
    let strands = [];

    function buildStrands() {
      strands.forEach((s) => s.dispose());
      strands = [];
      for (let i = 0; i < maxStrands; i++) {
        strands.push(new window.SPITLAB.DripStrand(scene, {
          anchorX: Math.random() * w,
          anchorY: 0,
          viewH: h,
          accent: Math.random() < 0.16,
        }));
      }
    }

    function resize() {
      w = window.innerWidth; h = window.innerHeight;
      renderer.setSize(w, h);
      camera.left = 0; camera.right = w; camera.top = 0; camera.bottom = h;
      camera.updateProjectionMatrix();
      buildStrands();
    }

    resize();
    window.addEventListener('resize', debounce(resize, 250));

    let last = performance.now();
    function tick(now) {
      requestAnimationFrame(tick);
      if (window.SPITLAB.tabHidden) { last = now; return; }
      const dt = Math.min((now - last) / 1000, 0.05);
      last = now;
      const elapsed = now / 1000;
      strands.forEach((s) => s.update(dt, elapsed));
      renderer.render(scene, camera);
    }
    requestAnimationFrame(tick);
  }

  function debounce(fn, ms) {
    let t;
    return function (...args) {
      clearTimeout(t);
      t = setTimeout(() => fn.apply(this, args), ms);
    };
  }

  document.addEventListener('DOMContentLoaded', init);
})();
