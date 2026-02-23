/**
 * user.controller.js
 *
 * User-defined controller functions for the /api/user routes.
 * Handles reading the authenticated user's own profile data,
 * including their assigned Google/Excel Sheet URL.
 */

import User from "../../models/User.js";
import jwt from "jsonwebtoken";
import { secret } from "../../config/jwt.js";

/* ─────────────────────────────────────────────────────────────────────────
   extractUserId
   Parses the JWT from the Authorization header and returns the user ID.
   Returns null if the token is missing or invalid.
────────────────────────────────────────────────────────────────────────── */
function extractUserId(req) {
  const authHeader = req.headers["authorization"] || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.split(" ")[1] : authHeader;
  if (!token) return null;

  try {
    const decoded = jwt.verify(token, secret);
    return decoded.id || null;
  } catch {
    return null;
  }
}

/* ─────────────────────────────────────────────────────────────────────────
   getUserProfile
   GET /api/user/profile
   Returns the authenticated user's profile including their assigned
   Google/Excel Sheet URL for the procurement schedule.
────────────────────────────────────────────────────────────────────────── */
export async function getUserProfile(req, res) {
  try {
    const userId = extractUserId(req);
    if (!userId) {
      return res.status(401).json({ message: "Unauthorized. Please log in." });
    }

    const user = await User.findById(userId).select(
      "name email phone role isApproved googleSheetUrl lastLogin createdAt"
    );

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        isApproved: user.isApproved,
        googleSheetUrl: user.googleSheetUrl ?? null,
        lastLogin: user.lastLogin,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}
