const User = require("../../models/User");
const Project = require("../../models/Project");

exports.getStats = async (req, res) => {
  const totalManagers = await User.countDocuments({
    role: "USER"
  });

  const activeProjects = await Project.countDocuments({
    status: "Active"
  });

  const pendingApprovals = await User.countDocuments({
    status: "PENDING"
  });

  res.json({
    totalManagers,
    activeProjects,
    pendingApprovals
  });
};
