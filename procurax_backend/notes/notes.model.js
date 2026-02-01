import mongoose from "mongoose";

const noteSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    content: { type: String, required: true, trim: true },
    tag: { type: String, default: "Issue" },
    location: { type: String, default: "Unknown" },
    createdAt: { type: Date, default: Date.now },
    lastEdited: { type: Date, default: Date.now },
    hasAttachment: { type: Boolean, default: false },
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { versionKey: false }
);

export default mongoose.model("Note", noteSchema);
