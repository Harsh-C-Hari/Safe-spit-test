/* ============================================
   SPITLAB — hero-wordmark.js
   3D extruded liquid-glass wordmark. Lower edge of
   each letter sags via noise-displaced vertices; a
   handful of DripStrand instances (from
   fluid-system.js) hang off the bottom edge.
   ============================================ */

import * as THREE from 'three';
import { FontLoader } from 'three/addons/loaders/FontLoader.js';
import { TextGeometry } from 'three/addons/geometries/TextGeometry.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';

(function () {
  'use strict';

  // compact 3D simplex noise (Ashima/Stefan Gustavson public-domain technique),
  // used only for the vertex-sag displacement below.
  const NOISE_GLSL = `
    vec3 mod289(vec3 x){return x-floor(x*(1.0/289.0))*289.0;}
    vec4 mod289(vec4 x){return x-floor(x*(1.0/289.0))*289.0;}
    vec4 permute(vec4 x){return mod289(((x*34.0)+1.0)*x);}
    vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
    float snoise(vec3 v){
      const vec2  C = vec2(1.0/6.0, 1.0/3.0);
      const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);
      vec3 i  = floor(v + dot(v, C.yyy));
      vec3 x0 = v - i + dot(i, C.xxx);
      vec3 g = step(x0.yzx, x0.xyz);
      vec3 l = 1.0 - g;
      vec3 i1 = min(g.xyz, l.zxy);
      vec3 i2 = max(g.xyz, l.zxy);
      vec3 x1 = x0 - i1 + C.xxx;
      vec3 x2 = x0 - i2 + C.yyy;
      vec3 x3 = x0 - D.yyy;
      i = mod289(i);
      vec4 p = permute(permute(permute(
                i.z + vec4(0.0, i1.z, i2.z, 1.0))
              + i.y + vec4(0.0, i1.y, i2.y, 1.0))
              + i.x + vec4(0.0, i1.x, i2.x, 1.0));
      float n_ = 0.142857142857;
      vec3 ns = n_ * D.wyz - D.xzx;
      vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
      vec4 x_ = floor(j * ns.z);
      vec4 y_ = floor(j - 7.0 * x_);
      vec4 x = x_ *ns.x + ns.yyyy;
      vec4 y = y_ *ns.x + ns.yyyy;
      vec4 h = 1.0 - abs(x) - abs(y);
      vec4 b0 = vec4(x.xy, y.xy);
      vec4 b1 = vec4(x.zw, y.zw);
      vec4 s0 = floor(b0)*2.0 + 1.0;
      vec4 s1 = floor(b1)*2.0 + 1.0;
      vec4 sh = -step(h, vec4(0.0));
      vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
      vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;
      vec3 p0 = vec3(a0.xy, h.x);
      vec3 p1 = vec3(a0.zw, h.y);
      vec3 p2 = vec3(a1.xy, h.z);
      vec3 p3 = vec3(a1.zw, h.w);
      vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
      p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
      vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
      m = m * m;
      return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
    }
  `;

  function patchSagMaterial(material, minY, maxY) {
    material.userData.shader = null;
    material.onBeforeCompile = (shader) => {
      shader.uniforms.uTime = { value: 0 };
      shader.uniforms.uMinY = { value: minY };
      shader.uniforms.uMaxY = { value: maxY };
      shader.vertexShader = shader.vertexShader
        .replace('#include <common>', `#include <common>\nuniform float uTime;\nuniform float uMinY;\nuniform float uMaxY;\n${NOISE_GLSL}`)
        .replace(
          '#include <begin_vertex>',
          `#include <begin_vertex>
          float heightT = clamp((position.y - uMinY) / max(0.001, (uMaxY - uMinY)), 0.0, 1.0);
          float sagWeight = pow(1.0 - heightT, 3.0);
          float n = snoise(vec3(position.x * 0.05, uTime * 0.35, position.z * 0.4));
          transformed.y -= sagWeight * (2.2 + n * 2.4);
          transformed.x += sagWeight * n * 1.1;`
        );
      material.userData.shader = shader;
    };
  }

  function init() {
    const canvas = document.getElementById('hero-canvas');
    const mount = canvas ? canvas.closest('.hero-stage') : null;
    if (!canvas || !mount) return;

    const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.toneMapping = THREE.ACESFilmicToneMapping;

    const scene = new THREE.Scene();
    const pmrem = new THREE.PMREMGenerator(renderer);
    scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;

    let w = mount.clientWidth, h = mount.clientHeight;
    const camera = new THREE.OrthographicCamera(0, w, 0, h, -1000, 1000);
    camera.position.z = 300;

    const key = new THREE.DirectionalLight(0xffffff, 1.4);
    key.position.set(-300, -200, 400);
    scene.add(key);
    scene.add(new THREE.AmbientLight(0xffffff, 0.5));

    const group = new THREE.Group();
    scene.add(group);

    let textMesh = null;
    const strands = [];

    const loader = new FontLoader();
    loader.load(
      'https://unpkg.com/three@0.160.0/examples/fonts/helvetiker_bold.typeface.json',
      (font) => {
        const geo = new TextGeometry('SPITLAB', {
          font,
          size: 100,
          depth: 26,
          curveSegments: 6,
          bevelEnabled: true,
          bevelThickness: 4,
          bevelSize: 2.4,
          bevelSegments: 4,
        });
        geo.center();
        geo.computeBoundingBox(); // recompute AFTER centering so the box matches final vertex positions

        const material = new THREE.MeshPhysicalMaterial({
          color: 0xd8d8d8,
          roughness: 0.06,
          metalness: 0.02,
          transmission: 0.35,
          thickness: 1.6,
          ior: 1.4,
          clearcoat: 1,
          clearcoatRoughness: 0.08,
          sheen: 1,
          sheenColor: new THREE.Color(0xffffff),
          sheenRoughness: 0.3,
          side: THREE.DoubleSide,
        });
        patchSagMaterial(material, geo.boundingBox.min.y, geo.boundingBox.max.y);

        textMesh = new THREE.Mesh(geo, material);
        // font geometry is Y-up (ascenders = larger local Y), but our ortho camera
        // uses a Y-down screen convention (top=0, bottom=h) to match fluid-system.js —
        // flip the mesh so it reads right-side-up on screen.
        textMesh.scale.y = -1;
        group.add(textMesh);
        layout();

        // drip strands hanging off the bottom edge of the letters — added directly to
        // the top-level scene (not `group`) so their coordinates are plain world/screen
        // pixels, matching what DripStrand expects, avoiding a second nested transform.
        const box = new THREE.Box3().setFromObject(textMesh);
        const dripCount = window.innerWidth < 720 ? 4 : 8;
        for (let i = 0; i < dripCount; i++) {
          const anchorX = THREE.MathUtils.lerp(box.min.x, box.max.x, Math.random());
          const s = new window.SPITLAB.DripStrand(scene, {
            anchorX,
            anchorY: box.max.y, // world space, y-down: larger y = visual bottom edge
            viewH: (box.max.y - box.min.y) * 1.4,
            accent: i % 5 === 0,
          });
          strands.push(s);
        }
      },
      undefined,
      () => { /* font failed to load — CSS fallback headline text remains visible underneath */ }
    );

    function layout() {
      w = mount.clientWidth; h = mount.clientHeight;
      renderer.setSize(w, h);
      camera.left = 0; camera.right = w; camera.top = 0; camera.bottom = h;
      camera.updateProjectionMatrix();
      group.position.set(w / 2, h * 0.42, 0);
      const scale = Math.min(w / 780, 1.15) * (window.innerWidth < 640 ? 0.62 : 1);
      group.scale.setScalar(Math.max(scale, 0.36));
    }

    layout();
    window.addEventListener('resize', debounce(layout, 200));

    let last = performance.now();
    function tick(now) {
      requestAnimationFrame(tick);
      if (window.SPITLAB.tabHidden) { last = now; return; }
      const dt = Math.min((now - last) / 1000, 0.05);
      last = now;
      const elapsed = now / 1000;
      if (textMesh && textMesh.material.userData.shader) {
        textMesh.material.userData.shader.uniforms.uTime.value = elapsed;
      }
      strands.forEach((s) => s.update(dt, elapsed));
      renderer.render(scene, camera);
    }
    requestAnimationFrame(tick);
  }

  function debounce(fn, ms) {
    let t;
    return function (...args) { clearTimeout(t); t = setTimeout(() => fn.apply(this, args), ms); };
  }

  if (window.SPITLAB && window.SPITLAB.useFallback) {
    // static CSS/SVG headline stands in — see .hero-title-fallback in the markup
  } else {
    document.addEventListener('DOMContentLoaded', init);
  }
})();
