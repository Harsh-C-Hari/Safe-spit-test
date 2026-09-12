import React from 'react';

export const SiteShell: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <>
      <div className="texture-overlay" />
      <main className="site-shell">
        {children}
      </main>
    </>
  );
};
