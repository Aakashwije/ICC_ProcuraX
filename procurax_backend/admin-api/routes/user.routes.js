import { Router } from "express";
import { adminMiddleware as adminAuth } from "../../core/middleware/auth.middleware.js";
import {
  approveUser,
  assignSheetUrl,
  getUsers,
  rejectUser,
} from "../controllers/adminUser.controller.js";

const router = Router();

router.get("/", adminAuth, getUsers);
router.patch("/:id/approve", adminAuth, approveUser);
router.patch("/:id/reject", adminAuth, rejectUser);

/* PATCH /admin-users/:id/sheet-url — assign procurement sheet URL to a user */
router.patch("/:id/sheet-url", adminAuth, assignSheetUrl);

export default router;
