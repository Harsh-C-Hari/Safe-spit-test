import React, { useEffect, useRef } from 'react';
import gsap from 'gsap';

export const Section04: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from('.science-fade', {
        opacity: 0,
        y: 30,
        duration: 1,
        stagger: 0.2,
        ease: 'power2.out',
        scrollTrigger: {
          trigger: containerRef.current,
          start: 'top 60%',
        }
      });
    }, containerRef);
    return () => ctx.revert();
  }, []);

  return (
    <section ref={containerRef} style={{ minHeight: '100vh', padding: '10vw', backgroundColor: 'var(--color-black)', color: 'var(--color-bg)' }}>
      <h2 className="science-fade" style={{ fontSize: '6vw', textTransform: 'uppercase', marginBottom: '8vh', letterSpacing: '-0.02em', color: 'var(--color-acid-green)', lineHeight: 1 }}>
        THE SCIENCE
      </h2>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8vw' }}>
        <div className="science-fade" style={{ fontSize: '2.5vw', lineHeight: '1.2', opacity: 0.9, letterSpacing: '-0.01em' }}>
          <p style={{ marginBottom: '4vh' }}>
            We don't just guess. We use a proprietary blend of kinematics, wind-resistance modeling, and spite.
          </p>
          <p>
            By analyzing the inbound trajectory vector and combining it with the user's localized gravitational constant, SAFE//SPIT deterministically generates the absolute worst possible return path.
          </p>
        </div>

        <div className="science-fade" style={{ fontFamily: 'var(--font-technical)', fontSize: '1.2vw', borderLeft: '1px solid var(--color-acid-green)', paddingLeft: '4vw', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
          <div style={{ marginBottom: '6vh' }}>
            <div style={{ opacity: 0.5, marginBottom: '1vh' }}>FORMULA_01</div>
            <div style={{ fontSize: '3vw', color: 'var(--color-acid-green)', lineHeight: 1 }}>
              R = (v₀² * sin(2θ)) / g + ε
            </div>
            <div style={{ fontSize: '1vw', opacity: 0.5, marginTop: '2vh' }}>* where ε is the spite coefficient</div>
          </div>

          <div>
            <div style={{ opacity: 0.5, marginBottom: '2vh' }}>INSTRUMENTATION_DUMP</div>
            <div style={{ opacity: 0.8, lineHeight: '1.6', letterSpacing: '0.05em' }}>
              SYS_CHECK: OK<br />
              GRAVITY: 9.81 m/s²<br />
              WIND_RESISTANCE: ACTIVE<br />
              TARGET_LOCK: ENGAGED<br />
              <br />
              <span style={{ opacity: 0.5 }}>
                0x00A1F 0x44B2C 0x99D3E<br />
                0x11B4D 0x55C3A 0x88E2F<br />
                0x22C5E 0x66D4B 0x77F1D
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
