import { Router } from "express";
import {
	getManagers,
	addManager,
	deleteManager,
	toggleAccess
} from "../controllers/manager.controller.js";
import adminAuth from "../middleware/adminAuth.middleware.js";

const router = Router();

router.get("/", adminAuth, getManagers);
router.post("/", adminAuth, addManager);
router.delete("/:id", adminAuth, deleteManager);
router.post("/toggle/:id", adminAuth, toggleAccess);

export default router;
