/*
  Note model: defines how notes are stored in MongoDB.
*/
import mongoose from "mongoose";

const noteSchema = new mongoose.Schema(
  {
    /*
      Title and content are required fields.
    */
    title: { type: String, required: true, trim: true },
    content: { type: String, required: true, trim: true },
    /*
      Tag helps categorize the note (default: "Issue").
    */
    tag: { type: String, default: "Issue" },
    /*
      Dates for creation and last edit.
    */
    createdAt: { type: Date, default: Date.now },
    lastEdited: { type: Date, default: Date.now },
    /*
      Attachment flag (true if note has any file).
    */
    hasAttachment: { type: Boolean, default: false },
    /*
      Owner is the user who created the note.
    */
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { versionKey: false }
);

/*
  Export Note model for controllers.
*/
export default mongoose.model("Note", noteSchema);
