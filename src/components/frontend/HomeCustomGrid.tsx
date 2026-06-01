import React from "react";
import "../../styles/user/HomeCustomGrid.css";
import { Typography, Container } from "@mui/material";

interface GridItem {
  id: number;
  title: string;
  image: string;
}

const gridItems: GridItem[] = [
  { id: 1, title: "Luxury Suite", image: "/room1.jpg" },
  { id: 2, title: "Deluxe Room", image: "/room2.jpg" },
  { id: 3, title: "Cozy Stay", image: "/room3.jpg" },
  { id: 4, title: "Modern Space", image: "/room4.jpg" },
  { id: 5, title: "Family Room", image: "/room5.webp" },
  { id: 6, title: "Penthouse", image: "/room6.jpg" },
];

const HomeCustomGrid: React.FC = () => {
  const handleClick = (item: GridItem) => {
    console.log(`Clicked on ${item.title}`);
  };

  return (
    <>
      <Container sx={{ py: 2 }}>
        <Typography variant="h4" fontWeight="bold" color="#1B2447" gutterBottom>
          For You
        </Typography>
      </Container>
      <div className="gridWrapper">
        <div className="parent">
          {gridItems.map((item) => (
            <div
              key={item.id}
              className={`div${item.id} gridBox`}
              onClick={() => handleClick(item)}
            >
              <img src={item.image} alt={item.title} className="gridImage" />
              <div className="overlay">
                <h3 className="title">{item.title}</h3>
              </div>
            </div>
          ))}
        </div>
      </div>
    </>
  );
};

export default HomeCustomGrid;
