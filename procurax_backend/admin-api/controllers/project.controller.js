/**
 * Project Controller (Refactored)
 *
 * Thin controller layer — delegates ALL business logic to ProjectService.
 * Controller handles only HTTP request/response concerns.
 *
 * Architecture: Controller → Service → Model (3-tier)
 */

import ProjectService from "../../core/services/project.service.js";
import { asyncHandler } from "../../core/middleware/errorHandler.js";

export const getProjects = asyncHandler(async (req, res) => {
  const result = await ProjectService.getProjects(req.query);
  res.json(result.projects);
});

export const addProject = asyncHandler(async (req, res) => {
  await ProjectService.createProject(req.body);
  res.json({ success: true });
});

export const assignManager = asyncHandler(async (req, res) => {
  const { projectId, managerId } = req.body;
  await ProjectService.assignManager(projectId, managerId);
  res.json({ success: true });
});

export const updateProject = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const project = await ProjectService.updateProject(id, req.body);
  res.json({ success: true, project });
});

export const deleteProject = asyncHandler(async (req, res) => {
  await ProjectService.deleteProject(req.params.id);
  res.json({ success: true });
});
