import React, { useEffect, useRef } from 'react';
import gsap from 'gsap';


export const Section02: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const textRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      if (textRef.current) {
        const lines = textRef.current.children;
        gsap.fromTo(lines,
          { opacity: 0.1, y: 30 },
          {
            opacity: 1,
            y: 0,
            stagger: 0.2,
            ease: "power2.out",
            scrollTrigger: {
              trigger: containerRef.current,
              start: "top 60%",
              end: "bottom 80%",
              scrub: 1
            }
          }
        );
      }
    }, containerRef);
    return () => ctx.revert();
  }, []);

  return (
    <section ref={containerRef} style={{ minHeight: '150vh', display: 'flex', alignItems: 'center', padding: '10vw', backgroundColor: 'var(--color-bg)', color: 'var(--color-black)' }}>
      <div ref={textRef} style={{ display: 'flex', flexDirection: 'column', gap: '4vh', fontSize: '7vw', lineHeight: '1.05', textTransform: 'uppercase', letterSpacing: '-0.02em', fontWeight: 500 }}>
        <div>THEY REJECTED YOU.</div>
        <div>WE TOOK THAT PERSONALLY.</div>
        <div>SO WE DID THE ONLY REASONABLE THING.</div>
        <div style={{ color: 'var(--color-orange)' }}>WE CALCULATED THE RETURN.</div>
      </div>
    </section>
  );
};
