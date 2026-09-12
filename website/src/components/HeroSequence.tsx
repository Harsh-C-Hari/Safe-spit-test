import React, { useEffect, useRef } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

export const HeroSequence: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const textTitleRef = useRef<HTMLHeadingElement>(null);
  const textSubRef = useRef<HTMLDivElement>(null);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      if (!containerRef.current) return;

      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: containerRef.current,
          start: "top top",
          end: "+=400%",
          scrub: 1,
          pin: true,
        }
      });

      // Video scrub duration sync
      tl.fromTo(videoRef.current,
        { currentTime: 0 },
        { currentTime: 10, ease: "none", duration: 1 },
        0
      );

      // Title zoom out
      tl.to(textTitleRef.current, {
        scale: 4,
        opacity: 0,
        ease: "power2.in",
        duration: 0.3
      }, 0);

      // Scroll to begin fade out
      tl.to(scrollRef.current, {
        opacity: 0,
        duration: 0.2
      }, 0);

      // Subtitles come in
      tl.fromTo(textSubRef.current,
        { opacity: 0, y: 50 },
        { opacity: 1, y: 0, duration: 0.2 },
        0.3
      );

      // Subtitles go out
      tl.to(textSubRef.current, {
        opacity: 0,
        y: -50,
        duration: 0.2
      }, 0.7);

    }, containerRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={containerRef} style={{ width: '100vw', height: '100vh', position: 'relative', overflow: 'hidden', backgroundColor: 'var(--color-black)', color: 'var(--color-bg)' }}>
      <video
        ref={videoRef}
        src="https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"
        style={{ width: '100%', height: '100%', objectFit: 'cover', opacity: 0.4 }}
        muted
        playsInline
        preload="auto"
      />
      <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', pointerEvents: 'none' }}>
        <h1 ref={textTitleRef} style={{ fontSize: '14vw', margin: 0, textTransform: 'uppercase', letterSpacing: '-0.02em', whiteSpace: 'nowrap', lineHeight: 1 }}>
          SAFE//SPIT
        </h1>
        <div ref={textSubRef} style={{ textAlign: 'center', position: 'absolute', opacity: 0 }}>
          <h2 style={{ fontSize: '5vw', margin: '0 0 1rem 0', textTransform: 'uppercase', lineHeight: 1 }}>THEY REJECTED YOU.</h2>
          <h2 style={{ fontSize: '3vw', margin: '0 0 1rem 0', color: 'var(--color-acid-green)', textTransform: 'uppercase', lineHeight: 1 }}>SO WE CALCULATED THE RETURN.</h2>
          <p style={{ fontSize: '1.5vw', margin: 0, fontFamily: 'var(--font-technical)', color: 'var(--color-gray)' }}>RETURN ANGLE 67.4°</p>
        </div>
      </div>
      <div ref={scrollRef} style={{ position: 'absolute', bottom: '4vh', width: '100%', textAlign: 'center', fontFamily: 'var(--font-technical)', fontSize: '0.85rem', letterSpacing: '0.1em', opacity: 0.5 }}>
        SCROLL TO BEGIN
      </div>
    </section>
  );
};
