import { useEffect } from "react";
import { useMap } from "react-leaflet";

import L from "leaflet";
import "leaflet/dist/leaflet.css";

// ✅ Dual pulse marker effect
const MarkerPulse = ({ coordinates }: { coordinates: [number, number] }) => {
  const map = useMap();

  useEffect(() => {
    if (!map) return;

    const pulseIcon = L.divIcon({
      className: "custom-pulse",
      html: `
      <div class="pulse-wrapper">
        <div class="pulse-ring outer"></div>
        <div class="pulse-ring inner"></div>
      </div>
    `,
      iconSize: [30, 30],
      iconAnchor: [15, 15],
    });

    const pulseMarker = L.marker(coordinates, { icon: pulseIcon }).addTo(map);

    if (!document.getElementById("pulse-style")) {
      const style = document.createElement("style");
      style.id = "pulse-style";
      style.innerHTML = `
      .pulse-wrapper {
        position: relative;
        width: 30px;
        height: 30px;
      }
      .pulse-ring {
        position: absolute;
        top: 50%;
        left: 50%;
        width: 20px;
        height: 20px;
        border-radius: 50%;
        transform: translate(-50%, -50%);
        background: rgba(27,36,71, 0.6);
        opacity: 0.6;
      }
      .pulse-ring.outer {
        animation: pulseOuter 2s infinite;
      }
      .pulse-ring.inner {
        animation: pulseInner 2s infinite 0.5s;
        background: rgba(27,36,71, 0.8);
      }
      @keyframes pulseOuter {
        0% { transform: translate(-50%, -50%) scale(0.5); opacity: 0.8; }
        70% { transform: translate(-50%, -50%) scale(2.5); opacity: 0.2; }
        100% { transform: translate(-50%, -50%) scale(0.5); opacity: 0.8; }
      }
      @keyframes pulseInner {
        0% { transform: translate(-50%, -50%) scale(0.8); opacity: 0.7; }
        70% { transform: translate(-50%, -50%) scale(1.8); opacity: 0.2; }
        100% { transform: translate(-50%, -50%) scale(0.8); opacity: 0.7; }
      }
    `;
      document.head.appendChild(style);
    }

    return () => {
      pulseMarker.remove();
    };
  }, [map, coordinates]);

  return null;
};

export default MarkerPulse;