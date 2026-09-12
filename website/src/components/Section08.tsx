import React, { useEffect, useRef } from 'react';
import gsap from 'gsap';

export const Section08: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const qRef = useRef<HTMLDivElement>(null);
  const noRef = useRef<HTMLDivElement>(null);
  const butRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: containerRef.current,
          start: "top top",
          end: "+=200%",
          scrub: 1,
          pin: true,
        }
      });

      tl.fromTo(qRef.current, { opacity: 0, scale: 0.9 }, { opacity: 1, scale: 1, duration: 1 })
        .to(qRef.current, { opacity: 0, y: -50, duration: 1 })
        .fromTo(noRef.current, { opacity: 0, scale: 2 }, { opacity: 1, scale: 1, duration: 1, ease: "bounce.out" })
        .to(noRef.current, { opacity: 0, y: -50, duration: 1 }, "+=0.5")
        .fromTo(butRef.current, { opacity: 0, y: 50 }, { opacity: 1, y: 0, duration: 1 });
    }, containerRef);
    return () => ctx.revert();
  }, []);

  return (
    <section ref={containerRef} style={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: 'var(--color-black)', color: 'var(--color-bg)', overflow: 'hidden', position: 'relative' }}>
      <div ref={qRef} style={{ position: 'absolute', fontSize: '8vw', textTransform: 'uppercase', opacity: 0, textAlign: 'center', lineHeight: 1 }}>
        WAS THIS NECESSARY?
      </div>
      <div ref={noRef} style={{ position: 'absolute', fontSize: '20vw', textTransform: 'uppercase', color: 'var(--color-orange)', opacity: 0, fontWeight: 700, lineHeight: 1 }}>
        NO.
      </div>
      <div ref={butRef} style={{ position: 'absolute', fontSize: '6vw', textTransform: 'uppercase', color: 'var(--color-acid-green)', opacity: 0, textAlign: 'center', lineHeight: 1 }}>
        BUT IT WORKS.
      </div>
    </section>
  );
};
