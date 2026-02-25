import express from 'express';
import { sendMessage, getMessagesByChat, deleteMessage } from '../controllers/messageController.js';

const router = express.Router();

// Send a new message
router.post('/', sendMessage);

// Get messages by chat ID
// GET /api/messages?chatId=CHAT_ID
router.get('/', getMessagesByChat);


// Delete a message by ID
// DELETE /api/messages/:id
router.delete('/:id', (req, res, next) => {
    console.log("Delete message route hit with id:", req.params.id);
    next();
}, deleteMessage);

export default router;