import { Brand } from "../../../../theme/themeColor";

export const fieldStyle = {
  "& .MuiOutlinedInput-root": {
    "& fieldset": {
      borderColor: "#1B2447",
    },
    "&:hover fieldset": {
      borderColor: "#1B2447",
    },
    "&.Mui-focused fieldset": {
      borderColor: "#1B2447",
    },
    "& input": {
      color: "#1B2447",
    },
    /* SELECTED VALUE (dropdown text) */
    "& .MuiSelect-select": {
      color: "#1B2447",
    },
  },
  "& .MuiInputLabel-root": {
    color: "#1B2447",
  },
  "& .MuiInputLabel-root.Mui-focused": {
    color: "#1B2447",
  },
  /* SELECTED VALUE (dropdown text) */
  "& .MuiSelect-select": {
    color: "#1B2447",
  },

  /* DROPDOWN ARROW ICON */
  "& .MuiSvgIcon-root": {
    color: "#1B2447",
  },
};
// styles.ts
export const personalInfoFieldStyle = {
  "& .MuiOutlinedInput-root": {
    color: "#1B2447", // ✅ input text color
    "& fieldset": {
      borderColor: "#1B2447",
    },
    "&:hover fieldset": {
      borderColor: "#1B2447",
    },
    "&.Mui-focused fieldset": {
      borderColor: "#1B2447",
    },
  },

  "& .MuiInputLabel-root": {
    color: "#1B2447",
  },
  "& .MuiInputLabel-root.Mui-focused": {
    color: "#1B2447",
  },

  "& .MuiFormHelperText-root": {
    color: "#1B2447", // optional: helper text color
  },
};

export const sectionBox = {
  gridColumn: "1 / -1",
  p: 2,
  borderRadius: 2,
  border: "1px solid #e5e7eb",
  backgroundColor: "#fafafa",
};

export const uploadBox = {
  display: "flex",
  gap: 2,
  alignItems: "center",
};

export const uploadPreview = {
  width: 120,
  height: 120,
  borderRadius: 2,
  objectFit: "cover",
  border: `1px solid ${Brand.indigo}`,
};
