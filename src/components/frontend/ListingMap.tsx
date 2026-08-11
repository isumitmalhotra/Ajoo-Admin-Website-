import { useEffect, useMemo, useRef } from "react";
import { Box } from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import RemoveIcon from "@mui/icons-material/Remove";
import CheckIcon from "@mui/icons-material/Check";
import {
  MapContainer,
  TileLayer,
  Marker,
  useMap,
  useMapEvents,
} from "react-leaflet";
import L, { LatLngBounds, LatLngLiteral } from "leaflet";
import "leaflet/dist/leaflet.css";

export type MapProperty = {
  id: number | string;
  name: string;
  price: number; // numeric INR — formatted on the pin
  lat: number;
  lng: number;
  featured?: boolean;
};

interface ListingMapProps {
  properties: MapProperty[];
  hoveredId?: number | string | null;
  onHoverPin?: (id: number | string | null) => void;
  onClickPin?: (id: number | string) => void;
  searchOnMove: boolean;
  onToggleSearchOnMove: () => void;
  onMoveEnd?: (bounds: LatLngBounds) => void;
  initialCenter?: LatLngLiteral;
  initialZoom?: number;
}

// ── Helpers ──────────────────────────────────────────────────────────────
const formatInrCompact = (n: number): string => {
  if (n >= 100000) {
    const lakhs = n / 100000;
    return `₹${lakhs % 1 === 0 ? lakhs.toFixed(0) : lakhs.toFixed(1)}L`;
  }
  if (n >= 1000) {
    const thousands = n / 1000;
    return `₹${thousands % 1 === 0 ? thousands.toFixed(0) : thousands.toFixed(1)}K`;
  }
  return `₹${n}`;
};

const buildPinIcon = (
  price: number,
  opts: { featured?: boolean; hovered?: boolean }
): L.DivIcon => {
  const { featured, hovered } = opts;
  const bg = featured || hovered ? "#1B2447" : "#FFFAF0";
  const color = featured || hovered ? "#FFFAF0" : "#1B2447";
  const borderColor = featured || hovered ? "#1B2447" : "#D9CFB8";
  const shadow =
    featured || hovered
      ? "0 6px 16px rgba(27,36,71,.28)"
      : "0 1px 2px rgba(27,36,71,.06), 0 6px 16px rgba(27,36,71,.12)";
  const scale = hovered ? 1.08 : 1;

  const label = formatInrCompact(price);

  // Size the wrapper to actually fit the label. Heuristic: ~8.5px per char
  // (Inter 600 at 13px) + 28px horizontal padding budget. Floor at 60px.
  const width = Math.max(60, Math.round(label.length * 8.5 + 28));
  const height = 30;

  return L.divIcon({
    className: "ajoo-price-pin",
    html: `
      <div style="
        width: 100%;
        height: 100%;
        background: ${bg};
        color: ${color};
        border: 1px solid ${borderColor};
        border-radius: 999px;
        font-family: 'Inter', system-ui, sans-serif;
        font-weight: 600;
        font-size: 13px;
        line-height: 1;
        white-space: nowrap;
        box-shadow: ${shadow};
        transform: scale(${scale});
        transform-origin: center bottom;
        transition: transform .15s ease, background .15s ease, color .15s ease;
        cursor: pointer;
        letter-spacing: -0.01em;
        display: flex;
        align-items: center;
        justify-content: center;
        box-sizing: border-box;
        padding: 0 12px;
      ">${label}</div>
    `,
    // Wrapper sized to the pill so Leaflet positions it as one unit;
    // bottom-center anchored so the pill sits ON the lat/lng point.
    iconSize: [width, height],
    iconAnchor: [width / 2, height],
  });
};

// ── Inner helpers that need the map instance ─────────────────────────────
const MapEventHandler: React.FC<{
  onMoveEnd?: (bounds: LatLngBounds) => void;
  searchOnMove: boolean;
}> = ({ onMoveEnd, searchOnMove }) => {
  const map = useMapEvents({
    moveend: () => {
      if (searchOnMove && onMoveEnd) onMoveEnd(map.getBounds());
    },
    zoomend: () => {
      if (searchOnMove && onMoveEnd) onMoveEnd(map.getBounds());
    },
  });
  return null;
};

const MapImperativeHandle: React.FC<{
  innerRef: React.MutableRefObject<L.Map | null>;
}> = ({ innerRef }) => {
  const map = useMap();
  useEffect(() => {
    innerRef.current = map;
  }, [map, innerRef]);
  return null;
};

// Recenters the map when the visitor's location resolves, and fixes Leaflet's
// occasional zoomed-out (world) render when its container sizes after mount.
const RecenterOnLocation: React.FC<{ center: LatLngLiteral; zoom: number }> = ({
  center,
  zoom,
}) => {
  const map = useMap();
  const applied = useRef<string>("");
  useEffect(() => {
    const key = `${center.lat.toFixed(4)},${center.lng.toFixed(4)}`;
    if (key !== applied.current) {
      applied.current = key;
      map.setView(center, zoom);
    }
    const t = setTimeout(() => map.invalidateSize(), 250);
    return () => clearTimeout(t);
  }, [center.lat, center.lng, zoom, map]);
  return null;
};

