/**
 * user.routes.js
 *
 * Routes for user self-service profile operations.
 * Mounted at /api/user in app.js.
 */

import { Router } from "express";
import { getUserProfile } from "../controllers/user.controller.js";

const router = Router();

/* GET /api/user/profile — returns the logged-in user's profile + sheet URL */
router.get("/profile", getUserProfile);

export default router;
