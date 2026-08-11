import React, { useState } from "react";
import {
  Card,
  CardContent,
  CardMedia,
  Typography,
  Box,
  Button,
} from "@mui/material";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import FavoriteBorderIcon from "@mui/icons-material/FavoriteBorder";
import FavoriteIcon from "@mui/icons-material/Favorite";
import StarIcon from "@mui/icons-material/Star";
import { useNavigate } from "react-router-dom";
import toast from "react-hot-toast";
import { saveProperty } from "../../services/customerApi";

interface HomePropCardProps {
  id?: number | string;
  image: string;
  name: string;
  location: string;
  price: string;
  tag?: string;
  rating?: number;
  initialSaved?: boolean;
  /** Fired after a successful save/unsave toggle (used by the Saved page to refresh). */
  onToggleSaved?: (id: number | string, saved: boolean) => void;
}

const HomePropCard: React.FC<HomePropCardProps> = ({
  id,
  image,
  name,
  location = "India",
  price,
  tag = "Featured",
  rating = 4.3,
  initialSaved = false,
  onToggleSaved,
}) => {
  const navigate = useNavigate();
  const [saved, setSaved] = useState(initialSaved);
  const [savingFav, setSavingFav] = useState(false);

  const handleToggleSave = async (e: React.MouseEvent) => {
    // The card is usually wrapped in a <Link>; don't navigate on heart click.
    e.preventDefault();
    e.stopPropagation();
    if (id == null || savingFav) return;
    const next = !saved;
    setSaved(next);
    setSavingFav(true);
    try {
      await saveProperty(id);
      onToggleSaved?.(id, next);
    } catch (err: any) {
      setSaved(!next); // revert
      toast.error(
        err?.response?.data?.message ||
          "Please sign in to save properties."
      );
    } finally {
      setSavingFav(false);
    }
  };

  return (
    <Card
      sx={{
        width: "100%",
        borderRadius: "14px",
        border: "1px solid #D9CFB8",
        boxShadow: "0 1px 2px rgba(27,36,71,.04), 0 8px 24px rgba(27,36,71,.06)",
        bgcolor: "#FFFAF0",
        transition: "transform 0.25s ease, box-shadow 0.25s ease",
        cursor: "pointer",
        display: "flex",
        flexDirection: "column",
        gap: "12px",
        overflow: "hidden",
        "&:hover": {
          transform: "translateY(-3px)",
          boxShadow: "0 12px 40px rgba(27,36,71,.12)",
        },
        "&:hover .card-img": { transform: "scale(1.05)" },
      }}
    >
      {/* Image */}
      <Box
        sx={{
          aspectRatio: "1/1",
          position: "relative",
          overflow: "hidden",
          borderRadius: "14px 14px 0 0",
        }}
      >
        <CardMedia
          component="img"
          image={image}
          alt={name}
          className="card-img"
          sx={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
            transition: "transform 0.4s ease",
          }}
        />

        {/* Badge top-left */}
        {tag && (
          <Box
            sx={{
              position: "absolute",
              top: 10,
              left: 10,
              bgcolor: "rgba(255,250,240,0.95)",
              padding: "5px 10px",
              borderRadius: "999px",
              fontSize: 11,
              fontWeight: 600,
              color: "#1B2447",
              display: "flex",
              alignItems: "center",
              gap: "5px",
              backdropFilter: "blur(8px)",
            }}
          >
            <Box
              sx={{ width: 6, height: 6, borderRadius: "50%", bgcolor: "#3F6B4E" }}
            />
            {tag}
          </Box>
        )}

        {/* Fav button top-right */}
        <Box
          onClick={handleToggleSave}
          role="button"
          aria-label={saved ? "Remove from saved" : "Save property"}
          sx={{
            position: "absolute",
            top: 10,
            right: 10,
            width: 32,
            height: 32,
            borderRadius: "50%",
            bgcolor: "rgba(255,250,240,0.85)",
            display: "grid",
            placeItems: "center",
            backdropFilter: "blur(8px)",
            cursor: "pointer",
            transition: "0.2s",
            opacity: savingFav ? 0.6 : 1,
            "&:hover": { bgcolor: "#fff", transform: "scale(1.08)" },
          }}
        >
          {saved ? (
            <FavoriteIcon sx={{ fontSize: 16, color: "#C16345" }} />
          ) : (
            <FavoriteBorderIcon sx={{ fontSize: 16, color: "#3D4670" }} />
          )}
        </Box>
      </Box>

      {/* Content */}
      <CardContent sx={{ padding: "0 12px 12px", display: "flex", flexDirection: "column", gap: "4px" }}>
        {/* Location overline */}
        <Box sx={{ display: "flex", alignItems: "center", gap: "4px" }}>
          <LocationOnIcon sx={{ fontSize: 12, color: "#6B7390" }} />
          <Typography
            sx={{
              fontSize: 11,
              color: "#6B7390",
              letterSpacing: "0.06em",
              textTransform: "uppercase",
              fontWeight: 600,
            }}
          >
            {location}
          </Typography>
        </Box>

        {/* Title */}
        <Typography
          sx={{
            fontFamily: "'Fraunces', serif",
            fontWeight: 500,
            fontSize: 17,
            color: "#1B2447",
            lineHeight: 1.25,
            letterSpacing: "-0.01em",
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap",
          }}
        >
          {name}
        </Typography>

        {/* Meta row */}
        <Box sx={{ display: "flex", alignItems: "center", gap: "6px" }}>
          <StarIcon sx={{ fontSize: 13, color: "#C16345", fill: "#C16345" }} />
          <Typography sx={{ fontSize: 13, color: "#1B2447", fontWeight: 500 }}>
            {rating}
          </Typography>
        </Box>

        {/* Footer row — price + button */}
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            mt: "4px",
          }}
        >
          <Box>
            <Typography
              component="span"
              sx={{
                fontFamily: "'Fraunces', serif",
                fontSize: 17,
                fontWeight: 600,
                color: "#1B2447",
              }}
            >
              {price}
            </Typography>
            <Typography
              component="span"
              sx={{ fontSize: 12, color: "#6B7390", ml: "4px" }}
            >
              / night
            </Typography>
          </Box>

          <Button
            variant="contained"
            size="small"
            sx={{
              bgcolor: "#1B2447",
              textTransform: "none",
              fontWeight: 600,
              borderRadius: "10px",
              fontSize: 12,
              px: 1.5,
              py: 0.6,
              "&:hover": { bgcolor: "#2A356B" },
            }}
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              navigate(id != null ? `/property/detail/${id}` : "/property/list");
            }}
          >
            Book
          </Button>
        </Box>
      </CardContent>
    </Card>
  );
};

export default HomePropCard;
