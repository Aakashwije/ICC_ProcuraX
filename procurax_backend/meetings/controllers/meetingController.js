import Meeting from "../models/Meeting.js";

export const getMeetings = async (req, res) => {
	try {
		const meetings = await Meeting.find().sort({ date: 1, startTime: 1 });
		res.json(meetings);
	} catch (error) {
		res.status(500).json({ message: "Failed to load meetings" });
	}
};

export const createMeeting = async (req, res) => {
	try {
		const {
			title,
			description = "",
			date,
			startTime = "",
			endTime = "",
			location = "",
		} = req.body;

		if (!title || !date) {
			return res.status(400).json({ message: "Title and date are required" });
		}

		const meeting = await Meeting.create({
			title,
			description,
			date,
			startTime,
			endTime,
			location,
		});

		res.status(201).json(meeting);
	} catch (error) {
		res.status(500).json({ message: "Failed to create meeting" });
	}
};

export const deleteMeeting = async (req, res) => {
	try {
		await Meeting.findByIdAndDelete(req.params.id);
		res.json({ success: true });
	} catch (error) {
		res.status(500).json({ message: "Failed to delete meeting" });
	}
};
