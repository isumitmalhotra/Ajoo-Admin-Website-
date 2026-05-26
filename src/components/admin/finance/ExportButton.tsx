import { useState } from "react";
import { Button, Tooltip, CircularProgress } from "@mui/material";
import { Download } from "lucide-react";

interface ExportButtonProps {
  /** Column headers for the CSV */
  headers: string[];
  /** Rows of data — each row is an array of cell values matching headers order */
  rows: (string | number)[][];
  /** File name for the downloaded CSV (without extension) */
  filename?: string;
  /** Optional button text */
  label?: string;
}

const ExportButton = ({
  headers,
  rows,
  filename,
  label = "Export CSV",
}: ExportButtonProps) => {
  const [exporting, setExporting] = useState(false);

  const handleExport = () => {
    if (rows.length === 0) return;
    setExporting(true);

    try {
      const escapeCell = (val: string | number): string => {
        const str = String(val);
        if (str.includes(",") || str.includes('"') || str.includes("\n")) {
          return `"${str.replace(/"/g, '""')}"`;
        }
        return str;
      };

      const csvContent = [
        headers.map(escapeCell).join(","),
        ...rows.map((row) => row.map(escapeCell).join(",")),
      ].join("\n");

      const blob = new Blob(["\uFEFF" + csvContent], {
        type: "text/csv;charset=utf-8;",
      });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute(
        "download",
        `${filename ?? "export"}-${new Date().toISOString().slice(0, 10)}.csv`
      );
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } finally {
      setExporting(false);
    }
  };

  return (
    <Tooltip title="Download as CSV">
      <span>
        <Button
          variant="outlined"
          size="small"
          startIcon={
            exporting ? (
              <CircularProgress size={14} sx={{ color: "#881f9b" }} />
            ) : (
              <Download size={14} />
            )
          }
          onClick={handleExport}
          disabled={exporting || rows.length === 0}
          sx={{
            borderColor: "#d1d5db",
            color: "#374151",
            borderRadius: "0.65rem",
            px: 1.4,
            py: 0.6,
            textTransform: "none",
            fontWeight: 600,
            fontSize: "0.78rem",
            whiteSpace: "nowrap",
            "&:hover": {
              borderColor: "#881f9b",
              color: "#881f9b",
              bgcolor: "#faf5ff",
            },
            "&.Mui-disabled": {
              borderColor: "#e5e7eb",
            },
          }}
        >
          {label}
        </Button>
      </span>
    </Tooltip>
  );
};

export default ExportButton;
