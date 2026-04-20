import { useState } from "react";
import { IconButton, Tooltip, CircularProgress } from "@mui/material";
import { Download } from "lucide-react";

interface ExportButtonProps {
  /** Column headers for the CSV */
  headers: string[];
  /** Rows of data — each row is an array of cell values matching headers order */
  rows: (string | number)[][];
  /** File name for the downloaded CSV (without extension) */
  filename?: string;
}

const ExportButton = ({ headers, rows, filename }: ExportButtonProps) => {
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
    <Tooltip title="Export CSV">
      <IconButton
        onClick={handleExport}
        disabled={exporting || rows.length === 0}
        sx={{
          border: "1px solid #e5e7eb",
          borderRadius: "0.5rem",
          p: 1,
          "&:hover": { borderColor: "#881f9b", color: "#881f9b" },
        }}
      >
        {exporting ? <CircularProgress size={16} /> : <Download size={16} />}
      </IconButton>
    </Tooltip>
  );
};

export default ExportButton;
