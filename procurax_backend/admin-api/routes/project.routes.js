import { Router } from "express";
import {
	getProjects,
	addProject,
	assignManager,
	deleteProject
} from "../controllers/project.controller.js";
import adminAuth from "../middleware/adminAuth.middleware.js";

const router = Router();

router.get("/", adminAuth, getProjects);
router.post("/", adminAuth, addProject);
router.post("/assign", adminAuth, assignManager);
router.delete("/:id", adminAuth, deleteProject);

export default router;
