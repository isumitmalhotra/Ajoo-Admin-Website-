import React from "react";
import { Box, Checkbox, FormControlLabel, Typography } from "@mui/material";
import { useFormikContext } from "formik";
import { sectionBox } from "./styles";

const PURPLE = "#1B2447";

const RoleSelector = ({ disabled }: { disabled: boolean }) => {
  const { values, setFieldValue } = useFormikContext<any>();

  return (
    <Box sx={sectionBox}>
      <Typography fontSize={14} fontWeight={600} mb={1}>
        Account Role
      </Typography>

      <FormControlLabel
        control={
          <Checkbox
            checked={values.user}
            onChange={(e) => setFieldValue("user", e.target.checked)}
            disabled={disabled}
            sx={{
              color: PURPLE,
              "&.Mui-checked": { color: PURPLE },
              "&.Mui-disabled": { color: `${PURPLE}80` },
            }}
          />
        }
        label="User"
      />

      <FormControlLabel
        control={
          <Checkbox
            checked={values.host}
            onChange={(e) => setFieldValue("host", e.target.checked)}
            disabled={disabled}
            sx={{
              color: PURPLE,
              "&.Mui-checked": { color: PURPLE },
              "&.Mui-disabled": { color: `${PURPLE}80` },
            }}
          />
        }
        label="Host"
      />
    </Box>
  );
};

// export default RoleSelector;
export default React.memo(RoleSelector);

