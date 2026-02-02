import express from 'express';
import { createCall, getCall, updateCallStatus } from '../controllers/callController.js';

const router = express.Router();

router.post('/', createCall);               // Create a new call
router.get('/:id', getCall);                 // Get call details by ID
router.patch('/:id/status', updateCallStatus); // Update call status

export default router;
