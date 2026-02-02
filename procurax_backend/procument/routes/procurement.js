// procurax_backend/procument/routes/procurement.js
import express from "express";
import { getProcurementView } from "../services/procurement.service.js";
import { authenticate } from "../middleware/auth.js";

const router = express.Router();

router.get("/procurement", authenticate, async (req, res) => {
  try {
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


export default router;
