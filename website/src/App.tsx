
import { SiteShell } from './components/SiteShell';
import { PersistentNav } from './components/PersistentNav';
import { HeroSequence } from './components/HeroSequence';
import { Section02 } from './components/Section02';
import { Section03 } from './components/Section03';
import { Section04 } from './components/Section04';
import { Section05 } from './components/Section05';
import { Section08 } from './components/Section08';
import { JournalSection } from './components/JournalSection';
import { Section09 } from './components/Section09';

function App() {
  return (
    <SiteShell>
      <PersistentNav />
      
      <HeroSequence />
      
      <Section02 />
      
      <Section03 />
      <Section04 />
      <Section05 />

      <Section08 />
      <JournalSection />
      <Section09 />

    </SiteShell>
  );
}

export default App;
