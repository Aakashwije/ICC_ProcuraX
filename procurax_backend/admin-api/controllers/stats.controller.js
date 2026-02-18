import User from "../../models/User.js";
import Project from "../../models/Project.js";

export const getStats = async (req, res) => {
  const totalManagers = await User.countDocuments({
    role: "project_manager"
  });

  const activeProjects = await Project.countDocuments({
    status: "Active"
  });

  const pendingApprovals = await User.countDocuments({
    role: "project_manager",
    isApproved: false
  });

  res.json({
    totalManagers,
    activeProjects,
    pendingApprovals
  });
};
