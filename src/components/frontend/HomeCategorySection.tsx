import { Box, Typography, Grid, Container } from "@mui/material";
const roomImages = ["/room1.jpg", "/room2.jpg", "/room3.jpg", "/room4.jpg"];

const HomeCategorySection = () => {
  // const HomeCategorySection = () => {
  // Example click handler
  const handleClick = (idx: number) => {
    console.log(`Clicked on category ${idx + 1}`);
    // You can navigate or trigger any action here
  };

  return (
    <>
      <Container sx={{ py: 6 }}>
        <Typography variant="h4" fontWeight="bold" color="#1B2447" gutterBottom>
          Our Categories
        </Typography>

        <Grid container spacing={3}>
          {roomImages.map((src, idx) => (
            <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
              <Box
                onClick={() => handleClick(idx)}
                sx={{
                  width: "100%",
                  height: "200px",
                  borderRadius: 2,
                  boxShadow: 3,
                  overflow: "hidden",
                  cursor: "pointer",
                  transition: "transform 0.3s, box-shadow 0.3s",
                  "&:hover": {
                    transform: "scale(1.05)",
                    boxShadow: 6,
                  },
                }}
              >
                <Box
                  component="img"
                  src={src}
                  alt={`gallery-${idx}`}
                  sx={{
                    width: "100%",
                    height: "100%",
                    objectFit: "cover",
                  }}
                />
              </Box>
            </Grid>
          ))}
        </Grid>
      </Container>
    </>
  );
};
export default HomeCategorySection;
