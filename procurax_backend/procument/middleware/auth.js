/*
  Procurement API auth middleware.
  This checks the Authorization header and only allows
  requests that match ADMIN_TOKEN or APP_TOKEN.
*/
export function authenticate(req, res, next) {
  /*
    Expected header format: "Bearer <token>".
    We split on space and take the second item.
  */
  const header = req.headers.authorization || "";
  const token = header.split(" ")[1] || "";
  if (!token) return res.status(401).json({ error: "No token provided" });

  /*
    If token matches admin/app tokens from env,
    allow request and set req.isAdmin for later use.
  */
  if (token === process.env.ADMIN_TOKEN || token === process.env.APP_TOKEN) {
    req.isAdmin = token === process.env.ADMIN_TOKEN;
    return next();
  }

  /*
    If token is wrong, block the request.
  */
  return res.status(403).json({ error: "Invalid token" });
}
