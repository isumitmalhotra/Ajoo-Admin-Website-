import type { AppRole, RbacClaims } from "./apiContracts";
import { extractClaimsFromToken, normalizeRbacClaims } from "./apiContracts";

const ADMIN_TOKEN_KEY = "adminToken";
const ADMIN_USER_KEY = "adminUser";
const ADMIN_CLAIMS_KEY = "adminClaims";
const ADMIN_ROLES_KEY = "adminRoles";
const ADMIN_PERMISSIONS_KEY = "adminPermissions";

const parseJson = <T>(value: string | null): T | null => {
  if (!value) return null;
  try {
    return JSON.parse(value) as T;
  } catch {
    return null;
  }
};

export const getAdminToken = (): string | null => localStorage.getItem(ADMIN_TOKEN_KEY);

export const setAdminToken = (token: string): void => {
  localStorage.setItem(ADMIN_TOKEN_KEY, token);
};

export const setAdminUser = (user: Record<string, unknown>): void => {
  localStorage.setItem(ADMIN_USER_KEY, JSON.stringify(user));
};

export const getAdminUser = (): Record<string, unknown> | null =>
  parseJson<Record<string, unknown>>(localStorage.getItem(ADMIN_USER_KEY));

export const setAdminClaims = (claims: RbacClaims | null): void => {
  if (!claims) {
    localStorage.removeItem(ADMIN_CLAIMS_KEY);
    return;
  }

  localStorage.setItem(ADMIN_CLAIMS_KEY, JSON.stringify(claims));
};

export const getAdminClaims = (): RbacClaims | null => {
  const stored = parseJson<unknown>(localStorage.getItem(ADMIN_CLAIMS_KEY));
  const normalized = normalizeRbacClaims(stored);
  if (normalized) return normalized;

  const token = getAdminToken();
  return token ? extractClaimsFromToken(token) : null;
};

export const setAdminRoles = (roles: AppRole[]): void => {
  localStorage.setItem(ADMIN_ROLES_KEY, JSON.stringify(roles));
};

export const getAdminRoles = (): AppRole[] => {
  const roles = parseJson<unknown>(localStorage.getItem(ADMIN_ROLES_KEY));
  if (!Array.isArray(roles)) return [];
  return roles.filter((role): role is AppRole => typeof role === "string");
};

export const setAdminPermissions = (permissions: string[]): void => {
  localStorage.setItem(ADMIN_PERMISSIONS_KEY, JSON.stringify(permissions));
};

export const getAdminPermissions = (): string[] => {
  const permissions = parseJson<unknown>(localStorage.getItem(ADMIN_PERMISSIONS_KEY));
  if (!Array.isArray(permissions)) return [];
  return permissions.filter((permission): permission is string => typeof permission === "string");
};

export const clearAdminSession = (): void => {
  localStorage.removeItem(ADMIN_TOKEN_KEY);
  localStorage.removeItem(ADMIN_USER_KEY);
  localStorage.removeItem(ADMIN_CLAIMS_KEY);
  localStorage.removeItem(ADMIN_ROLES_KEY);
  localStorage.removeItem(ADMIN_PERMISSIONS_KEY);
};
