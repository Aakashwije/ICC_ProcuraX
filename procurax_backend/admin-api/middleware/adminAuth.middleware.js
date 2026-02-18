import jwt from "jsonwebtoken";
import { secret } from "../../config/jwt.js";

const adminAuthMiddleware = (req, res, next) => {
  const authHeader = req.headers["authorization"] || "";
  const token = authHeader.startsWith("Bearer ")
    ? authHeader.split(" ")[1]
    : authHeader;

  if (!token) {
    return res.status(401).json({
      message: "No token"
    });
  }

  try {
    const decoded = jwt.verify(token, secret);

    if (decoded.role !== "admin") {
      return res.status(403).json({
        message: "Admins only"
      });
    }

    req.admin = decoded;
    next();

  } catch (error) {
    res.status(401).json({
      message: "Invalid token"
    });
  }
};

export default adminAuthMiddleware;
