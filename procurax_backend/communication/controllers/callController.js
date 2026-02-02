import { db } from '../config/firebase.js';

// Create a new call record
async function createCall(req, res) {
  try {
    const { callerId, receiverId, startTime, status } = req.body;

    if (!callerId || !receiverId || !startTime || !status) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const callData = {
      callerId,
      receiverId,
      startTime: new Date(startTime),
      status, // e.g., "ringing", "in-progress", "ended"
      createdAt: new Date(),
    };

    const callRef = await db.collection('calls').add(callData);

    res.status(201).json({ id: callRef.id, ...callData });
  } catch (error) {
    console.error('Error creating call:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// Get call details by call ID
async function getCall(req, res) {
  try {
    const callId = req.params.id;
    const callDoc = await db.collection('calls').doc(callId).get();

    if (!callDoc.exists) {
      return res.status(404).json({ error: 'Call not found' });
    }

    res.json({ id: callDoc.id, ...callDoc.data() });
  } catch (error) {
    console.error('Error getting call:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// Update call status (e.g., from "ringing" to "in-progress" or "ended")
async function updateCallStatus(req, res) {
  try {
    const callId = req.params.id;
    const { status, endTime } = req.body;

    if (!status) {
      return res.status(400).json({ error: 'Status is required' });
    }

    const updateData = { status };
    if (endTime) {
      updateData.endTime = new Date(endTime);
    }

    const callRef = db.collection('calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      return res.status(404).json({ error: 'Call not found' });
    }

    await callRef.update(updateData);

    res.json({ id: callId, ...updateData });
  } catch (error) {
    console.error('Error updating call:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

export { createCall, getCall, updateCallStatus };
