import express from 'express';
import { createChat, getUserChats, getChatById, markChatRead } from '../controllers/chatController.js';


const router = express.Router();

// Create new chat
// POST /api/chats
router.post('/', createChat);

// Get all chats for a user
// GET /api/chats/user/:userId
router.get('/user/:userId', getUserChats);

// Get chat by ID
// GET /api/chats/:id
router.get('/:id', getChatById);

// Mark chat as read for a user
// PATCH /api/chats/:id/read
router.patch('/:id/read', markChatRead);



export default router;