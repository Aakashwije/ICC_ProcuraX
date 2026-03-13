import { Router } from "express";
import {
	getManagers,
	addManager,
	updateManager,
	deleteManager,
	toggleAccess
} from "../controllers/manager.controller.js";
import { adminMiddleware as adminAuth } from "../../core/middleware/auth.middleware.js";

const router = Router();

router.get("/", adminAuth, getManagers);
router.post("/", adminAuth, addManager);
router.put("/:id", adminAuth, updateManager);
router.delete("/:id", adminAuth, deleteManager);
router.patch("/:id/access", adminAuth, toggleAccess);
router.post("/toggle/:id", adminAuth, toggleAccess);

export default router;
