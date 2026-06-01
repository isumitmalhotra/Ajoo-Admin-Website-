// import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import { Provider } from "react-redux";
import { store } from "./app/store.ts";
import "leaflet/dist/leaflet.css";
import "slick-carousel/slick/slick.css";
import "slick-carousel/slick/slick-theme.css";
import AppSnackbarContainer from "./components/admin/common/AppSnackbarContainer.tsx";
import { createTheme, ThemeProvider } from "@mui/material/styles";
import CssBaseline from "@mui/material/CssBaseline";

import App from "./App.tsx";

const muiTheme = createTheme({
  palette: {
    primary: { main: "#1B2447" },
    secondary: { main: "#C16345" },
    background: { default: "#EFE7D6", paper: "#FFFAF0" },
    text: { primary: "#1B2447", secondary: "#6B7390" },
  },
  typography: {
    fontFamily: "'Inter', system-ui, sans-serif",
    h1: { fontFamily: "'Fraunces', serif", letterSpacing: "-0.035em", fontWeight: 400 },
    h2: { fontFamily: "'Fraunces', serif", letterSpacing: "-0.025em", fontWeight: 400 },
    h3: { fontFamily: "'Fraunces', serif", letterSpacing: "-0.02em", fontWeight: 400 },
    h4: { fontFamily: "'Fraunces', serif", letterSpacing: "-0.015em", fontWeight: 500 },
    h5: { fontFamily: "'Fraunces', serif", letterSpacing: "-0.01em", fontWeight: 500 },
    h6: { fontFamily: "'Fraunces', serif", letterSpacing: "-0.005em", fontWeight: 500 },
  },
  shape: { borderRadius: 10 },
});

createRoot(document.getElementById("root")!).render(
  <Provider store={store}>
    <ThemeProvider theme={muiTheme}>
      <CssBaseline />
      <App />
      <AppSnackbarContainer />
    </ThemeProvider>
  </Provider>
);
