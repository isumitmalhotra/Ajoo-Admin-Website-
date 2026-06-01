import { Box, Typography } from "@mui/material"

const AdminPropertyVerification = () => {
    const indigoTheme = {
  primary: {
    main: "#1B2447",
    light: "#2A356B",
    dark: "#0E1A2E",
    contrastText: "#FFFAF0",
  },
  secondary: {
    main: "#C16345",
    light: "#D9CFB8",
    dark: "#A8512F",
  },
  background: {
    default: "#EFE7D6",
    paper: "#FFFAF0",
  },
};
  return (
    <>
       <Box>
        <Typography
          variant="h4"
          sx={{
            fontWeight: 700,
            background: `linear-gradient(135deg, ${indigoTheme.primary.main}, ${indigoTheme.secondary.main})`,
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