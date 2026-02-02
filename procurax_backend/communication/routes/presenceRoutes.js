import express from 'express';
import { heartbeat, getPresence } from '../controllers/presenceController.js';

const router = express.Router();


// User heartbeat to indicate presence

router.post('/heartbeat', heartbeat);

// Get presence status for a user
// GET /api/presence/:userId
router.get('/:userId', getPresence);

export default router;