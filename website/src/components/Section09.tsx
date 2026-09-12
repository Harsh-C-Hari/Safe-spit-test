import React from 'react';

export const Section09: React.FC = () => {
  return (
    <section style={{ height: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', backgroundColor: 'var(--color-bg)', color: 'var(--color-black)', borderTop: 'var(--border-strong)' }}>
      <h2 style={{ fontSize: '10vw', textTransform: 'uppercase', margin: '0 0 4vh 0', letterSpacing: '-0.03em', textAlign: 'center', lineHeight: 1 }}>
        DOWNLOAD<br />SAFE//SPIT
      </h2>
      <a href="https://drive.google.com/file/d/1WO7HH3zFftCj0opHzD58cGorqBcI-_tF/view?usp=sharing" target="_blank" rel="noopener noreferrer" style={{ padding: '2vh 4vw', backgroundColor: 'var(--color-black)', color: 'var(--color-acid-green)', textDecoration: 'none', fontSize: '2vw', fontFamily: 'var(--font-technical)', textTransform: 'uppercase', borderRadius: '4px', border: '1px solid var(--color-acid-green)', transition: 'background-color 0.3s' }} onMouseEnter={(e) => { e.currentTarget.style.backgroundColor = 'var(--color-acid-green)'; e.currentTarget.style.color = 'var(--color-black)'; }} onMouseLeave={(e) => { e.currentTarget.style.backgroundColor = 'var(--color-black)'; e.currentTarget.style.color = 'var(--color-acid-green)'; }}>
        GET THE EXPERIMENT
      </a>
      <div style={{ marginTop: '5vh', fontFamily: 'var(--font-technical)', fontSize: '1vw', opacity: 0.5, letterSpacing: '0.1em' }}>
        AVAILABLE ON ANDROID
      </div>
    </section>
  );
};
