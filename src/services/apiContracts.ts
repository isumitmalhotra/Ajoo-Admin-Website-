export const APP_ROLES = ["admin", "finance", "host", "support", "guest"] as const;

export type AppRole = (typeof APP_ROLES)[number];

export interface RbacClaims {
  sub: string | number;
  role: AppRole;
  permissions: string[];
  scope?: string[];
  tenantId?: string | number;
  iat?: number;
  exp?: number;
  iss?: string;
  aud?: string | string[];
}

export interface ApiResponseEnvelope<T> {
  success?: boolean;
  message?: string;
  data?: T;
  error?: {
    code?: string;
    details?: unknown;
  };
  meta?: unknown;
}

export interface AdminAuthPayload {
  admin: Record<string, unknown>;
  token: string;
  claims: RbacClaims | null;
  roles: AppRole[];
  permissions: string[];
  message: string;
}

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

const asString = (value: unknown): string | null =>
  typeof value === "string" && value.trim().length > 0 ? value : null;

const asStringArray = (value: unknown): string[] => {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string");
};

const isAppRole = (value: unknown): value is AppRole =>
  typeof value === "string" && APP_ROLES.includes(value as AppRole);

const decodeBase64Url = (value: string): string | null => {
  try {
    const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
    const json = atob(padded);
    return decodeURIComponent(
      json
        .split("")
        .map((char) => `%${char.charCodeAt(0).toString(16).padStart(2, "0")}`)
        .join("")
    );
  } catch {
    return null;
  }
};

const decodeJwtPayload = (token: string): Record<string, unknown> | null => {
  const parts = token.split(".");
  if (parts.length < 2) return null;
  const decoded = decodeBase64Url(parts[1]);
  if (!decoded) return null;

  try {
    const parsed: unknown = JSON.parse(decoded);
    return isRecord(parsed) ? parsed : null;
  } catch {
    return null;
  }
};

export const normalizeRbacClaims = (value: unknown): RbacClaims | null => {
  if (!isRecord(value)) return null;

  const subject = value.sub;
  if (typeof subject !== "string" && typeof subject !== "number") return null;

  const roleValue = value.role;
  if (!isAppRole(roleValue)) return null;

  const permissions = asStringArray(value.permissions);
  const scope = asStringArray(value.scope);

  return {
    sub: subject,
    role: roleValue,
    permissions,
    scope: scope.length > 0 ? scope : undefined,
    tenantId:
      typeof value.tenantId === "string" || typeof value.tenantId === "number"
        ? value.tenantId
        : undefined,
    iat: typeof value.iat === "number" ? value.iat : undefined,
    exp: typeof value.exp === "number" ? value.exp : undefined,
    iss: asString(value.iss) || undefined,
    aud:
      typeof value.aud === "string" || Array.isArray(value.aud)
        ? (value.aud as string | string[])
        : undefined,
  };
};

export const extractApiData = <T>(payload: unknown): T | null => {
  if (!isRecord(payload)) return null;
  if ("data" in payload) return (payload.data as T) ?? null;
  return payload as T;
};

export const extractApiMessage = (payload: unknown, fallback = ""): string => {
  if (!isRecord(payload)) return fallback;
  const message = asString(payload.message);
  return message || fallback;
};

export const parseAdminAuthPayload = (payload: unknown): AdminAuthPayload | null => {
  const root = isRecord(payload) ? payload : null;
  if (!root) return null;

  const dataNode = extractApiData<Record<string, unknown>>(payload);
  const node = dataNode && isRecord(dataNode) ? dataNode : root;

  // Resolve the admin/user node FIRST — the backend nests the token INSIDE it
  // (response shape: { data: { admin: { ...fields, token } } }), so the token
  // lookup below must check adminNode as well as the top level.
  const adminNode = isRecord(node.admin)
    ? node.admin
    : isRecord(node.user)
    ? node.user
    : {};

  const token =
    asString(node.token) ||
    asString(node.accessToken) ||
    asString(node.jwt) ||
    asString(node.authToken) ||
    asString(adminNode.token) ||
    asString(adminNode.accessToken) ||
    asString(adminNode.jwt);

  if (!token) return null;

  const explicitClaims = normalizeRbacClaims(node.claims ?? node.rbacClaims ?? node.jwtClaims);
  const tokenClaims = normalizeRbacClaims(decodeJwtPayload(token));
  const claims = explicitClaims || tokenClaims;

  const roles = asStringArray(node.roles).filter((role): role is AppRole => isAppRole(role));
  if (claims?.role && !roles.includes(claims.role)) {
    roles.push(claims.role);
  }

  const permissions = asStringArray(node.permissions);
  if (claims?.permissions?.length) {
    const merged = new Set([...permissions, ...claims.permissions]);
    return {
      admin: adminNode,
      token,
      claims,
      roles,
      permissions: [...merged],
      message: extractApiMessage(payload),
    };
  }

  return {
    admin: adminNode,
    token,
    claims,
    roles,
    permissions,
    message: extractApiMessage(payload),
  };
};

export const hasAnyRole = (claims: RbacClaims | null, roles: AppRole[]): boolean => {
  if (!claims) return false;
  return roles.includes(claims.role);
};

export const extractClaimsFromToken = (token: string): RbacClaims | null =>
  normalizeRbacClaims(decodeJwtPayload(token));
