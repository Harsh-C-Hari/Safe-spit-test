/* ============================================
   SPITLAB — main.js
   Shared across every page: header state, grain,
   splatter decal placement, reduced-motion / low-end
   GPU detection, mobile nav.
   ============================================ */

(function () {
  'use strict';

  /* ---------- capability flags (exposed globally) ---------- */
  const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function detectLowEndGPU() {
    try {
      const canvas = document.createElement('canvas');
      const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
      if (!gl) return true;
      const dbg = gl.getExtension('WEBGL_debug_renderer_info');
      const renderer = dbg ? gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL) : '';
      const isSoftware = /swiftshader|software|llvmpipe/i.test(renderer || '');
      const fewCores = navigator.hardwareConcurrency && navigator.hardwareConcurrency <= 2;
      const isSmallScreen = window.innerWidth < 640;
      return isSoftware || (fewCores && isSmallScreen);
    } catch (e) {
      return true;
    }
  }

  window.SPITLAB = window.SPITLAB || {};
  window.SPITLAB.prefersReduced = prefersReduced;
  window.SPITLAB.lowEndGPU = detectLowEndGPU();
  window.SPITLAB.useFallback = prefersReduced || window.SPITLAB.lowEndGPU;

  if (window.SPITLAB.useFallback) {
    document.documentElement.classList.add('reduced-motion');
  }

  document.addEventListener('DOMContentLoaded', () => {
    initHeader();
    initGrain();
    initSplatterField();
    initCssDripFallback();
    initMobileNav();
    initVisibilityPause();
  });

  /* ---------- header: frost on scroll ---------- */
  function initHeader() {
    const header = document.querySelector('.site-header');
    if (!header) return;
    const onScroll = () => {
      header.classList.toggle('is-scrolled', window.scrollY > 12);
    };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  /* ---------- mobile nav ---------- */
  function initMobileNav() {
    const toggle = document.querySelector('.nav-toggle');
    const nav = document.querySelector('.main-nav');
    if (!toggle || !nav) return;
    toggle.addEventListener('click', () => {
      const open = nav.classList.toggle('is-open');
      toggle.setAttribute('aria-expanded', String(open));
    });
  }

  /* ---------- grain overlay: generate a tiny noise tile as a data URL ---------- */
  function initGrain() {
    const el = document.getElementById('grain-overlay');
    if (!el) return;
    const size = 128;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');
    const imgData = ctx.createImageData(size, size);
    for (let i = 0; i < imgData.data.length; i += 4) {
      const v = Math.floor(Math.random() * 255);
      imgData.data[i] = v;
      imgData.data[i + 1] = v;
      imgData.data[i + 2] = v;
      imgData.data[i + 3] = 255;
    }
    ctx.putImageData(imgData, 0, 0);
    el.style.backgroundImage = `url(${canvas.toDataURL()})`;
    el.style.backgroundSize = '128px 128px';
  }

  /* ---------- splatter field: scatter a small set of SVG shapes per page ---------- */
  const SPLAT_PATHS = [
    'M20 0c6 4 14 6 18 14 4 8-2 16-12 18-10 2-20-4-24-12C-2 12 8 2 20 0Z',
    'M10 2c8-3 20 1 24 10 4 9-4 18-14 19C10 32 0 24 1 14 2 8 4 4 10 2Z',
    'M4 10c2-6 10-10 18-8 8 2 14 10 12 18-2 8-12 12-20 9C6 26 1 18 4 10Z',
  ];

  function randRange(a, b) { return a + Math.random() * (b - a); }

  function makeSplat(accent, seedScale) {
    const ns = 'http://www.w3.org/2000/svg';
    const svg = document.createElementNS(ns, 'svg');
    const size = randRange(46, 108) * seedScale;
    svg.setAttribute('viewBox', '0 0 40 34');
    svg.setAttribute('width', size);
    svg.setAttribute('height', size * 0.85);
    svg.classList.add('splat-decal');
    if (accent) svg.classList.add('accent');

    const path = document.createElementNS(ns, 'path');
    path.setAttribute('d', SPLAT_PATHS[Math.floor(Math.random() * SPLAT_PATHS.length)]);
    const fill = accent ? '#7c7a2e' : '#232323';
    const stroke = accent ? 'rgba(168,162,58,0.55)' : 'rgba(216,216,216,0.14)';
    path.setAttribute('fill', fill);
    path.setAttribute('fill-opacity', accent ? '0.55' : '0.6');
    path.setAttribute('stroke', stroke);
    path.setAttribute('stroke-width', '0.6');
    svg.appendChild(path);

    svg.style.left = randRange(-2, 92) + 'vw';
    svg.style.top = randRange(4, 92) + 'vh';
    svg.style.transform = `rotate(${randRange(0, 360)}deg)`;
    return svg;
  }

  function initSplatterField() {
    const existing = document.querySelector('.splatter-field');
    if (!existing) return;
    const count = window.innerWidth < 720 ? 5 : 8;
    for (let i = 0; i < count; i++) {
      const accent = i % 4 === 0;
      existing.appendChild(makeSplat(accent, accent ? 0.6 : 1));
    }
  }

  /* ---------- CSS fallback drips (used instead of the WebGL drip canvas) ---------- */
  function initCssDripFallback() {
    if (!window.SPITLAB.useFallback) return;
    const layer = document.getElementById('css-drip-layer');
    if (!layer) return;
    layer.classList.add('is-active');
    const count = 7;
    for (let i = 0; i < count; i++) {
      const drip = document.createElement('div');
      drip.className = 'css-drip' + (i % 5 === 0 ? ' accent' : '');
      drip.style.left = randRange(2, 96) + 'vw';
      drip.style.animationDuration = randRange(3.5, 7) + 's';
      drip.style.animationDelay = randRange(0, 5) + 's';
      layer.appendChild(drip);
    }
  }

  /* ---------- pause heavy rendering when tab hidden ---------- */
  function initVisibilityPause() {
    document.addEventListener('visibilitychange', () => {
      window.SPITLAB.tabHidden = document.hidden;
    });
  }
})();
