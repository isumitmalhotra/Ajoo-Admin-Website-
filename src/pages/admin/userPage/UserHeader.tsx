import { Box, Button, Stack, TextField, Typography } from "@mui/material";
import { useState, useEffect } from "react";
import { useAppDispatch } from "../../../app/hooks";
import { fetchUsers } from "../../../features/admin/userManagement/user.slice";
import { FilterList as FilterListIcon } from "@mui/icons-material";
import { useDebounce } from "../../../hooks/useDebounce";

const COLORS = {
  primary: "#1B2447",
};

interface UserHeaderProps {
  searchTerm: string;
  onSearch: (value: string) => void;
  onAdd: () => void;
}

type StatusFilter = 1 | 0 | null;

export const UserHeader = ({
  searchTerm,
  onSearch,
  onAdd,
}: UserHeaderProps) => {
  const dispatch = useAppDispatch();
  /* ================= STATE ================= */
  const [status, setStatus] = useState<StatusFilter>(null);
  const [search, _setSearch] = useState("");
  const isActive = status === 1;
  const isInactive = status === 0;

  const debouncedSearch = useDebounce(search, 500);
  // const dispatch = useAppDispatch();

  /* ================= API TRIGGER ================= */
  const hitStatusApi = (overrideStatus?: StatusFilter) => {
    console.log("Calling API with status:", status);
    dispatch(
      fetchUsers({
        page: 1,
        search: debouncedSearch,
        status: overrideStatus ?? status,
      })
    ).unwrap();
  };

  useEffect(() => {
    hitStatusApi();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch]);

  return (
    <Box
      display="flex"
      justifyContent="space-between"
      alignItems="center"
      mb={4}
      flexWrap="wrap"
      gap={2}
    >
      <Typography variant="h4" sx={{ color: COLORS.primary, fontWeight: 700 }}>
        User Management
      </Typography>

      <Box display="flex" alignItems="center" gap={2} flexWrap="wrap">
        {/* ================= SEARCH ================= */}
        <Box display="flex" gap={1} alignItems="center">
          <TextField
            label="Search name or E-mail"
            size="small"
            value={searchTerm}
            onChange={(e) => onSearch(e.target.value)}
            sx={{
              minWidth: 200,
              "& .MuiOutlinedInput-root": {
                color: COLORS.primary,
                "& fieldset": { borderColor: COLORS.primary },
                "&:hover fieldset": { borderColor: COLORS.primary },
                "&.Mui-focused fieldset": { borderColor: COLORS.primary },
              },
              "& .MuiInputLabel-root": { color: COLORS.primary },
              "& .MuiInputLabel-root.Mui-focused": {
                color: COLORS.primary,
              },
            }}
          />
          {/* <Button variant="contained" sx={{ background: COLORS.primary }}>
            Search
          </Button> */}
        </Box>

        {/* ================= FILTER TOGGLES ================= */}
        <Stack direction="row" spacing={2}>
          {/* ACTIVE */}
          <Button
            variant="outlined"
            startIcon={<FilterListIcon />}
            onClick={() => {
              const next = isActive ? null : 1;
              setStatus(next);
              hitStatusApi(next);
            }}
            sx={{
              borderColor: "#2e7d32",
              color: isActive ? "#fff" : "#2e7d32",
              backgroundColor: isActive ? "#2e7d32" : "transparent",
              "&:hover": {
                backgroundColor: "#e0f2f1",
                borderColor: "#2e7d32",
                color: "#2e7d32",
              },
            }}
          >
            {isActive ? "Active (ON)" : "Active (OFF)"}
          </Button>

          {/* INACTIVE */}
          <Button
            variant="outlined"
            startIcon={<FilterListIcon />}
            onClick={() => {
              const next = isInactive ? null : 0;
              setStatus(next);
              hitStatusApi(next);
            }}
            sx={{
              borderColor: "#d32f2f",
              color: isInactive ? "#fff" : "#d32f2f",
              backgroundColor: isInactive ? "#d32f2f" : "transparent",
              "&:hover": {
                backgroundColor: "#fdecea",
                borderColor: "#d32f2f",
                color: "#d32f2f",
              },
            }}
          >
            {isInactive ? "Inactive (ON)" : "Inactive (OFF)"}
          </Button>
        </Stack>

        {/* ================= ADD USER ================= */}
        <Button
          variant="contained"
          onClick={onAdd}
          sx={{
            backgroundColor: COLORS.primary,
            borderRadius: 2,
            "&:hover": { backgroundColor: "#3730a3" },
          }}
        >
          Add User
        </Button>
      </Box>
    </Box>
  );
};
