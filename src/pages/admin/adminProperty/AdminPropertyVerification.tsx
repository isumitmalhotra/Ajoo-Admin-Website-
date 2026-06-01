import { Box, Typography } from "@mui/material"

const AdminPropertyVerification = () => {
    const purpleTheme = {
  primary: {
    main: "#1B2447",
    light: "#C16345",
    dark: "#5B21B6",
    contrastText: "#FFFFFF",
  },
  secondary: {
    main: "#EC4899",
    light: "#F472B6",
    dark: "#BE185D",
  },
  background: {
    default: "#F8FAFC",
    paper: "#FFFFFF",
  },
};
  return (
    <>
       <Box>
        <Typography
          variant="h4"
          sx={{
            fontWeight: 700,
            background: `linear-gradient(135deg, ${purpleTheme.primary.main}, ${purpleTheme.secondary.main})`,
            backgroundClip: "text",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            mb: 1,
          }}
        >
            Property Verification

        </Typography>
        <Typography variant="body1" color="text.secondary">
            Review and manage property verification requests from users.

        </Typography>
       </Box>


    </>
  )
}

export default AdminPropertyVerification