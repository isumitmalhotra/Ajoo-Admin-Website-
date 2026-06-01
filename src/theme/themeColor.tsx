// Sand & Indigo design tokens (client-approved Option 3)
export const Brand = {
  indigo:    "#1B2447",
  indigo600: "#2A356B",
  clay:      "#C16345",
  clay600:   "#A8512F",
  sand:      "#EFE7D6",
  cream:     "#FFFAF0",
  ink:       "#1B2447",
  ink2:      "#3D4670",
  muted:     "#6B7390",
  line:      "#D9CFB8",
  success:   "#3F6B4E",
};

// Back-compat alias — resolves to Brand.indigo (#1B2447). Still imported by ~15 admin
// files. Keep until those are migrated; never points to a purple value.
export const PurpleThemeColor = Brand.indigo;

export const ThemeColors = {
  primary:    Brand.indigo,
  secondary:  Brand.success,
  background: Brand.sand,
  text: {
    primary:   Brand.ink,
    secondary: Brand.muted,
  },
};

export const FOCUS_COLOR = Brand.indigo;

export const FieldLabelColor = {
  "& .MuiOutlinedInput-root.Mui-focused fieldset": {
    borderColor: Brand.indigo,
  },
  "& .MuiInputLabel-root.Mui-focused": {
    color: Brand.indigo,
  },
};

export const commonFieldSx = {
  minWidth: 180,
  "& .MuiOutlinedInput-root": {
    "&.Mui-focused fieldset": {
      borderColor: FOCUS_COLOR,
    },
  },
  "& .MuiInputLabel-root.Mui-focused": {
    color: FOCUS_COLOR,
  },
};

export const menuProps = {
  PaperProps: {
    sx: {
      borderRadius: 2,
      mt: 1,
      "& .MuiMenuItem-root": {
        fontSize: "0.85rem",
        "&.Mui-selected": {
          backgroundColor: `${FOCUS_COLOR}15`,
          color: FOCUS_COLOR,
        },
        "&:hover": {
          backgroundColor: `${FOCUS_COLOR}10`,
        },
      },
    },
  },
};
