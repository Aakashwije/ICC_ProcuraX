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
*/
router.get("/procurement", authenticate, async (req, res) => {
  try {
    /*
      The service handles caching + formatting.
      We just send the response as JSON.
    */
    const data = await getProcurementView();
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
