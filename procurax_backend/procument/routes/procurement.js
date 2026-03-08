/*
  Procurement routes: this module exposes endpoints for
  fetching procurement data (read-only view from Sheets).
*/
import express from "express";
import { getProcurementView } from "../services/procurement.service.js";
import { authenticate } from "../middleware/auth.js";

/*
  Create an Express router so we can mount these routes in app.js.
*/
const router = express.Router();

/*
  GET /procurement
  - protected by authenticate middleware
  - returns cached/processed procurement view
  - uses userId from auth context to ensure per-user caching
*/
router.get("/procurement", authenticate, async (req, res) => {
  try {
    /*
      The sheetUrl is passed as a query parameter from the Flutter frontend.
      If missing, the service falls back to the default environment variable.
      The userId comes from the authenticate middleware (JWT or token).
    */
    const { sheetUrl } = req.query;
    const userId = req.userId || req.user?.id || "anon";

    /*
      The service handles caching + formatting, using both sheetUrl and userId.
      This ensures each user has their own cached data.
    */
    const data = await getProcurementView(sheetUrl, userId);
    res.json(data);
  } catch (err) {
    console.error("🔥 PROCUREMENT ERROR:", err);
    res.status(500).json({
      error: "Failed to load procurement data",
      details: err.message,
    });
  }
});

/*
  Export router so app.js can mount it under /api.
*/
export default router;
