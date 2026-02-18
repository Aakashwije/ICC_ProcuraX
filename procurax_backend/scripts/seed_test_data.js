import "../config/env.js";
import mongoose from "mongoose";
import User from "../models/User.js";
import Project from "../models/Project.js";

const uri =
  process.env.MONGODB_URI ||
  process.env.MONGO_URI ||
  "mongodb://127.0.0.1:27017/procurax";

const ensureUser = async ({ email, role, isApproved, isActive, name }) => {
  let user = await User.findOne({ email });
  if (!user) {
    user = new User({
      name,
      email,
      password: "password",
      role,
      isApproved,
      isActive,
    });
    await user.save();
  }
  return user;
};

const ensureProject = async ({ name, sheetUrl, managerId, managerName }) => {
  let project = await Project.findOne({ name });
  if (!project) {
    project = new Project({
      name,
      sheetUrl,
      managerId,
      managerName,
      status: "Active",
    });
    await project.save();
  }
  return project;
};

const run = async () => {
  await mongoose.connect(uri);

  const admin = await ensureUser({
    email: "admin@example.com",
    name: "Admin User",
    role: "admin",
    isApproved: true,
    isActive: true,
  });

  const manager = await ensureUser({
    email: "manager@example.com",
    name: "Project Manager",
    role: "project_manager",
    isApproved: true,
    isActive: true,
  });

  await ensureUser({
    email: "pending@example.com",
    name: "Pending User",
    role: "project_manager",
    isApproved: false,
    isActive: true,
  });

  await ensureProject({
    name: "Tower A - Downtown",
    sheetUrl: "https://docs.google.com/spreadsheets/d/example",
    managerId: manager._id,
    managerName: manager.name,
  });

  await mongoose.disconnect();

  console.log("Seed complete");
};

run().catch((error) => {
  console.error("Seed failed", error);
  process.exit(1);
});
