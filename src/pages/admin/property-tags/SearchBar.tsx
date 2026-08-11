import React, { useState, ChangeEvent, FormEvent } from "react";
import { Box, Button, Stack, Typography, TextField, MenuItem } from "@mui/material";
import { Brand } from "../../../theme/themeColor";
import type { SearchBarProps } from './types';

const SearchBar: React.FC<SearchBarProps> = ({
  ThemeColors,
  filterData,
  handleFilterUpdate,
  handleFilter,
  handleClear,
  handleFormShow,
}) => {
  const [searchItem, setSearchItem] = useState("");

  const handleInputChange = (event: ChangeEvent<HTMLInputElement>) => {
    setSearchItem(event.target.value);
    handleFilterUpdate("search", event.target.value, false);
  };

  const handleCancel = () => {
    setSearchItem("");
    handleClear();
  };

  return (
    <Box display="flex" flexDirection="column" gap={3} mb={4}>
      <Box
        display="flex"
        alignItems="center"
        gap={2}
        flexWrap="wrap"
        justifyContent="space-between"
        width="100%"
      >
        <Typography
          variant="h4"
          sx={{
            color: ThemeColors.primary,
            fontWeight: 700,
          }}
        >
          Property Tags
        </Typography>

        <Button
          variant="contained"
          onClick={() => handleFormShow()} // <-- no id needed for Add
          sx={{
            backgroundColor: ThemeColors.primary,
            borderRadius: 2,
            "&:hover": {
              backgroundColor: "#3730a3",
            },
          }}
        >
          Add Tag
        </Button>
      </Box>

      <form
        onSubmit={(e: FormEvent<HTMLFormElement>) => {
          e.preventDefault();
          handleFilter();
        }}
      >
        <Box display="flex" alignItems="center" gap={2} flexWrap="wrap">
          {/* Search TextField */}
          <TextField
            label="Search by keyword..."
            variant="outlined"
            size="small"
            value={searchItem}
            onChange={handleInputChange}
            sx={{
              minWidth: 220,
              "& .MuiOutlinedInput-root.Mui-focused fieldset": {
                borderColor: Brand.indigo,
              },
              "& .MuiInputLabel-root.Mui-focused": {
                color: Brand.indigo,
              },
            }}
          />

          {/* Status Select */}
          <TextField
            label="Status"
            select
            size="small"
            name="status"
            value={filterData.status}
            onChange={(e: ChangeEvent<HTMLInputElement>) =>
              handleFilterUpdate("status", e.target.value, true)
            }
            sx={{
              minWidth: 160,
              "& .MuiOutlinedInput-root.Mui-focused fieldset": {
                borderColor: Brand.indigo,
              },
              "& .MuiInputLabel-root.Mui-focused": {
                color: Brand.indigo,
              },
            }}
          >
            <MenuItem value="">Select</MenuItem>
            <MenuItem value="1">Active</MenuItem>
            <MenuItem value="0">Inactive</MenuItem>
          </TextField>

          {/* Buttons */}
          <Stack direction="row" spacing={1}>
            <Button
              type="submit"
              variant="contained"
              sx={{ background: ThemeColors.primary }}
            >
              Search
            </Button>

            <Button
              variant="outlined"
              color="secondary"
              onClick={handleCancel}
            >
              Clear
            </Button>
          </Stack>
        </Box>
      </form>
    </Box>
  );
};

export default SearchBar;
