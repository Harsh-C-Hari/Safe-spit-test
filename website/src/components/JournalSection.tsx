import React, { useRef, useState, useEffect } from 'react';
import gsap from 'gsap';
import { Draggable } from 'gsap/Draggable';

// Register GSAP Plugins
if (typeof window !== 'undefined') {
  gsap.registerPlugin(Draggable);
}

interface JournalEntry {
  id: string;
  title: string;
  blurb: string;
  mediaType: 'image' | 'video';
  mediaSrc: string;
  poster?: string;
  alt: string;
}

const journalData: JournalEntry[] = [
  {
    id: "01",
    title: "JUST STARTED",
    blurb: "Just started the project without knowing anything wooh woohhhh",
    mediaType: "image",
    mediaSrc: "/useless/journal/image1.png",
    alt: "Project kickoff screenshot"
  },
  {
    id: "02",
    title: "RUNNING COOL SHITS",
    blurb: "Running some cool shits",
    mediaType: "image",
    mediaSrc: "/useless/journal/image2.png",
    alt: "Running something cool"
  },
  {
    id: "03",
    title: "FULL TRAGDYY",
    blurb: "Full tragdyy analloooooo",
    mediaType: "image",
    mediaSrc: "/useless/journal/image3.png",
    alt: "Full tragedy"
  },
  {
    id: "04",
    title: "AGAIN PANI PALLI",
    blurb: "Again pani palli guysssss",
    mediaType: "image",
    mediaSrc: "/useless/journal/image4.png",
    alt: "Again doing it"
  },
  {
    id: "05",
    title: "THE LOOP",
    blurb: "Doing and undoing reset to og — what the heck it's a loop",
    mediaType: "image",
    mediaSrc: "/useless/journal/image5.png",
    alt: "Doing and undoing in a loop"
  },
  {
    id: "06",
    title: "OVAL HEAD",
    blurb: "Just try something new — removing the whole vehicle system and adding an oval for head placements",
    mediaType: "image",
    mediaSrc: "/useless/journal/image6.png",
    alt: "Oval head placement experiment"
  },
  {
    id: "07",
    title: "BUG MATRAM",
    blurb: "Buggode bug matram but ever failed ever win ennalle — lets give it a shot",
    mediaType: "image",
    mediaSrc: "/useless/journal/image7.png",
    alt: "Debugging session"
  },
  {
    id: "08",
    title: "VS CODE ESCAPE",
    blurb: "Just switched to VS Code — the Antigravity sucks so much",
    mediaType: "image",
    mediaSrc: "/useless/journal/image8.png",
    alt: "Switched to VS Code"
  },
  {
    id: "09",
    title: "SUPA BASEEEEE",
    blurb: "Returned to Antigravity and set upping the Supa Baseeeee",
    mediaType: "image",
    mediaSrc: "/useless/journal/image9.png",
    alt: "Supabase setup"
  },
  {
    id: "10",
    title: "JWT CHAOS",
    blurb: "We made JWT — a fun implementation where any person with the same name accesses the same data. Typically useless.",
    mediaType: "image",
    mediaSrc: "/useless/journal/image10.png",
    alt: "JWT implementation"
  },
  {
    id: "11",
    title: "LANDING PAGE",
    blurb: "Built the landing page and a dummy journey — it was a bit of a work",
    mediaType: "image",
    mediaSrc: "/useless/journal/image11.png",
    alt: "Landing page built"
  },
];

