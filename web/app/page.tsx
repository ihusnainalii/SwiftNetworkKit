import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { PipelineSimulator } from "@/components/PipelineSimulator";
import { CodePlayground } from "@/components/CodePlayground";
import { ConcurrencyVisualizer } from "@/components/ConcurrencyVisualizer";
import { LibraryComparison } from "@/components/LibraryComparison";
import { BentoFeatures } from "@/components/BentoFeatures";
import { RoadmapSection } from "@/components/RoadmapSection";
import { MetricsDashboard } from "@/components/MetricsDashboard";
import { ApiExplorer } from "@/components/ApiExplorer";
import { SpmInstall } from "@/components/SpmInstall";
import { Footer } from "@/components/Footer";

export default function Home() {
  return (
    <div className="relative min-h-screen">
      {/* Antigravity Spatial Canvas */}
      <div className="antigravity-bg">
        <div className="mesh-grid"></div>
        <div className="orb orb-1"></div>
        <div className="orb orb-2"></div>
        <div className="orb orb-3"></div>
      </div>

      <Navbar />

      <main className="relative z-10 pt-20">
        <Hero />
        <PipelineSimulator />
        <CodePlayground />
        <ConcurrencyVisualizer />
        <LibraryComparison />
        <BentoFeatures />
        <RoadmapSection />
        <MetricsDashboard />
        <ApiExplorer />
        <SpmInstall />
      </main>

      <Footer />
    </div>
  );
}
