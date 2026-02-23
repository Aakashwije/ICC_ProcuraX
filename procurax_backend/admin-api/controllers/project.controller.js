import Project from "../../models/Project.js";
import User from "../../models/User.js";

export const getProjects = async (req, res) => {
  const projects = await Project.find();
  res.json(projects);
};

export const addProject = async (req, res) => {
  const { name, sheetUrl } = req.body;

  const project = new Project({
    name,
    sheetUrl
  });

  await project.save();

  res.json({ success: true });
};

export const assignManager = async (req, res) => {
  const { projectId, managerId } = req.body;

  if (!projectId) {
    return res.status(400).json({ message: "Project ID is required" });
  }

  if (!managerId) {
    await Project.findByIdAndUpdate(projectId, {
      managerId: null,
      managerName: "Unassigned"
    });

    return res.json({ success: true });
  }

  const manager = await User.findById(managerId);

  if (!manager) {
    return res.status(404).json({ message: "Manager not found" });
  }

  await Project.findByIdAndUpdate(projectId, {
    managerId,
    managerName: manager.name
  });

  res.json({ success: true });
};

export const updateProject = async (req, res) => {
  const { id } = req.params;
  const { status, name, sheetUrl } = req.body;

  const project = await Project.findByIdAndUpdate(
    id,
    { status, name, sheetUrl },
    { new: true }
  );

  if (!project) {
    return res.status(404).json({ message: "Project not found" });
  }

  res.json({ success: true, project });
};

export const deleteProject = async (req, res) => {
  await Project.findByIdAndDelete(req.params.id);
  res.json({ success: true });
};
