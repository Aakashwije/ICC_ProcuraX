import mongoose from "mongoose";
import jwt from "jsonwebtoken";
import { secret } from "../config/jwt.js";

/*
  Auth middleware that verifies the JWT token from the Authorization header.
  Sets req.userId and req.user on the request if valid.
  Returns 401 if token is missing or invalid.
*/
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.split(" ")[1] : authHeader;

  if (!token) {
    return res.status(401).json({ message: "No token provided. Please log in." });
  }

  try {
    const decoded = jwt.verify(token, secret);
    req.userId = decoded.id;
    req.user = decoded;
    return next();
  } catch (err) {
    return res.status(401).json({ message: "Invalid or expired token. Please log in again." });
  }
};

export default authMiddleware;
