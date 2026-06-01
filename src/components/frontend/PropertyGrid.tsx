import { Box } from "@mui/material";
import { Link } from "react-router-dom";
import { HomePropCard } from "../../components";

const PropertyGrid = ({ properties }: any) => {
  return (
    <Box
      sx={{
        display: "grid",
        gap: "24px",
        gridTemplateColumns: {
          xs: "1fr",
          sm: "repeat(2, 1fr)",
          lg: "repeat(3, 1fr)",
        },
      }}
    >
      {properties.map((p: any, i: number) => (
        <Link
          to={`/property/detail/${i + 1}`}
          key={i}
          style={{ textDecoration: "none" }}
        >
          {/* Override image aspect-ratio to 4/3 for listing page */}
          <Box
            sx={{
              "& .card-img-wrapper": {
                aspectRatio: "4/3 !important",
              },
            }}
          >
            <HomePropCard {...p} />
          </Box>
        </Link>
      ))}
    </Box>
  );
};

export default PropertyGrid;
