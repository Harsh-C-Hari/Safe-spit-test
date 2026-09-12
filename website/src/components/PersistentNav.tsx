import React from 'react';

export const PersistentNav: React.FC = () => {
  const handleScrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <nav className="persistent-nav">
      <div
        className="nav-item nav-top-left"
        onClick={handleScrollToTop}
        style={{ cursor: 'pointer' }}
      >
        SAFE//SPIT
      </div>
    </nav>
  );
};
