/* ============================================
   SPITLAB — simulator.js
   Playable teaser: aim, set power + spit type, launch
   a 3D glob on a simplified parabolic arc, splat on
   impact. Three.js renders the glob + target; a 2D
   overlay canvas draws the trail + splat marks
   (via splatter-shader.js) and the HUD.
   ============================================ */

import * as THREE from 'three';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';

(function () {
  'use strict';

  const TYPES = {
    normal:   { label: 'NORMAL',   color: '#d8d8d8', radius: 9,  gravityMul: 1.0, trail: 'plain' },
    murukkan: { label: 'MURUKKAN', color: '#a8a23a', radius: 9,  gravityMul: 0.95, trail: 'plain' },
    heavy:    { label: 'HEAVY',    color: '#c3c3c3', radius: 15, gravityMul: 1.5, trail: 'plain' },
    bubble:   { label: 'BUBBLE',   color: '#e8e8e6', radius: 10, gravityMul: 0.85, trail: 'bubble' },
  };

  const G = 640; // px/s^2, y-down so gravity is positive

  function init() {
    const stage = document.querySelector('.sim-stage');
    const glCanvas = document.getElementById('sim-canvas');
    const overlay = document.getElementById('splat-overlay');
    if (!stage || !glCanvas || !overlay) return;

    const octx = overlay.getContext('2d');
    let w = stage.clientWidth, h = stage.clientHeight;
    let dpr = Math.min(window.devicePixelRatio || 1, 2);

    /* ---------- three.js scene (glob + target only — ambient drips already
       run globally via fluid-system.js) ---------- */
    let renderer, scene, camera, glob, targetMesh, mouthMesh, pmrem;
    const useGL = !(window.SPITLAB && window.SPITLAB.useFallback);

    if (useGL) {
      renderer = new THREE.WebGLRenderer({ canvas: glCanvas, alpha: true, antialias: true });
      renderer.setPixelRatio(dpr);
      scene = new THREE.Scene();
      pmrem = new THREE.PMREMGenerator(renderer);
      scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.05).texture;
      camera = new THREE.OrthographicCamera(0, w, 0, h, -1000, 1000);
      camera.position.z = 400;

      scene.add(new THREE.AmbientLight(0xffffff, 0.7));
      const key = new THREE.DirectionalLight(0xffffff, 1.1);
      key.position.set(-200, -200, 400);
      scene.add(key);

      const targetGeo = new THREE.CircleGeometry(1, 40);
      const targetMat = new THREE.MeshPhysicalMaterial({ color: 0x161616, roughness: 0.8, metalness: 0 });
      targetMesh = new THREE.Mesh(targetGeo, targetMat);
      scene.add(targetMesh);

      // simple face glyph drawn onto a canvas texture, applied to the target circle
      const faceCanvas = document.createElement('canvas');
      faceCanvas.width = faceCanvas.height = 256;
      const fctx = faceCanvas.getContext('2d');
      fctx.fillStyle = '#161616'; fctx.fillRect(0, 0, 256, 256);
      fctx.strokeStyle = 'rgba(234,234,234,0.5)'; fctx.lineWidth = 4;
      fctx.beginPath(); fctx.ellipse(128, 128, 118, 118, 0, 0, Math.PI * 2); fctx.stroke();
      fctx.fillStyle = 'rgba(234,234,234,0.8)';
      fctx.beginPath(); fctx.ellipse(92, 108, 9, 13, 0, 0, Math.PI * 2); fctx.fill();
      fctx.beginPath(); fctx.ellipse(164, 108, 9, 13, 0, 0, Math.PI * 2); fctx.fill();
      fctx.strokeStyle = 'rgba(234,234,234,0.6)'; fctx.lineWidth = 5; fctx.lineCap = 'round';
      fctx.beginPath(); fctx.moveTo(96, 168); fctx.quadraticCurveTo(128, 150, 160, 168); fctx.stroke();
      const faceTex = new THREE.CanvasTexture(faceCanvas);
      targetMesh.material.map = faceTex;
      targetMesh.material.needsUpdate = true;

      const mouthGeo = new THREE.CircleGeometry(1, 24);
      const mouthMat = new THREE.MeshBasicMaterial({ color: 0x2a2a2a });
      mouthMesh = new THREE.Mesh(mouthGeo, mouthMat);
      scene.add(mouthMesh);

      const globGeo = new THREE.SphereGeometry(1, 20, 16);
      const globMat = new THREE.MeshPhysicalMaterial({
        color: 0xd8d8d8, roughness: 0.08, transmission: 0.5, thickness: 1.2,
        ior: 1.35, clearcoat: 1, clearcoatRoughness: 0.1,
      });
      glob = new THREE.Mesh(globGeo, globMat);
      glob.visible = false;
      scene.add(glob);
    }

    /* ---------- layout ---------- */
    let target = { x: 0, y: 0, r: 0 };
    let mouth = { x: 0, y: 0, r: 0 };

    function layout() {
      w = stage.clientWidth; h = stage.clientHeight;
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      overlay.width = w * dpr; overlay.height = h * dpr;
      overlay.style.width = w + 'px'; overlay.style.height = h + 'px';
      octx.setTransform(dpr, 0, 0, dpr, 0, 0);

      target = { x: w * 0.5, y: h * 0.42, r: Math.min(w, h) * 0.15 };
      mouth = { x: w * 0.5, y: h * 0.98, r: 14 };

      if (useGL) {
        renderer.setSize(w, h);
        camera.left = 0; camera.right = w; camera.top = 0; camera.bottom = h;
        camera.updateProjectionMatrix();
        targetMesh.scale.setScalar(target.r);
        targetMesh.position.set(target.x, target.y, -5);
        mouthMesh.scale.setScalar(mouth.r);
        mouthMesh.position.set(mouth.x, mouth.y, 0);
      }
    }

    /* ---------- aim + power state ---------- */
    let aimDeg = 0; // -40..40, 0 = straight up
    let power = 62; // 0..100
    let activeType = 'normal';
    let hits = 0, misses = 0;

    const powerInput = document.getElementById('power-input');
    const spitBtn = document.getElementById('spit-btn');
    const hitsEl = document.getElementById('hud-hits');
    const missesEl = document.getElementById('hud-misses');
    const typeButtons = document.querySelectorAll('.type-btn');
    const aimHint = document.getElementById('aim-readout');

    typeButtons.forEach((btn) => {
      btn.addEventListener('click', () => {
        typeButtons.forEach((b) => b.classList.remove('is-active'));
        btn.classList.add('is-active');
        activeType = btn.dataset.type;
      });
    });

    if (powerInput) {
      powerInput.addEventListener('input', () => { power = Number(powerInput.value); });
    }

    stage.addEventListener('pointermove', (e) => {
      const rect = stage.getBoundingClientRect();
      const px = (e.clientX - rect.left) / rect.width; // 0..1
      aimDeg = THREE.MathUtils.clamp((px - 0.5) * 90, -42, 42);
      if (aimHint) aimHint.textContent = Math.round(aimDeg) + '°';
    });

    function launch() {
      if (projectile.active) return;
      const cfg = TYPES[activeType];
      const speed = 260 + (power / 100) * 520;
      const rad = (aimDeg * Math.PI) / 180;
      projectile.active = true;
      projectile.x = mouth.x;
      projectile.y = mouth.y - mouth.r;
      projectile.vx = Math.sin(rad) * speed;
      projectile.vy = -Math.cos(rad) * speed;
      projectile.type = activeType;
      projectile.radius = cfg.radius;
      projectile.trailPts = [];
      projectile.startY = projectile.y;
      if (useGL) { glob.visible = true; glob.material.color.set(cfg.color); }
    }

    if (spitBtn) spitBtn.addEventListener('click', launch);
    window.addEventListener('keydown', (e) => {
      if (e.code === 'Space' && document.activeElement !== powerInput) {
        e.preventDefault();
        launch();
      }
    });

    /* ---------- projectile state ---------- */
    const projectile = { active: false, x: 0, y: 0, vx: 0, vy: 0, radius: 9, type: 'normal', trailPts: [], startY: 0 };
    let shake = 0;

    function resolveEnd(hit) {
      const cfg = TYPES[projectile.type];
      window.SPITLAB.drawSplat(octx, {
        x: projectile.x, y: projectile.y,
        radius: hit ? cfg.radius * 3.4 : cfg.radius * 2.2,
        color: cfg.color,
        accentColor: '#a8a23a',
        alpha: hit ? 0.9 : 0.55,
        satellites: hit ? 8 : 4,
      });
      if (hit) { hits++; if (hitsEl) hitsEl.textContent = String(hits); shake = 10; }
      else { misses++; if (missesEl) missesEl.textContent = String(misses); }
      projectile.active = false;
      if (useGL) glob.visible = false;
    }

    function step(dt) {
      if (!projectile.active) return;
      const cfg = TYPES[projectile.type];
      projectile.vy += G * cfg.gravityMul * dt;
      projectile.x += projectile.vx * dt;
      projectile.y += projectile.vy * dt;
      projectile.trailPts.push({ x: projectile.x, y: projectile.y });
      if (projectile.trailPts.length > 26) projectile.trailPts.shift();

      const dx = projectile.x - target.x, dy = projectile.y - target.y;
      if (Math.sqrt(dx * dx + dy * dy) < target.r * 0.92 + projectile.radius) {
        resolveEnd(true);
        return;
      }
      if (projectile.y > mouth.y + 40 || projectile.x < -60 || projectile.x > w + 60) {
        resolveEnd(false);
        return;
      }

      if (useGL) {
        glob.position.set(projectile.x, projectile.y, 10);
        glob.scale.setScalar(projectile.radius);
      }
    }

    function drawOverlay() {
      // trail: short translucent strokes behind the in-flight glob. Splats from
      // past impacts are left as a permanent record on the same canvas — a
      // visible trace of every spit taken, which reads as a feature not a bug.
      if (projectile.active && projectile.trailPts.length > 1) {
        const cfg = TYPES[projectile.type];
        octx.save();
        octx.lineCap = 'round';
        for (let i = 1; i < projectile.trailPts.length; i++) {
          const a = projectile.trailPts[i - 1], b = projectile.trailPts[i];
          const t = i / projectile.trailPts.length;
          octx.globalAlpha = t * 0.35;
          octx.strokeStyle = cfg.color;
          octx.lineWidth = projectile.radius * 0.5 * t;
          octx.beginPath(); octx.moveTo(a.x, a.y); octx.lineTo(b.x, b.y); octx.stroke();
        }
        octx.restore();
      }
    }

    /* ---------- render loop ---------- */
    let last = performance.now();
    function tick(now) {
      requestAnimationFrame(tick);
      if (window.SPITLAB.tabHidden) { last = now; return; }
      const dt = Math.min((now - last) / 1000, 0.033);
      last = now;
      step(dt);
      drawOverlay();

      if (useGL) {
        if (shake > 0) {
          camera.position.x = (Math.random() - 0.5) * shake;
          camera.position.y = (Math.random() - 0.5) * shake;
          shake *= 0.82;
          if (shake < 0.2) { shake = 0; camera.position.set(0, 0, 400); }
        }
        renderer.render(scene, camera);
      }
    }

    layout();
    window.addEventListener('resize', debounce(layout, 200));
    requestAnimationFrame(tick);
  }

  function debounce(fn, ms) {
    let t;
    return function (...args) { clearTimeout(t); t = setTimeout(() => fn.apply(this, args), ms); };
  }

  document.addEventListener('DOMContentLoaded', init);
})();
