// Procurement API auth middleware.
// Accepts either ADMIN_TOKEN or APP_TOKEN from the Authorization header.
export function authenticate(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.split(" ")[1] || "";
  if (!token) return res.status(401).json({ error: "No token provided" });

  if (token === process.env.ADMIN_TOKEN || token === process.env.APP_TOKEN) {
    req.isAdmin = token === process.env.ADMIN_TOKEN;
    return next();
  }

  return res.status(403).json({ error: "Invalid token" });
}
