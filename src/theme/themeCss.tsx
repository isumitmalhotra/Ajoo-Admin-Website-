import { Brand } from "./themeColor";

export const themeCss = {
  modalFormContainer: {
    position: "absolute",
    top: "50%",
    left: "50%",
    transform: "translate(-50%, -50%)",
    width: { xs: "90%", sm: 500, md: 600 },
    bgcolor: "background.paper",
    borderRadius: 4,
    boxShadow: "0 8px 24px rgba(0,0,0,0.2)",
    overflowY: "auto",
    transition: "all 0.3s ease-in-out",
  },
  modalHeader: {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    px: 3,
    py: 2,
    bgcolor: Brand.indigo,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
  },
};
