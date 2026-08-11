import {
  Box,
  TextField,
  CircularProgress,
  IconButton,
  InputAdornment,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import { useEffect, useState } from "react";
import { useAppDispatch, useAppSelector } from "../../../app/hooks";
import {
  fetchHostsForProperty,
  resetHostForProperty,
} from "../../../features/admin/userManagement/hostForProperty.slice";
import { useDebounce } from "../../../hooks/useDebounce";

const INDIGO = "#1B2447";

interface Props {
  value: string; // hostName from Formik
  onSelect: (host: any) => void;
  onClear?: () => void; // optional clear handler
  disabled?: boolean;
}

export default function HostAssignField({
  value,
  onSelect,
  onClear,
  disabled,
}: Props) {
  const dispatch = useAppDispatch();
  const { hosts, loading } = useAppSelector((state) => state.hostForProperty);

  const [inputValue, setInputValue] = useState(value);
  const [open, setOpen] = useState(false);
  const [hasSelected, setHasSelected] = useState(false);

  const debouncedSearch = useDebounce(inputValue, 400);

  useEffect(() => {
    setInputValue(value);
    if (value) setHasSelected(true);
  }, [value]);

  useEffect(() => {
    if (
      !debouncedSearch.trim() ||
      disabled ||
      hasSelected ||
      debouncedSearch === value // 🔒 prevents API on refresh
    ) {
      setOpen(false);
      return;
    }
  
    dispatch(fetchHostsForProperty({ search: debouncedSearch }));
    setOpen(true);
  }, [debouncedSearch, disabled, hasSelected, value, dispatch]);
  

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value);
    setHasSelected(false); // user started typing again
  };



  const handleSelect = (host: any) => {
    onSelect(host);
    setInputValue(host.user_fullName);
    setHasSelected(true); // 🔒 lock dropdown
    setOpen(false);
    dispatch(resetHostForProperty());
  };

  const handleClear = () => {
    setInputValue("");
    setHasSelected(false);
    onClear?.();
    dispatch(resetHostForProperty());
    setOpen(false);
  };
  return (
    <Box position="relative">
      <TextField
        fullWidth
        label="Assign Host"
        value={inputValue}
        disabled={disabled}
        // onChange={(e) => setInputValue(e.target.value)}
        onChange={handleInputChange}
        // onFocus={() => inputValue && setOpen(true)}
        onFocus={() => {
            if (!hasSelected && inputValue) setOpen(true);
          }}
        InputProps={{
          endAdornment: (
            <>
              {loading && <CircularProgress size={18} />}
              {inputValue && !disabled && (
                <InputAdornment position="end">
                  <IconButton size="small" onClick={handleClear}>
                    <CloseIcon fontSize="small" />
                  </IconButton>
                </InputAdornment>
              )}
            </>
          ),
        }}
        sx={{
          "& .MuiOutlinedInput-root": {
            "&.Mui-focused fieldset": {
              borderColor: INDIGO,
              borderWidth: 2,
            },
          },
          "& .MuiInputLabel-root.Mui-focused": {
            color: INDIGO,
          },
        }}
      />

      {/* 🔽 Dropdown */}
      {open && !disabled && hosts.length > 0 && (
        <Box
          sx={{
            position: "absolute",
            zIndex: 10,
            width: "100%",
            mt: 0.5,
            bgcolor: "#fff",
            border: "1px solid #ddd",
            borderRadius: 1,
            maxHeight: 220,
            overflowY: "auto",
            boxShadow: 3,
          }}
        >
          {hosts.map((h) => (
            <Box
              key={h.user_id}
              onClick={() => handleSelect(h)}
              sx={{
                p: 1.5,
                cursor: "pointer",
                "&:hover": {
                  backgroundColor: "#f3e8ff",
                },
              }}
            >
              <strong>{h.user_fullName}</strong>
              <Box sx={{ fontSize: 12, color: "#6b7280" }}>
                {h.userCred?.cred_user_email}
              </Box>
            </Box>
          ))}
        </Box>
      )}
    </Box>
  );
}
