/**
 * Projects Routes v1
 *
 * RESTful API routes for project management with validation.
 * Architecture: Route → Controller (asyncHandler) → Service → Model
 */

import { Router } from "express";
import {
  authMiddleware,
  adminMiddleware,
  validateBody,
  validateObjectId,
  asyncHandler,
  projectSchemas,
  ProjectService,
} from "../../core/index.js";

const router = Router();

/**
 * GET /api/v1/projects
 * Get all projects (authenticated users)
 */
router.get(
  "/",
  authMiddleware,
  asyncHandler(async (req, res) => {
    const result = await ProjectService.getProjects(req.query);
    res.json({ success: true, ...result });
  })
);

/**
 * GET /api/v1/projects/:id
 * Get a specific project
 */
router.get(
  "/:id",
  authMiddleware,
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    const project = await ProjectService.getProjectById(req.params.id);
    res.json({ success: true, project });
  })
);

/**
 * POST /api/v1/projects
 * Create a project (admin only)
 */
router.post(
  "/",
  adminMiddleware,
  validateBody(projectSchemas.create),
  asyncHandler(async (req, res) => {
    const project = await ProjectService.createProject(req.validatedBody);
    res.status(201).json({ success: true, project });
  })
);

/**
 * PUT /api/v1/projects/:id
 * Update a project (admin only)
 */
router.put(
  "/:id",
  adminMiddleware,
  validateObjectId("id"),
  validateBody(projectSchemas.update),
  asyncHandler(async (req, res) => {
    const project = await ProjectService.updateProject(
      req.params.id,
      req.validatedBody
    );
    res.json({ success: true, project });
  })
);

/**
 * PATCH /api/v1/projects/assign-manager
 * Assign a manager to a project (admin only)
 */
router.patch(
  "/assign-manager",
  adminMiddleware,
  validateBody(projectSchemas.assignManager),
  asyncHandler(async (req, res) => {
    await ProjectService.assignManager(
      req.validatedBody.projectId,
      req.validatedBody.managerId
    );
    res.json({ success: true });
  })
);

/**
 * DELETE /api/v1/projects/:id
 * Delete a project (admin only)
 */
router.delete(
  "/:id",
  adminMiddleware,
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    await ProjectService.deleteProject(req.params.id);
    res.json({ success: true });
  })
);

export default router;
