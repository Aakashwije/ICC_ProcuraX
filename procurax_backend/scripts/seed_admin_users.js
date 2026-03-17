import "../config/env.js";
import mongoose from "mongoose";
import User from "../models/User.js";

const uri =
  process.env.MONGODB_URI ||
  process.env.MONGO_URI ||
  "mongodb://127.0.0.1:27017/procurax";

const adminUsers = [
  {
    name: "Project Admin",
    email: "admin1@icc.lk",
    password: "Admin@2026#Secure1",
    role: "admin",
    isApproved: true,
    isActive: true,
  },
  {
    name: "System Admin",
    email: "admin2@icc.lk",
    password: "Admin@2026#Secure2",
    role: "admin",
    isApproved: true,
    isActive: true,
  },
  {
    name: "Operations Admin",
    email: "admin3@icc.lk",
    password: "Admin@2026#Secure3",
    role: "admin",
    isApproved: true,
    isActive: true,
  },
];

const run = async () => {
  await mongoose.connect(uri);
  console.log("Connected to MongoDB");

  for (const adminData of adminUsers) {
    let user = await User.findOne({ email: adminData.email });

    if (user) {
      // Update existing user to ensure they are admin
      user.role = "admin";
      user.isApproved = true;
      user.isActive = true;
      user.name = adminData.name;
      // Update password (the pre-save hook will hash it)
      user.password = adminData.password;
      await user.save();
      console.log(`✅ Updated existing admin: ${adminData.email}`);
    } else {
      // Create new admin user
      user = new User(adminData);
      await user.save();
      console.log(`✅ Created new admin: ${adminData.email}`);
    }
  }

  await mongoose.disconnect();
  console.log("\n🎉 All admin users seeded successfully!");
};

run().catch((error) => {
  console.error("❌ Seed failed:", error);
  process.exit(1);
});
