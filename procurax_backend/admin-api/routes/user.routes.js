import { Router } from "express";
import adminAuth from "../middleware/adminAuth.middleware.js";
import {
  approveUser,
  getUsers,
  rejectUser,
} from "../controllers/adminUser.controller.js";

const router = Router();

router.get("/", adminAuth, getUsers);
router.patch("/:id/approve", adminAuth, approveUser);
router.patch("/:id/reject", adminAuth, rejectUser);

export default router;
