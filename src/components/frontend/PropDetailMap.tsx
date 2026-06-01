import React, { useEffect } from "react";
import { Box } from "@mui/material";
import { MapContainer, TileLayer, Marker, useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

// ✅ Custom red map marker
const markerIcon = new L.Icon({
  iconUrl:
    "https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-red.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [32, 48],
  iconAnchor: [16, 48],
});

// ✅ Pulse effect dynamically rendered at given lat/lng
const MarkerPulse = ({ coordinates }: { coordinates: [number, number] }) => {
  const map = useMap();

  useEffect(() => {
    if (!map) return;

    // Create a custom div icon with two rings
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

    // Add pulse marker to the map
    const pulseMarker = L.marker(coordinates, { icon: pulseIcon }).addTo(map);

    // Inject styles once
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

interface ResponsiveMapProps {
  coordinates: [number, number];
}

const PropDetailMap: React.FC<ResponsiveMapProps> = ({ coordinates }) => {
  return (
    <Box
      sx={{
        width: "100%",
        height: { xs: 250, sm: 320, md: 400 },
        borderRadius: 3,
        overflow: "hidden",
        position: "relative",
        boxShadow: "0 8px 25px rgba(0,0,0,0.15)",
        "& .leaflet-container": {
          width: "100%",
          height: "100%",
        },
        transition: "all 0.4s ease",
        "&:hover": {
          boxShadow: "0 10px 30px rgba(27,36,71, 0.3)",
          transform: "scale(1.01)",
        },
      }}
    >
      <MapContainer
        center={coordinates}
        zoom={13}
        scrollWheelZoom={false}
        style={{ width: "100%", height: "100%", zIndex: 1 }}
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution='&copy; <a href="http://carto.com/attributions">CARTO</a>'
        />

        {/* ✅ Red marker for property */}
        <Marker position={coordinates} icon={markerIcon} />

        {/* ✅ Animated pulse effect */}
        <MarkerPulse coordinates={coordinates} />
      </MapContainer>

      {/* ✅ Overlay gradient */}
      <Box
        sx={{
          position: "absolute",
          inset: 0,
          background:
            "linear-gradient(180deg, rgba(0,0,0,0.05) 0%, rgba(0,0,0,0.25) 100%)",
          pointerEvents: "none",
          zIndex: 2,
        }}
      />
    </Box>
  );
};

export default PropDetailMap;
