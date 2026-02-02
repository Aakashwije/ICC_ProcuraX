import express from 'express';
import { setTyping, getTyping } from '../controllers/typingController.js';

const router = express.Router();

//Set typing status for a user in a chat
router.post('/', setTyping);

//Get typing status for a user in a chat
// GET /api/typing?chatId=CHAT_ID&userId=USER_ID
router.get('/', getTyping);

export default router;