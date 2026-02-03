import express from 'express';
import { getProjectManagers, getAllUsers } from '../controllers/userController.js';

const router = express.Router();

// Get all project managers only
// GET /api/users/project-managers
router.get('/', getProjectManagers);

// Get all users
// GET /api/users/all
router.get('/all', getAllUsers);

export default router;