import React, { useState, useEffect, useRef } from 'react';
import gsap from 'gsap';

export const Section05: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [speed, setSpeed] = useState(50);
  const [angle, setAngle] = useState(45);
  const [wind, setWind] = useState(50);

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from('.calib-element', {
        opacity: 0,
        y: 20,
        duration: 0.8,
        stagger: 0.1,
        scrollTrigger: {
          trigger: containerRef.current,
          start: 'top 70%',
        }
      });
    }, containerRef);
    return () => ctx.revert();
  }, []);

  const cpX = 50 + (wind - 50) * 0.4;
  const cpY = 90 - (speed * 0.8);
  const endX = 10 + (speed * 0.8);
  const endY = 90;
  const pathD = `M10,90 Q${cpX},${cpY} ${endX},${endY}`;

  const inputStyle = {
    width: '100%',
    cursor: 'pointer'
  };

  return (
    <section ref={containerRef} className="responsive-section" style={{ minHeight: '100vh', padding: '10vw', backgroundColor: 'var(--color-bg)', color: 'var(--color-black)' }}>
      <h2 className="calib-element responsive-h2" style={{ fontSize: '6vw', textTransform: 'uppercase', marginBottom: '8vh', letterSpacing: '-0.02em', lineHeight: 1 }}>
        MANUAL CALIBRATION
      </h2>

      <div className="responsive-flex" style={{ display: 'flex', flexWrap: 'wrap', gap: '4vw' }}>
        <div className="calib-element" style={{ flex: '1 1 300px', display: 'flex', flexDirection: 'column', gap: '4vh', fontFamily: 'var(--font-technical)', border: 'var(--border-strong)', padding: '2vw', backgroundColor: 'var(--color-black)', color: 'var(--color-bg)' }}>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1vh' }}>
              <span style={{ opacity: 0.5 }}>VELOCITY</span>
              <span style={{ color: 'var(--color-acid-green)' }}>{speed} m/s</span>
            </div>
            <input type="range" min="10" max="100" value={speed} onChange={(e) => setSpeed(Number(e.target.value))} style={inputStyle} />
          </div>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1vh' }}>
              <span style={{ opacity: 0.5 }}>PITCH</span>
              <span style={{ color: 'var(--color-acid-green)' }}>{angle}°</span>
            </div>
            <input type="range" min="10" max="80" value={angle} onChange={(e) => setAngle(Number(e.target.value))} style={inputStyle} />
          </div>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1vh' }}>
              <span style={{ opacity: 0.5 }}>WIND_SHEAR</span>
              <span style={{ color: 'var(--color-acid-green)' }}>{wind}%</span>
            </div>
            <input type="range" min="0" max="100" value={wind} onChange={(e) => setWind(Number(e.target.value))} style={inputStyle} />
          </div>
        </div>

        <div className="calib-element" style={{ flex: '2 1 400px', border: 'var(--border-strong)', height: '50vh', position: 'relative', overflow: 'hidden' }}>
          <svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none">
            {/* Grid */}
            <path d="M0,25 L100,25 M0,50 L100,50 M0,75 L100,75 M25,0 L25,100 M50,0 L50,100 M75,0 L75,100" fill="none" stroke="var(--color-black)" strokeWidth="0.1" opacity="0.2" />
            <path d={pathD} fill="none" stroke="var(--color-acid-green)" strokeWidth="1" />
            <circle cx={endX} cy={endY} r="1.5" fill="var(--color-acid-green)" />
          </svg>
          <div className="responsive-mono" style={{ position: 'absolute', bottom: '1vw', left: '1vw', fontFamily: 'var(--font-technical)', fontSize: '1vw', opacity: 0.5 }}>
            TARGET_POS: X={endX.toFixed(1)} Y={endY.toFixed(1)}
          </div>
        </div>
      </div>
    </section>
  );
};
