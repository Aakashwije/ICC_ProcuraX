/*
  Procurement API auth middleware.
  Accepts:
  1. A valid JWT token (signed with JWT_SECRET) — used by the Flutter app.
  2. ADMIN_TOKEN or APP_TOKEN — for legacy/admin access.
*/
import jwt from "jsonwebtoken";

export function authenticate(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.split(" ")[1] : header.split(" ")[1] || "";

  if (!token) return res.status(401).json({ error: "No token provided" });

  /*
    First check legacy static tokens (ADMIN_TOKEN / APP_TOKEN).
  */
  if (token === process.env.ADMIN_TOKEN || token === process.env.APP_TOKEN) {
    req.isAdmin = token === process.env.ADMIN_TOKEN;
    return next();
  }

  /*
    Otherwise try to verify as a JWT issued by the auth service.
  */
  try {
    const secret = process.env.JWT_SECRET || "change_me";
    const decoded = jwt.verify(token, secret);
    req.userId = decoded.id;
    req.user = decoded;
    req.isAdmin = decoded.role === "admin";
    return next();
  } catch {
    return res.status(403).json({ error: "Invalid or expired token" });
  }
}
