/*
  Task model: defines how a task is stored in MongoDB.
  Each field has a type, default value, and rules.
*/
import mongoose from "mongoose";

const TaskSchema = new mongoose.Schema(
  {
    /*
      Task title is required and trimmed for clean input.
    */
    title: { type: String, required: true, trim: true },
    /*
      Optional description for extra details.
    */
    description: { type: String, default: "" },
    /*
      Status indicates the task progress.
    */
    status: {
      type: String,
      enum: ["todo", "in_progress", "blocked", "done"],
      default: "todo",
    },
    /*
      Priority helps sort tasks.
    */
    priority: {
      type: String,
      enum: ["low", "medium", "high", "critical"],
      default: "medium",
    },
    /*
      Due date can be null if not set.
    */
    dueDate: { type: Date, default: null },
    /*
      Assignee name or email stored as string.
    */
    assignee: { type: String, default: "" },
    /*
      Tags list used for filtering or grouping.
    */
    tags: { type: [String], default: [] },
    /*
      Owner is the user who created the task.
    */
    owner: { type: mongoose.Schema.Types.ObjectId, required: true },
    /*
      Archive flag for soft deletes.
    */
    isArchived: { type: Boolean, default: false },
  },
  { timestamps: true }
);

/*
  Export the Mongoose model so controller can query it.
*/
export default mongoose.model("Task", TaskSchema);
