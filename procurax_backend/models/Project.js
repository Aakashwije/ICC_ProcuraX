import mongoose from "mongoose";

const ProjectSchema = new mongoose.Schema({
  name: { type: String, required: true },

  managerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    default: null
  },

  managerName: {
    type: String,
    default: "Unassigned"
  },

  sheetUrl: { type: String, required: true },

  status: {
    type: String,
    default: "Active"
  },

  createdAt: {
    type: Date,
    default: Date.now
  }
});

export default mongoose.model("Project", ProjectSchema);
