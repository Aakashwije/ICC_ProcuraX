import mongoose from "mongoose";

const MeetingSchema = new mongoose.Schema(
	{
		title: {
			type: String,
			required: true,
			trim: true,
		},
		description: {
			type: String,
			default: "",
			trim: true,
		},
		date: {
			type: Date,
			required: true,
		},
		startTime: {
			type: String,
			default: "",
			trim: true,
		},
		endTime: {
			type: String,
			default: "",
			trim: true,
		},
		location: {
			type: String,
			default: "",
			trim: true,
		},
	},
	{
		timestamps: true,
	}
);

export default mongoose.model("Meeting", MeetingSchema);
