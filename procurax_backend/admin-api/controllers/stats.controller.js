import User from "../../models/User.js";
import Project from "../../models/Project.js";

export const getStats = async (req, res) => {
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
