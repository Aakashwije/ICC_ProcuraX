/**
 * Project Service
 *
 * Business logic layer for project operations.
 * Handles CRUD, manager assignment, and notification triggers.
 */

import Project from "../../models/Project.js";
import User from "../../models/User.js";
import { AppError } from "../errors/AppError.js";
import logger from "../logging/logger.js";
import NotificationService from "../../notifications/notification.service.js";

class ProjectService {
  /**
   * Get all projects
   */
  async getProjects(options = {}) {
    const { status, page = 1, limit = 50 } = options;

    const query = {};
    if (status) query.status = status;

    const projects = await Project.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);

    const total = await Project.countDocuments(query);

    return {
      projects,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    };
  }

  /**
   * Get a single project by ID
   */
  async getProjectById(projectId) {
    const project = await Project.findById(projectId);

    if (!project) {
      throw AppError.notFound("Project");
    }

    return project;
  }

  /**
   * Create a new project
   */
  async createProject(data) {
    logger.debug("Creating project", { name: data.name });

    const project = new Project({
      name: data.name,
      sheetUrl: data.sheetUrl,
    });

    await project.save();

    logger.info("Project created", { projectId: project._id });
    return project;
  }

  /**
   * Update a project
   */
  async updateProject(projectId, updates) {
    logger.debug("Updating project", { projectId, fields: Object.keys(updates) });

    const oldProject = await Project.findById(projectId);
    if (!oldProject) {
      throw AppError.notFound("Project");
    }

    const project = await Project.findByIdAndUpdate(projectId, updates, {
      new: true,
      runValidators: true,
    });

    // Notify manager of status change
    if (project.managerId && updates.status && updates.status !== oldProject.status) {
      try {
        await NotificationService.createProjectNotification(project.managerId, {
          projectName: project.name,
          projectId: project._id,
          projectStatus: updates.status,
          action: "statusChanged",
        });
      } catch (err) {
        logger.error("Failed to send project status notification", { err: err.message });
      }
    }

    logger.info("Project updated", { projectId });
    return project;
  }

  /**
   * Assign a manager to a project
   */
  async assignManager(projectId, managerId) {
    if (!projectId) {
      throw AppError.badRequest("Project ID is required");
    }

    // Unassign manager
    if (!managerId) {
      await Project.findByIdAndUpdate(projectId, {
        managerId: null,
        managerName: "Unassigned",
      });
      logger.info("Manager unassigned from project", { projectId });
      return { success: true };
    }

    const manager = await User.findById(managerId);
    if (!manager) {
      throw AppError.notFound("Manager");
    }

    const project = await Project.findByIdAndUpdate(
      projectId,
      { managerId, managerName: manager.name },
      { new: true }
    );

    if (!project) {
      throw AppError.notFound("Project");
    }

    // Notify manager of assignment
    try {
      await NotificationService.createProjectNotification(managerId, {
        projectName: project.name,
        projectId: project._id,
        projectStatus: project.status || "active",
        action: "assigned",
      });
    } catch (err) {
      logger.error("Failed to send assignment notification", { err: err.message });
    }

    logger.info("Manager assigned to project", { projectId, managerId });
    return { success: true };
  }

  /**
   * Delete a project
   */
  async deleteProject(projectId) {
    const project = await Project.findByIdAndDelete(projectId);

    if (!project) {
      throw AppError.notFound("Project");
    }

    logger.info("Project deleted", { projectId });
    return { success: true };
  }
}

export default new ProjectService();
