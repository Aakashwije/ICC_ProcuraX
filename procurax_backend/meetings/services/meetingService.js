const Meeting = require("../models/Meeting");

exports.findConflicts = async (startTime, endTime, excludeId = null) => {
  const query = {
    startTime: { $lt: endTime },
    endTime: { $gt: startTime }
  };

  if (excludeId) {
    query._id = { $ne: excludeId };
  }

  return await Meeting.find(query);
};

exports.suggestNextSlot = async (startTime, durationMinutes = 60) => {
  const meetings = await Meeting.find().sort({ startTime: 1 });

  let proposedStart = new Date(startTime);

  for (const meeting of meetings) {
    if (proposedStart < meeting.endTime) {
      proposedStart = meeting.endTime;
    }
  }

  return {
    suggestedStart: proposedStart,
    suggestedEnd: new Date(
      proposedStart.getTime() + durationMinutes * 60000
    )
  };
};
