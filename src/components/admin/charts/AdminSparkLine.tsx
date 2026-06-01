import * as React from "react";
import Stack from "@mui/material/Stack";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import { SparkLineChart } from "@mui/x-charts/SparkLineChart";

const settings = {
  valueFormatter: (value: number | null) => (value !== null ? `${value}%` : ""),
  height: 120,
  showTooltip: true,
  showHighlight: true,
} as const;

const smallValues = [0, 2, 3, 4, 6, 8, 7, 9, 15, 6, 8, 7, 12];
const largeValues = [60, 65, 66, 68, 87, 82, 83, 89, 92, 75, 76, 77, 91];

export default function CustomYAxis() {
  // type HighlightItemData = {
  //   seriesId: string;
  //   dataIndex: number;
  //   x: number;
  //   y: number;
  // };
  const [selectedIndex, setSelectedIndex] = React.useState<number | null>(null);
  const [selectedChart, setSelectedChart] = React.useState<
    "small" | "large" | null
  >(null);
  const handleHighlightChange = (
    index: number | null,
    chartType: "small" | "large"
  ) => {
    setSelectedIndex(index);
    setSelectedChart(chartType);
  };

  return (
    <Stack
      sx={{
        width: "100%",
        maxWidth: 720,
        margin: "auto",
        fontFamily: "'Inter', system-ui, sans-serif",
        userSelect: "none",
      }}
      spacing={4}
    >
      <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>
        Without fixed y-range
      </Typography>
      <Stack direction="row" spacing={3} sx={{ mb: 3 }}>
        <Box sx={{ flex: 1, cursor: "pointer" }}>
          <SparkLineChart
            data={smallValues}
            color="#e53935"
            {...settings}
            onHighlightChange={(highlight) =>
              handleHighlightChange(highlight?.dataIndex ?? null, "small")
            }
          />
          {selectedChart === "small" && selectedIndex !== null && (
            <Typography
              variant="subtitle2"
              sx={{ mt: 1, textAlign: "center", color: "#e53935" }}
            >
              Selected Value: {smallValues[selectedIndex]}%
            </Typography>
          )}
        </Box>
        <Box sx={{ flex: 1, cursor: "pointer" }}>
          <SparkLineChart
            data={largeValues}
            color="#1e88e5"
            {...settings}
            onHighlightChange={(highlight) =>
              handleHighlightChange(highlight?.dataIndex ?? null, "small")
            }
          />
          {selectedChart === "large" && selectedIndex !== null && (
            <Typography
              variant="subtitle2"
              sx={{ mt: 1, textAlign: "center", color: "#1e88e5" }}
            >
              Selected Value: {largeValues[selectedIndex]}%
            </Typography>
          )}
        </Box>
      </Stack>

      <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>
        With y-range fixed to [0, 100]
      </Typography>
      <Stack direction="row" spacing={3}>
        <Box sx={{ flex: 1, cursor: "pointer" }}>
          <SparkLineChart
            data={smallValues}
            yAxis={{ min: 0, max: 100 }}
            color="#e53935"
            {...settings}
            onHighlightChange={(highlight) =>
              handleHighlightChange(highlight?.dataIndex ?? null, "small")
            }
          />
          {selectedChart === "small" && selectedIndex !== null && (
            <Typography
              variant="subtitle2"
              sx={{ mt: 1, textAlign: "center", color: "#e53935" }}
            >
              Selected Value: {smallValues[selectedIndex]}%
            </Typography>
          )}
        </Box>
        <Box sx={{ flex: 1, cursor: "pointer" }}>
          <SparkLineChart
            data={largeValues}
            yAxis={{ min: 0, max: 100 }}
            color="#1e88e5"
            {...settings}
            onHighlightChange={(highlight) =>
              handleHighlightChange(highlight?.dataIndex ?? null, "small")
            }
          />
          {selectedChart === "large" && selectedIndex !== null && (
            <Typography
              variant="subtitle2"
              sx={{ mt: 1, textAlign: "center", color: "#1e88e5" }}
            >
              Selected Value: {largeValues[selectedIndex]}%
            </Typography>
          )}
        </Box>
      </Stack>
    </Stack>
  );
}
