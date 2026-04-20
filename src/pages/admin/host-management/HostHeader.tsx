import {
  Box,
  Button,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useEffect, useState } from "react";
import { FilterList as FilterListIcon } from "@mui/icons-material";

const COLORS = {
  primary: "#881f9b",
};

interface HostHeaderProps {
  searchTerm: string;
  status: 1 | 0 | null;
  kycStatus: "all" | "verified" | "pending" | "rejected";
  onSearch: (
    search: string,
    status: 1 | 0 | null,
    kycStatus: "all" | "verified" | "pending" | "rejected"
  ) => void;
  onAdd: () => void;
}

export const HostHeader = ({
  searchTerm,
  status,
  kycStatus,
  onSearch,
  onAdd,
}: HostHeaderProps) => {
  const [localSearch, setLocalSearch] = useState(searchTerm);

  /* 🔁 Sync when parent resets */
  useEffect(() => {
    setLocalSearch(searchTerm);
  }, [searchTerm]);

  /* ================= HANDLERS ================= */

  const handleSearch = () => {
    onSearch(localSearch, status, kycStatus);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      handleSearch();
    }
  };

  const toggleStatus = (value: 1 | 0) => {
    // deselect if clicked again
    const newStatus = status === value ? null : value;
    onSearch(localSearch, newStatus, kycStatus);
  };

  const applyKycStatus = (value: "all" | "verified" | "pending" | "rejected") => {
    onSearch(localSearch, status, value);
  };

  const handleClear = () => {
    setLocalSearch("");
    onSearch("", null, "all");
  };

  /* ================= RENDER ================= */

  return (
    <Box
      display="flex"
      justifyContent="space-between"
      alignItems="center"
      mb={4}
      flexWrap="wrap"
      gap={2}
    >
      {/* Title */}
      <Typography
        variant="h4"
        sx={{ color: COLORS.primary, fontWeight: 700 }}
      >
        Host Management
      </Typography>

      {/* Actions */}
      <Box display="flex" alignItems="center" gap={2} flexWrap="wrap">
        {/* Search */}
        <Box display="flex" gap={1} alignItems="center">
          <TextField
            label="Search host name or E-mail"
            size="small"
            value={localSearch}
            onChange={(e) => setLocalSearch(e.target.value)}
            onKeyDown={handleKeyDown}
            sx={{
              minWidth: 220,
              "& .MuiOutlinedInput-root": {
                color: COLORS.primary,
                "& fieldset": { borderColor: COLORS.primary },
                "&:hover fieldset": { borderColor: COLORS.primary },
                "&.Mui-focused fieldset": {
                  borderColor: COLORS.primary,
                },
              },
              "& .MuiInputLabel-root": { color: COLORS.primary },
              "& .MuiInputLabel-root.Mui-focused": {
                color: COLORS.primary,
              },
            }}
          />

          <Button
            variant="contained"
            onClick={handleSearch}
            sx={{ background: COLORS.primary }}
          >
            Search
          </Button>

          {/* Clear */}
          <Button
            variant="outlined"
            onClick={handleClear}
            disabled={!localSearch && status === null}
            sx={{
              borderColor: COLORS.primary,
              color: COLORS.primary,
            }}
          >
            Clear
          </Button>
        </Box>

        {/* Status Filters */}
        <Stack direction="row" spacing={2}>
          {/* Active */}
          <Button
            variant="outlined"
            startIcon={<FilterListIcon />}
            onClick={() => toggleStatus(1)}
            sx={{
              borderColor: "#2e7d32",
              color: status === 1 ? "#fff" : "#2e7d32",
              backgroundColor: status === 1 ? "#2e7d32" : "transparent",
              "&:hover": {
                backgroundColor:
                  status === 1 ? "#2e7d32" : "#e0f2f1",
                borderColor: "#2e7d32",
              },
            }}
          >
            Active
          </Button>

          {/* Inactive */}
          <Button
            variant="outlined"
            startIcon={<FilterListIcon />}
            onClick={() => toggleStatus(0)}
            sx={{
              borderColor: "#d32f2f",
              color: status === 0 ? "#fff" : "#d32f2f",
              backgroundColor: status === 0 ? "#d32f2f" : "transparent",
              "&:hover": {
                backgroundColor:
                  status === 0 ? "#d32f2f" : "#fdecea",
                borderColor: "#d32f2f",
              },
            }}
          >
            Inactive
          </Button>
        </Stack>

        {/* KYC Filters */}
        <Stack direction="row" spacing={1}>
          <Button
            variant={kycStatus === "all" ? "contained" : "outlined"}
            onClick={() => applyKycStatus("all")}
            sx={{
              minWidth: 72,
              backgroundColor: kycStatus === "all" ? COLORS.primary : "transparent",
              borderColor: COLORS.primary,
              color: kycStatus === "all" ? "#fff" : COLORS.primary,
              "&:hover": {
                backgroundColor: kycStatus === "all" ? COLORS.primary : "#f5e9fb",
              },
            }}
          >
            KYC All
          </Button>
          <Button
            variant={kycStatus === "verified" ? "contained" : "outlined"}
            onClick={() => applyKycStatus("verified")}
            sx={{
              minWidth: 96,
              backgroundColor: kycStatus === "verified" ? "#2e7d32" : "transparent",
              borderColor: "#2e7d32",
              color: kycStatus === "verified" ? "#fff" : "#2e7d32",
              "&:hover": {
                backgroundColor: kycStatus === "verified" ? "#2e7d32" : "#e8f5e9",
              },
            }}
          >
            Verified
          </Button>
          <Button
            variant={kycStatus === "pending" ? "contained" : "outlined"}
            onClick={() => applyKycStatus("pending")}
            sx={{
              minWidth: 92,
              backgroundColor: kycStatus === "pending" ? "#ed6c02" : "transparent",
              borderColor: "#ed6c02",
              color: kycStatus === "pending" ? "#fff" : "#ed6c02",
              "&:hover": {
                backgroundColor: kycStatus === "pending" ? "#ed6c02" : "#fff3e0",
              },
            }}
          >
            Pending
          </Button>
          <Button
            variant={kycStatus === "rejected" ? "contained" : "outlined"}
            onClick={() => applyKycStatus("rejected")}
            sx={{
              minWidth: 96,
              backgroundColor: kycStatus === "rejected" ? "#d32f2f" : "transparent",
              borderColor: "#d32f2f",
              color: kycStatus === "rejected" ? "#fff" : "#d32f2f",
              "&:hover": {
                backgroundColor: kycStatus === "rejected" ? "#d32f2f" : "#ffebee",
              },
            }}
          >
            Rejected
          </Button>
        </Stack>

        {/* Add Host */}
        <Button
          variant="contained"
          onClick={onAdd}
          sx={{
            backgroundColor: COLORS.primary,
            borderRadius: 2,
            "&:hover": { backgroundColor: "#3730a3" },
          }}
        >
          Add Host
        </Button>
      </Box>
    </Box>
  );
};
