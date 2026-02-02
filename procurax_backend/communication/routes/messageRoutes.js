import express from 'express';
import { sendMessage, getMessagesByChat } from '../controllers/messageController.js';

const router = express.Router();

// Send a new message
router.post('/', sendMessage);

// Get messages by chat ID
// GET /api/messages?chatId=CHAT_ID
router.get('/', getMessagesByChat);

export default router;