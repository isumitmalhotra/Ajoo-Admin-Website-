import { Box, Typography } from "@mui/material";
import WifiIcon from "@mui/icons-material/Wifi";
import PoolIcon from "@mui/icons-material/Pool";
import AcUnitIcon from "@mui/icons-material/AcUnit";
import KitchenIcon from "@mui/icons-material/Kitchen";
import LocalParkingIcon from "@mui/icons-material/LocalParking";
import TvIcon from "@mui/icons-material/Tv";
import BalconyIcon from "@mui/icons-material/Balcony";
import LocalLaundryServiceIcon from "@mui/icons-material/LocalLaundryService";
import RoomServiceIcon from "@mui/icons-material/RoomService";
import HotTubIcon from "@mui/icons-material/HotTub";
import FitnessCenterIcon from "@mui/icons-material/FitnessCenter";
import PetsIcon from "@mui/icons-material/Pets";
import LocalFireDepartmentIcon from "@mui/icons-material/LocalFireDepartment";
import CheckCircleOutlineIcon from "@mui/icons-material/CheckCircleOutline";

const ICON_MAP: Record<string, typeof WifiIcon> = {
  wifi: WifiIcon,
  "wi-fi": WifiIcon,
  internet: WifiIcon,
  pool: PoolIcon,
  "swimming pool": PoolIcon,
  ac: AcUnitIcon,
  "air conditioning": AcUnitIcon,
  kitchen: KitchenIcon,
  parking: LocalParkingIcon,
  "free parking": LocalParkingIcon,
  tv: TvIcon,
  television: TvIcon,
  balcony: BalconyIcon,
  laundry: LocalLaundryServiceIcon,
  washer: LocalLaundryServiceIcon,
  "room service": RoomServiceIcon,
  jacuzzi: HotTubIcon,
  "hot tub": HotTubIcon,
  gym: FitnessCenterIcon,
  fitness: FitnessCenterIcon,
  "pet friendly": PetsIcon,
  pets: PetsIcon,
  fireplace: LocalFireDepartmentIcon,
  heating: LocalFireDepartmentIcon,
};

const DEFAULT_AMENITIES = [
  "Wi-Fi",
  "Pool",
  "Air conditioning",
  "Kitchen",
  "Free parking",
  "TV",
  "Balcony",
  "Laundry",
];

interface AmenitiesGridProps {
  amenities?: string[];
}

const iconFor = (label: string) => {
  const key = label.toLowerCase().trim();
  return ICON_MAP[key] || CheckCircleOutlineIcon;
};

export default function AmenitiesGrid({ amenities }: AmenitiesGridProps) {
  const items = amenities && amenities.length > 0 ? amenities : DEFAULT_AMENITIES;

  return (
    <Box
      sx={{
        bgcolor: "#FFFAF0",
        padding: { xs: "20px", sm: "24px" },
        border: "1px solid #D9CFB8",
        borderRadius: "14px",
        boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
        maxWidth: { md: "65%" },
      }}
    >
      <Typography
        sx={{
          fontFamily: "'Fraunces', serif",
          fontSize: { xs: 20, sm: 24 },
          fontWeight: 400,
          letterSpacing: "-0.02em",
          color: "#1B2447",
          mb: "20px",
        }}
      >
        What this place offers
      </Typography>

      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: {
            xs: "1fr 1fr",
            sm: "1fr 1fr",
            md: "1fr 1fr 1fr 1fr",
          },
          gap: "16px",
        }}
      >
        {items.slice(0, 8).map((label, idx) => {
          const Icon = iconFor(label);
          return (
            <Box
              key={idx}
              sx={{
                display: "flex",
                alignItems: "center",
                gap: "12px",
                padding: "10px 12px",
                borderRadius: "10px",
                transition: "background 0.2s ease",
                "&:hover": { bgcolor: "rgba(27,36,71,0.03)" },
              }}
            >
              <Box
                sx={{
                  width: 36,
                  height: 36,
                  borderRadius: "10px",
                  bgcolor: "rgba(27,36,71,0.06)",
                  display: "grid",
                  placeItems: "center",
                  flexShrink: 0,
                }}
              >
                <Icon sx={{ fontSize: 18, color: "#1B2447" }} />
              </Box>
              <Typography
                sx={{
                  fontSize: 14,
                  fontWeight: 500,
                  color: "#1B2447",
                  lineHeight: 1.3,
                }}
              >
                {label}
              </Typography>
            </Box>
          );
        })}
      </Box>
    </Box>
  );
}
