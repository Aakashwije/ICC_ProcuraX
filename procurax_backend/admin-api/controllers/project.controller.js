const Project = require("../../models/Project");
const User = require("../../models/User");

exports.getProjects = async (req, res) => {
  const projects = await Project.find();
  res.json(projects);
};

exports.addProject = async (req, res) => {
  const { name, sheetUrl } = req.body;

  const project = new Project({
    name,
    sheetUrl
  });

  await project.save();

  res.json({ success: true });
};

exports.assignManager = async (req, res) => {
  const { projectId, managerId } = req.body;

  const manager = await User.findById(managerId);

  await Project.findByIdAndUpdate(projectId, {
    managerId,
    managerName: manager.name
  });

  res.json({ success: true });
};

exports.deleteProject = async (req, res) => {
  await Project.findByIdAndDelete(req.params.id);
  res.json({ success: true });
};
