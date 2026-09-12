import React, { useEffect, useRef, useState } from 'react';
import gsap from 'gsap';


export const Section03: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [velocity, setVelocity] = useState(842);
  const [angle, setAngle] = useState(67.4);
  const [hex, setHex] = useState('0xA1B2C3');

  useEffect(() => {
    // Decorative rapidly updating counters
    const interval = setInterval(() => {
      setVelocity(Math.floor(Math.random() * 200) + 700);
      setAngle(parseFloat((Math.random() * 90).toFixed(2)));
      setHex('0x' + Math.floor(Math.random() * 16777215).toString(16).toUpperCase().padStart(6, '0'));
    }, 80);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const ctx = gsap.context(() => {
      // Small parallax or fade in
      gsap.from('.engine-card', {
        y: 50,
        opacity: 0,
        duration: 0.8,
        stagger: 0.2,
        ease: 'power3.out',
        scrollTrigger: {
          trigger: containerRef.current,
          start: 'top 70%',
        }
      });
    }, containerRef);
    return () => ctx.revert();
  }, []);

  return (
    <section ref={containerRef} style={{ minHeight: '100vh', padding: '10vw', backgroundColor: 'var(--color-bg)', color: 'var(--color-black)' }}>
      <h2 style={{ fontSize: '6vw', textTransform: 'uppercase', marginBottom: '8vh', letterSpacing: '-0.02em', lineHeight: 1 }}>
        THE RETURN ENGINE
      </h2>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2vw', fontFamily: 'var(--font-technical)' }}>
        <div className="engine-card" style={{ border: 'var(--border-strong)', padding: '2vw', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ opacity: 0.5, marginBottom: '2vh', fontSize: '1.2vw' }}>VELOCITY_INPUT (m/s)</div>
          <div style={{ fontSize: '6vw', fontWeight: 600, lineHeight: 1 }}>{velocity}.04</div>
        </div>

        <div className="engine-card" style={{ border: 'var(--border-strong)', padding: '2vw', backgroundColor: 'var(--color-black)', color: 'var(--color-acid-green)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ opacity: 0.8, marginBottom: '2vh', fontSize: '1.2vw' }}>RETURN_ANGLE (deg)</div>
          <div style={{ fontSize: '6vw', fontWeight: 600, lineHeight: 1 }}>{angle.toFixed(2)}°</div>
        </div>

        <div className="engine-card" style={{ gridColumn: '1 / -1', border: 'var(--border-strong)', padding: '2vw', height: '40vh', position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
          <div style={{ opacity: 0.5, marginBottom: '2vh', fontSize: '1.2vw', zIndex: 1 }}>TRAJECTORY_SIMULATION</div>

          {/* Abstract SVG diagram */}
          <svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none" style={{ position: 'absolute', top: 0, left: 0, opacity: 0.1 }}>
            <path d="M10,90 Q50,10 90,90" fill="none" stroke="var(--color-black)" strokeWidth="0.5" strokeDasharray="1,1" />
            <path d="M10,90 Q50,40 90,90" fill="none" stroke="var(--color-black)" strokeWidth="1" />
            <line x1="10" y1="90" x2="90" y2="90" stroke="var(--color-black)" strokeWidth="2" />
            <circle cx="50" cy="40" r="1" fill="var(--color-black)" />
          </svg>

          <div style={{ position: 'absolute', bottom: '2vw', left: '2vw', fontSize: '1.2vw', opacity: 0.5, zIndex: 1 }}>
            CALCULATING... [{hex}]
          </div>
          <div style={{ position: 'absolute', bottom: '2vw', right: '2vw', fontSize: '1.2vw', opacity: 0.5, zIndex: 1 }}>
            SYS_NOMINAL
          </div>
        </div>
      </div>
    </section>
  );
};
