import express from 'express';
import { getUserAlerts, markAlertsRead } from '../controllers/alertsController.js';

const router = express.Router();

// Get all alerts for a user
// GET /api/alerts/user/:userId
router.get('/user/:userId', getUserAlerts);

// Mark alerts read for a user and chat
// PATCH /api/alerts/read
router.patch('/read', markAlertsRead);

export default router;