// ── Main component ───────────────────────────────────────────────────────
const ListingMap: React.FC<ListingMapProps> = ({
  properties,
  hoveredId = null,
  onHoverPin,
  onClickPin,
  searchOnMove,
  onToggleSearchOnMove,
  onMoveEnd,
  initialCenter = { lat: 15.4909, lng: 73.8278 }, // Goa default
  initialZoom = 11,
}) => {
  const mapRef = useRef<L.Map | null>(null);

  // Center map on property cluster (first time data loads) if bounds make sense
  const initialFitBounds = useMemo(() => {
    if (properties.length === 0) return null;
    const lats = properties.map((p) => p.lat);
    const lngs = properties.map((p) => p.lng);
    const minLat = Math.min(...lats);
    const maxLat = Math.max(...lats);
    const minLng = Math.min(...lngs);
    const maxLng = Math.max(...lngs);
    return L.latLngBounds([minLat, minLng], [maxLat, maxLng]);
  }, [properties]);

  useEffect(() => {
    if (mapRef.current && initialFitBounds) {
      mapRef.current.fitBounds(initialFitBounds, { padding: [40, 40] });
    }
    // Only fit on initial mount + when property set changes drastically.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [properties.length]);

  return (
    <Box
      sx={{
        position: "relative",
        width: "100%",
        height: "100%",
        borderRadius: "18px",
        overflow: "hidden",
        border: "1px solid #D9CFB8",
        boxShadow:
          "0 1px 2px rgba(27,36,71,.04), 0 12px 40px rgba(27,36,71,.12)",
        bgcolor: "#EFE7D6",
      }}
    >
      <MapContainer
        center={initialCenter}
        zoom={initialZoom}
        scrollWheelZoom
        zoomControl={false}
        style={{ width: "100%", height: "100%" }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <MapImperativeHandle innerRef={mapRef} />
        <RecenterOnLocation center={initialCenter} zoom={initialZoom} />
        <MapEventHandler
          onMoveEnd={onMoveEnd}
          searchOnMove={searchOnMove}
        />

        {properties.map((p) => {
          const isHovered = hoveredId === p.id;
          return (
            <Marker
              key={p.id}
              position={[p.lat, p.lng]}
              icon={buildPinIcon(p.price, {
                featured: p.featured,
                hovered: isHovered,
              })}
              eventHandlers={{
                click: () => onClickPin?.(p.id),
                mouseover: () => onHoverPin?.(p.id),
                mouseout: () => onHoverPin?.(null),
              }}
              zIndexOffset={isHovered ? 1000 : p.featured ? 500 : 0}
            />
          );
        })}
      </MapContainer>

      {/* ── "Search as I move the map" toggle (top-left) ── */}
      <Box
        onClick={onToggleSearchOnMove}
        sx={{
          position: "absolute",
          top: 16,
          left: 16,
          zIndex: 1000,
          display: "inline-flex",
          alignItems: "center",
          gap: "8px",
          padding: "8px 14px",
          borderRadius: "999px",
          bgcolor: "#FFFAF0",
          border: "1px solid #D9CFB8",
          boxShadow:
            "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
          fontFamily: "'Inter', system-ui, sans-serif",
          fontSize: 13,
          fontWeight: 500,
          color: "#1B2447",
          cursor: "pointer",
          userSelect: "none",
          transition: "0.2s",
          "&:hover": { borderColor: "#1B2447" },
        }}
      >
        <Box
          sx={{
            width: 16,
            height: 16,
            borderRadius: "4px",
            border: "1.5px solid",
            borderColor: searchOnMove ? "#1B2447" : "#6B7390",
            bgcolor: searchOnMove ? "#1B2447" : "transparent",
            display: "grid",
            placeItems: "center",
            transition: "0.15s",
          }}
        >
          {searchOnMove && (
            <CheckIcon sx={{ color: "#FFFAF0", fontSize: 12 }} />
          )}
        </Box>
        Search as I move the map
      </Box>

      {/* ── Custom +/- zoom controls (top-right) ── */}
      <Box
        sx={{
          position: "absolute",
          top: 16,
          right: 16,
          zIndex: 1000,
          display: "flex",
          flexDirection: "column",
          bgcolor: "#FFFAF0",
          border: "1px solid #D9CFB8",
          borderRadius: "10px",
          overflow: "hidden",
          boxShadow:
            "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
        }}
      >
        <Box
          onClick={() => mapRef.current?.zoomIn()}
          sx={{
            width: 38,
            height: 38,
            display: "grid",
            placeItems: "center",
            cursor: "pointer",
            color: "#1B2447",
            borderBottom: "1px solid #D9CFB8",
            transition: "0.15s",
            "&:hover": { bgcolor: "#EFE7D6" },
          }}
          aria-label="Zoom in"
        >
          <AddIcon sx={{ fontSize: 20 }} />
        </Box>
        <Box
          onClick={() => mapRef.current?.zoomOut()}
          sx={{
            width: 38,
            height: 38,
            display: "grid",
            placeItems: "center",
            cursor: "pointer",
            color: "#1B2447",
            transition: "0.15s",
            "&:hover": { bgcolor: "#EFE7D6" },
          }}
          aria-label="Zoom out"
        >
          <RemoveIcon sx={{ fontSize: 20 }} />
        </Box>
      </Box>
    </Box>
  );
};

export default ListingMap;
