import {
  Pagination as MuiPagination,
  PaginationItem,
  Box,
} from "@mui/material";
import { ArrowBackIosNew, ArrowForwardIos } from "@mui/icons-material";

interface PaginationComponentProps {
  count: number; // total number of pages
  page: number;
  onChange: (event: React.ChangeEvent<unknown>, value: number) => void;
}

const Pagination: React.FC<PaginationComponentProps> = ({
  count,
  page,
  onChange,
}) => {
  return (
    <Box display="flex" justifyContent="center" mt={2} mb={2}>
      <MuiPagination
        count={count}
        page={page}
        onChange={onChange}
        variant="outlined"
        shape="rounded"
        siblingCount={1}
        boundaryCount={1}
        renderItem={(item) => (
          <PaginationItem
            components={{ previous: ArrowBackIosNew, next: ArrowForwardIos }}
            {...item}
            sx={{
              borderRadius: "0.75rem", // 12px rounded
              fontFamily: "Lato",
              border: item.selected ? "2px solid #9B7EBD" : "1px solid #9B7EBD",
              backgroundColor: item.selected ? "#ede9fe" : "#fff",
              color: item.selected ? "#1B2447" : "#3D4670", // Deep purple vs gray-800
              fontWeight: item.selected ? 700 : 500,
              minWidth: "2.5rem", // 40px
              height: "2.5rem",
              transition: "all 0.25s ease-in-out",
              boxShadow: item.selected
                ? "0 2px 8px rgba(124, 58, 237, 0.15)"
                : "none",
              "&:hover": {
                backgroundColor: "#f3e8ff",
                borderColor: "#C16345",
                color: "#6b21a8",
              },
              "&.MuiPaginationItem-previousNext": {
                fontSize: "0.75rem",
              },
            }}
          />
        )}
      />
    </Box>
  );
};

export default Pagination;
