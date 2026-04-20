import { Navigate, Outlet } from "react-router-dom";
import { useEffect, useState } from "react";
import { API_BASE_URL } from "../configs/apiConfigs";

const DEV_BYPASS_ENABLED =
  import.meta.env.DEV &&
  import.meta.env.VITE_ENABLE_DEV_ADMIN_BYPASS === "true";

const DISABLE_ADMIN_AUTH =
  import.meta.env.DEV &&
  import.meta.env.VITE_DISABLE_ADMIN_AUTH === "true";

const AdminProtectedRoute = () => {
  const [isAuth, setIsAuth] = useState<boolean | null>(null);

  if (DISABLE_ADMIN_AUTH) {
    return <Outlet />;
  }

  useEffect(() => {
    const token = localStorage.getItem("adminToken");

    if (!token) {
      setIsAuth(false);
      return;
    }

    // Dev-only bypass for local frontend testing.
    if (DEV_BYPASS_ENABLED && token === "dev-admin-token") {
      setIsAuth(true);
      return;
    }

    // OPTIONAL BUT STRONGLY RECOMMENDED
    // Verify token with backend
    const verifyToken = async () => {
      try {
        const res = await fetch(
          `${API_BASE_URL}/admin/verify-token`,
          {
            method: "GET",
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        if (!res.ok) throw new Error("Unauthorized");

        setIsAuth(true);
      } catch (error) {
        localStorage.removeItem("adminToken");
        setIsAuth(false);
      }
    };

    verifyToken();
  }, []);

  // Loader while verifying
  if (isAuth === null) return null;

  return isAuth ? <Outlet /> : <Navigate to="/admin/login" replace />;
};

export default AdminProtectedRoute;