export const JournalSection: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const trackRef = useRef<HTMLDivElement>(null);
  const btnPrevRef = useRef<HTMLButtonElement>(null);
  const btnNextRef = useRef<HTMLButtonElement>(null);
  const captionRef = useRef<HTMLDivElement>(null);
  const videoRefs = useRef<(HTMLVideoElement | null)[]>([]);
  
  const [activeIndex, setActiveIndex] = useState(0);
  const [layout, setLayout] = useState({ stepVW: 50, baseOffset: 30, gapVW: 6 });
  const isAnimating = useRef(false);

  // Responsive Layout Setup
  useEffect(() => {
    const updateLayout = () => {
      const isMobile = window.innerWidth <= 768;
      setLayout({
        stepVW: isMobile ? 88 : 50, // 82vw + 6vw gap OR 44vw + 6vw gap
        baseOffset: isMobile ? 9 : 30,
        gapVW: 6
      });
    };
    updateLayout();
    window.addEventListener('resize', updateLayout);
    return () => window.removeEventListener('resize', updateLayout);
  }, []);

  // Magnetic Button Effect
  useEffect(() => {
    const attachMagnetic = (ref: React.RefObject<HTMLButtonElement | null>) => {
      if (!ref.current) return;
      const btn = ref.current;
      const xTo = gsap.quickTo(btn, "x", { duration: 0.4, ease: "power3" });
      const yTo = gsap.quickTo(btn, "y", { duration: 0.4, ease: "power3" });

      const onMove = (e: MouseEvent) => {
        const rect = btn.getBoundingClientRect();
        const x = (e.clientX - (rect.left + rect.width / 2)) * 0.3;
        const y = (e.clientY - (rect.top + rect.height / 2)) * 0.3;
        xTo(x);
        yTo(y);
      };
      const onLeave = () => {
        xTo(0);
        yTo(0);
      };

      btn.addEventListener("mousemove", onMove);
      btn.addEventListener("mouseleave", onLeave);

      return () => {
        btn.removeEventListener("mousemove", onMove);
        btn.removeEventListener("mouseleave", onLeave);
      };
    };

    const cleanupPrev = attachMagnetic(btnPrevRef);
    const cleanupNext = attachMagnetic(btnNextRef);

    return () => {
      if (cleanupPrev) cleanupPrev();
      if (cleanupNext) cleanupNext();
    };
  }, []);

  // Slide, Caption, and Video Animation
  useEffect(() => {
    if (!trackRef.current) return;
    
    const cards = Array.from(trackRef.current.children) as HTMLElement[];
    if (!cards.length) return;

    isAnimating.current = true;

    // Slide track to peek position
    gsap.to(trackRef.current, {
      x: `${layout.baseOffset - (activeIndex * layout.stepVW)}vw`,
      duration: 1.2,
      ease: 'expo.out',
      onComplete: () => {
        isAnimating.current = false;
      }
    });

    // Animate individual cards (peek scale/dim)
    cards.forEach((card, idx) => {
      const isActive = idx === activeIndex;
      gsap.to(card, {
        opacity: isActive ? 1 : 0.45,
        scale: isActive ? 1 : 0.92,
        filter: isActive ? 'grayscale(0)' : 'grayscale(0.6)',
        duration: 1.2,
        ease: 'expo.out'
      });
    });

    // Cross-fade the caption below
    if (captionRef.current) {
      gsap.fromTo(captionRef.current, 
        { opacity: 0, y: 8 },
        { opacity: 1, y: 0, duration: 0.5, delay: 0.3, ease: 'power2.out' }
      );
    }

    // Handle video playback
    videoRefs.current.forEach((video, idx) => {
      if (!video) return;
      if (idx === activeIndex) {
        if (!video.src && journalData[idx].mediaSrc) {
           video.src = journalData[idx].mediaSrc;
        }
        video.play().catch(e => console.warn('Autoplay blocked:', e));
      } else {
        video.pause();
        // Preload adjacent video source lazily
        if (Math.abs(idx - activeIndex) === 1 && !video.src && journalData[idx].mediaSrc) {
           video.src = journalData[idx].mediaSrc;
        }
      }
    });

  }, [activeIndex, layout]);

  // Global Mouse Inertia (Parallax)
  useEffect(() => {
    const section = containerRef.current;
    if (!section || !trackRef.current) return;

    const cards = Array.from(trackRef.current.children) as HTMLElement[];
    const caption = captionRef.current;
    const bgTitle = section.querySelector('.bg-title');

    // Create highly smoothed quickTo setters for inertia (increased duration for heavier inertia)
    const xToCards = gsap.quickTo(cards, "x", { duration: 1.5, ease: "power3.out" });
    const yToCards = gsap.quickTo(cards, "y", { duration: 1.5, ease: "power3.out" });
    
    const xToCaption = caption ? gsap.quickTo(caption, "x", { duration: 2.0, ease: "power3.out" }) : null;
    const yToCaption = caption ? gsap.quickTo(caption, "y", { duration: 2.0, ease: "power3.out" }) : null;
    
    const xToBg = bgTitle ? gsap.quickTo(bgTitle, "x", { duration: 3.5, ease: "power3.out" }) : null;
    const yToBg = bgTitle ? gsap.quickTo(bgTitle, "y", { duration: 3.5, ease: "power3.out" }) : null;

    // Check if device is touch-based. If so, reduce or disable heavy inertia to prevent lag
    const isTouch = window.matchMedia("(hover: none) and (pointer: coarse)").matches;
    if (isTouch) return;

    const onMove = (e: MouseEvent) => {
      // Get mouse position relative to center of screen (-0.5 to 0.5)
      const xRatio = (e.clientX / window.innerWidth) - 0.5;
      const yRatio = (e.clientY / window.innerHeight) - 0.5;

      // Cards shift noticeably with heavy inertia
      xToCards(xRatio * 35);
      yToCards(yRatio * 20);

      // Caption shifts inversely for more depth
      if (xToCaption && yToCaption) {
        xToCaption(xRatio * -25);
        yToCaption(yRatio * -15);
      }

      // Massive BG text shifts heavily and slowly
      if (xToBg && yToBg) {
        xToBg(xRatio * 80);
        yToBg(yRatio * 20);
      }
    };

    section.addEventListener('mousemove', onMove);
    return () => section.removeEventListener('mousemove', onMove);
  }, []);

  // Touch Swipe via Draggable
  useEffect(() => {
    if (!trackRef.current) return;
    
    const maxIndex = journalData.length - 1;

    const draggables = Draggable.create(trackRef.current, {
      type: "x",
      edgeResistance: 0.85,
      lockAxis: true,
      onDragEnd: function() {
        const deltaX = this.endX - this.startX;
        const isMobile = window.innerWidth <= 768;
        // On mobile, a swipe of 50px is often enough to register intent.
        const threshold = isMobile ? Math.min(window.innerWidth * 0.15, 60) : window.innerWidth * 0.1;
        
        let newIndex = activeIndex;
        if (deltaX < -threshold && newIndex < maxIndex) {
          newIndex++;
        } else if (deltaX > threshold && newIndex > 0) {
          newIndex--;
        }
        
        if (newIndex === activeIndex) {
          // Snap back if threshold not met
          gsap.to(trackRef.current, {
            x: `${layout.baseOffset - (activeIndex * layout.stepVW)}vw`,
            duration: 0.6,
            ease: 'expo.out'
          });
        } else {
          setActiveIndex(newIndex);
        }
      }
    });

    return () => {
      draggables[0]?.kill();
    };
  }, [activeIndex, layout]); // Rebind to capture fresh state

  const goNext = () => {
    if (isAnimating.current) return;
    setActiveIndex((prev) => Math.min(prev + 1, journalData.length - 1));
  };

  const goPrev = () => {
    if (isAnimating.current) return;
    setActiveIndex((prev) => Math.max(prev - 1, 0));
  };

  const activeEntry = journalData[activeIndex];

  return (
    <section ref={containerRef} style={{ 
      height: '100vh', 
      backgroundColor: 'var(--color-black)', 
      color: 'var(--color-bg)', 
      display: 'flex', 
      flexDirection: 'column',
      justifyContent: 'center',
      position: 'relative',
      overflow: 'hidden',
      borderTop: '1px solid rgba(243, 241, 234, 0.1)'
    }}>
      {/* Component Scoped CSS */}
      <style>{`
        .journal-card {
          width: 44vw;
          aspect-ratio: 4 / 3;
          border-radius: 1vw;
        }
        .journal-caption {
          left: 30vw;
          width: 44vw;
          bottom: 8vh;
        }
        .journal-nav-buttons {
          bottom: 8vh;
          right: 5vw;
          gap: 0.75vw;
        }
        .journal-nav-btn {
          width: clamp(35px, 3.5vw, 50px);
          height: clamp(35px, 3.5vw, 50px);
        }
        @media (max-width: 768px) {
          .journal-card {
            width: 82vw;
            aspect-ratio: 3 / 4;
            border-radius: 4vw;
          }
          .journal-caption {
            left: 9vw;
            width: 82vw;
            bottom: 12vh;
          }
          .journal-nav-buttons {
            bottom: 4vh;
            right: auto;
            left: 50%;
            transform: translateX(-50%);
            gap: 4vw;
          }
          .journal-nav-btn {
            width: 50px !important;
            height: 50px !important;
          }
        }
      `}</style>

      {/* Massive Background Title */}
      <div className="bg-title" style={{ position: 'absolute', top: '5vh', left: '10vw', zIndex: 0, opacity: 0.1, pointerEvents: 'none' }}>
        <h2 style={{ fontSize: '10vw', textTransform: 'uppercase', letterSpacing: '-0.04em', color: 'var(--color-acid-green)', margin: 0, lineHeight: 0.8, whiteSpace: 'nowrap' }}>
          DEV_JOURNAL
        </h2>
      </div>

      {/* Horizontal Filmstrip Track */}
      <div style={{ width: '100%', zIndex: 1 }}>
        <div ref={trackRef} style={{ display: 'flex', width: 'max-content', gap: `${layout.gapVW}vw`, cursor: 'grab' }}>
          {journalData.map((entry, idx) => (
            <div key={entry.id} className="journal-card" style={{ 
              border: '1px solid var(--border-strong, var(--color-acid-green))', 
              backgroundColor: 'rgba(17,17,17,0.5)',
              transformOrigin: 'center center',
              overflow: 'hidden',
              position: 'relative',
              boxSizing: 'border-box'
            }}>
              {entry.mediaType === 'video' ? (
                <video 
                  ref={(el) => { videoRefs.current[idx] = el; }}
                  poster={entry.poster}
                  muted 
                  loop 
                  playsInline 
                  aria-label={entry.alt}
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              ) : (
                <img 
                  src={entry.mediaSrc} 
                  alt={entry.alt} 
                  loading={idx <= 1 ? "eager" : "lazy"}
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Caption Box (Below Track) */}
      <div className="journal-caption" style={{ 
        position: 'absolute', 
        zIndex: 10,
        pointerEvents: 'none'
      }}>
        <div ref={captionRef}>
          <h3 style={{ fontSize: 'clamp(1.5rem, 4vw, 2.5rem)', margin: '1vh 0', textTransform: 'uppercase', lineHeight: 1, color: 'var(--color-acid-green)' }}>
            {activeEntry.title}
          </h3>
          <p style={{ 
            fontSize: 'clamp(1rem, 2vw, 1.5rem)', 
            lineHeight: 1.4, 
            opacity: 0.9, 
            margin: '0 0 1vh 0',
            display: '-webkit-box',
            WebkitLineClamp: 3,
            WebkitBoxOrient: 'vertical',
            overflow: 'hidden'
          }}>
            {activeEntry.blurb}
          </p>
        </div>
      </div>

      {/* Navigation Buttons */}
      <div className="journal-nav-buttons" style={{ position: 'absolute', display: 'flex', zIndex: 20 }}>
        {/* Left Arrow Button */}
        <button 
          ref={btnPrevRef}
          className="journal-nav-btn"
          onClick={goPrev}
          disabled={activeIndex === 0}
          style={{ 
            borderRadius: '50%', 
            border: '1px solid var(--color-acid-green)', 
            backgroundColor: 'transparent',
            color: 'var(--color-acid-green)',
            cursor: activeIndex === 0 ? 'not-allowed' : 'pointer',
            opacity: activeIndex === 0 ? 0.3 : 1,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            willChange: 'transform, background-color, color',
            transition: 'background-color 0.25s ease, color 0.25s ease'
          }}
          onMouseEnter={(e) => {
            if (activeIndex !== 0) {
              e.currentTarget.style.backgroundColor = 'var(--color-acid-green)';
              e.currentTarget.style.color = 'var(--color-black)';
            }
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.backgroundColor = 'transparent';
            e.currentTarget.style.color = 'var(--color-acid-green)';
          }}
        >
          {/* SVG Chevron Left */}
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="square" strokeLinejoin="miter">
            <polyline points="15 18 9 12 15 6"></polyline>
          </svg>
        </button>

        {/* Right Arrow Button */}
        <button 
          ref={btnNextRef}
          className="journal-nav-btn"
          onClick={goNext}
          disabled={activeIndex === journalData.length - 1}
          style={{ 
            borderRadius: '50%', 
            border: '1px solid var(--color-acid-green)', 
            backgroundColor: 'transparent',
            color: 'var(--color-acid-green)',
            cursor: activeIndex === journalData.length - 1 ? 'not-allowed' : 'pointer',
            opacity: activeIndex === journalData.length - 1 ? 0.3 : 1,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            willChange: 'transform, background-color, color',
            transition: 'background-color 0.25s ease, color 0.25s ease'
          }}
          onMouseEnter={(e) => {
            if (activeIndex !== journalData.length - 1) {
              e.currentTarget.style.backgroundColor = 'var(--color-acid-green)';
              e.currentTarget.style.color = 'var(--color-black)';
            }
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.backgroundColor = 'transparent';
            e.currentTarget.style.color = 'var(--color-acid-green)';
          }}
        >
          {/* SVG Chevron Right */}
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="square" strokeLinejoin="miter">
            <polyline points="9 18 15 12 9 6"></polyline>
          </svg>
        </button>
      </div>
    </section>
  );
};
