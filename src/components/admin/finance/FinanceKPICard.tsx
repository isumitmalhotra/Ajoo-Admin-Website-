import { Box, Typography, Stack } from "@mui/material";
import type { LucideIcon } from "lucide-react";
import { TrendingUp, TrendingDown } from "lucide-react";

interface FinanceKPICardProps {
  label: string;
  value: number;
  growth?: number;
  icon: LucideIcon;
  color?: string;
}

const FinanceKPICard = ({
  label,
  value,
  growth,
  icon: Icon,
}: FinanceKPICardProps) => {
  const isPositiveGrowth = (growth ?? 0) >= 0;

  return (
    <Box
      sx={{
        bgcolor: "rgba(255,255,255,0.15)",
        backdropFilter: "blur(10px)",
        borderRadius: "0.75rem",
        p: 2.5,
        display: "flex",
        alignItems: "center",
        gap: 2,
        minWidth: 0,
      }}
    >
      <Box
        sx={{
          width: 48,
          height: 48,
          borderRadius: "0.75rem",
          bgcolor: "rgba(255,255,255,0.2)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexShrink: 0,
        }}
      >
        <Icon size={24} color="#fff" />
      </Box>

      <Box sx={{ minWidth: 0, flex: 1 }}>
        <Typography
          variant="caption"
          sx={{ color: "rgba(255,255,255,0.8)", fontWeight: 500 }}
        >
          {label}
        </Typography>
        <Stack direction="row" alignItems="baseline" spacing={1}>
          <Typography
            variant="h5"
            fontWeight={700}
            sx={{ color: "#fff", lineHeight: 1.2 }}
          >
            ₹{value.toLocaleString("en-IN")}
          </Typography>
          {growth !== undefined && (
            <Stack direction="row" alignItems="center" spacing={0.3}>
              {isPositiveGrowth ? (
                <TrendingUp size={14} color="#86efac" />
              ) : (
                <TrendingDown size={14} color="#fca5a5" />
              )}
              <Typography
                variant="caption"
                sx={{
                  color: isPositiveGrowth
                    ? "#86efac"
                    : "#fca5a5",
                  fontWeight: 600,
                }}
              >
                {isPositiveGrowth ? "+" : ""}
                {growth.toFixed(1)}%
              </Typography>
            </Stack>
          )}
        </Stack>
      </Box>
    </Box>
  );
};

export default FinanceKPICard;
