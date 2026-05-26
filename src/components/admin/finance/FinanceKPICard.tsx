import { Box, Typography, Stack } from "@mui/material";
import type { LucideIcon } from "lucide-react";
import { ArrowDownRight, ArrowUpRight } from "lucide-react";

interface FinanceKPICardProps {
  label: string;
  value: number;
  growth?: number;
  icon: LucideIcon;
  color?: string;
  helperText?: string;
}

const FinanceKPICard = ({
  label,
  value,
  growth,
  icon: Icon,
  color = "#ffffff",
  helperText,
}: FinanceKPICardProps) => {
  const isPositiveGrowth = (growth ?? 0) >= 0;
  const formattedValue = new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(value);

  return (
    <Box
      sx={{
        position: "relative",
        bgcolor: "rgba(255,255,255,0.14)",
        border: "1px solid rgba(255,255,255,0.26)",
        backdropFilter: "blur(14px)",
        borderRadius: "1rem",
        p: 2.25,
        minWidth: 0,
        overflow: "hidden",
        "&::after": {
          content: '""',
          position: "absolute",
          inset: 0,
          background:
            "radial-gradient(circle at top right, rgba(255,255,255,0.22), transparent 58%)",
          pointerEvents: "none",
        },
      }}
    >
      <Stack direction="row" alignItems="flex-start" justifyContent="space-between" spacing={1.5}>
        <Box
          sx={{
            width: 42,
            height: 42,
            borderRadius: "0.85rem",
            bgcolor: "rgba(255,255,255,0.22)",
            border: "1px solid rgba(255,255,255,0.25)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexShrink: 0,
          }}
        >
          <Icon size={20} color={color} />
        </Box>

        {growth !== undefined && (
          <Stack
            direction="row"
            alignItems="center"
            spacing={0.4}
            sx={{
              px: 1,
              py: 0.45,
              borderRadius: "999px",
              bgcolor: isPositiveGrowth
                ? "rgba(134,239,172,0.18)"
                : "rgba(252,165,165,0.2)",
              border: isPositiveGrowth
                ? "1px solid rgba(134,239,172,0.35)"
                : "1px solid rgba(252,165,165,0.35)",
            }}
          >
            {isPositiveGrowth ? (
              <ArrowUpRight size={13} color="#bbf7d0" />
            ) : (
              <ArrowDownRight size={13} color="#fecaca" />
            )}
            <Typography
              variant="caption"
              sx={{
                color: isPositiveGrowth ? "#dcfce7" : "#fee2e2",
                fontWeight: 700,
                lineHeight: 1,
              }}
            >
              {isPositiveGrowth ? "+" : ""}
              {growth.toFixed(1)}%
            </Typography>
          </Stack>
        )}
      </Stack>

      <Box sx={{ minWidth: 0, pt: 1.75 }}>
        <Typography
          variant="caption"
          sx={{
            display: "block",
            mb: 0.7,
            color: "rgba(255,255,255,0.8)",
            fontWeight: 600,
            letterSpacing: 0.2,
          }}
        >
          {label}
        </Typography>
        <Stack direction="row" alignItems="center" spacing={1}>
          <Typography
            variant="h5"
            fontWeight={700}
            sx={{ color: "#fff", lineHeight: 1.1, letterSpacing: -0.3 }}
          >
            {formattedValue}
          </Typography>
        </Stack>

        {helperText && (
          <Typography
            variant="caption"
            sx={{ mt: 0.75, color: "rgba(255,255,255,0.74)", display: "block" }}
          >
            {helperText}
          </Typography>
        )}
      </Box>
    </Box>
  );
};

export default FinanceKPICard;
