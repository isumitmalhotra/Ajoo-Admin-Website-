import { Navigate, Outlet } from "react-router-dom";
import { useEffect, useState } from "react";
import { API_BASE_URL } from "../configs/apiConfigs";
import { getAdminClaims, getAdminToken, clearAdminSession } from "../services/adminSession";
import { hasAnyRole, type AppRole } from "../services/apiContracts";

const DEV_BYPASS_ENABLED =
  import.meta.env.DEV &&
  (import.meta.env.VITE_ENABLE_DEV_ADMIN_BYPASS === "true" ||
    import.meta.env.VITE_ADMIN_BYPASS === "true");

const DISABLE_ADMIN_AUTH =
  import.meta.env.DEV &&
  import.meta.env.VITE_DISABLE_ADMIN_AUTH === "true";

const ADMIN_ALLOWED_ROLES: AppRole[] = ["admin", "finance", "support"];

const AdminProtectedRoute = () => {
  const [isAuth, setIsAuth] = useState<boolean | null>(null);

  if (DISABLE_ADMIN_AUTH) {
    return <Outlet />;
  }

  useEffect(() => {
    // Local-only bypass for developer verification while auth backend is unavailable.
    if (DEV_BYPASS_ENABLED) {
      setIsAuth(true);
      return;
    }

    const token = getAdminToken();

    if (!token) {
      setIsAuth(false);
      return;
    }

    const claims = getAdminClaims();
    if (claims && !hasAnyRole(claims, ADMIN_ALLOWED_ROLES)) {
      clearAdminSession();
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
        clearAdminSession();
        setIsAuth(false);
      }
    };

    verifyToken();
  }, []);

  // Loader while verifying
  if (isAuth === null) return null;

  return isAuth ? <Outlet /> : <Navigate to="/admin/login" replace />;
};

export const GuestRoute = () => {
  const token = getAdminToken();
  if (token) {
    return <Navigate to="/admin/dashboard" replace />;
  }

  return <Outlet />;
};

export default AdminProtectedRoute;
