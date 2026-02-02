import { db } from '../config/firebase.js';


async function sendMessage(req, res) {
  try {
    //Debugging line
    console.log('BODY:', req.body); 

    const { chatId, senderId, content, type, fileUrl, fileName } = req.body;

    //Basic validation
    if (!chatId || !senderId || !type) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    //Text message must have content
    if (type === 'text' && !content) {
      return res.status(400).json({ error: 'content is required for text messages' });
    }

    //file message must have fileUrl
    if (type === 'file' && !fileUrl) {
      return res.status(400).json({ error: 'fileUrl is required for file messages' });
    }

    //Clean Ids
    const trimmedChatId = chatId.trim();
    const trimmedSenderId = senderId.trim();

    //Ensure chat exists
    const chatRef = db.collection('chats').doc(trimmedChatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      return res.status(404).json({ error: 'Chat not found' });
    }

    const now = new Date();

    //Message data to store
    const messageData = {
      chatId: trimmedChatId,
      senderId: trimmedSenderId,
      content: content || fileName || fileUrl || '',
      type,
      fileUrl: fileUrl || null,
      fileName: fileName || null,
      //readBy: [senderId],
      createdAt: now,
    };

    //Save message to Firestore
    const docRef = await db.collection('messages').add(messageData);

    const chatData = chatDoc.data() || {};
    // Get members or userIds array from chat document
    const members = Array.isArray(chatData.members)
      ? chatData.members
      : Array.isArray(chatData.userIds)
          ? chatData.userIds
          : [];
    const unreadCounts = { ...(chatData.unreadCounts || {}) };

    const alertsBatch = db.batch();
    // Create alerts for all members except sender
    members.forEach(memberId => {
      if (memberId === trimmedSenderId) {
        unreadCounts[memberId] = 0;
      } else {
        unreadCounts[memberId] = (unreadCounts[memberId] || 0) + 1;

        const alertRef = db.collection('alerts').doc();
        alertsBatch.set(alertRef, {
          userId: memberId,
          chatId: trimmedChatId,
          senderId: trimmedSenderId,
          title: `New message from ${trimmedSenderId}`,
          message: content,
          isRead: false,
          createdAt: now,
        });
      }
    });

    //Update chat metadata
    await chatRef.update({
      lastMessage: content,
      lastMessageSenderId: trimmedSenderId,
      updatedAt: now,
      unreadCounts,
    });

    //Save all alerts at once to the firebase
    await alertsBatch.commit();

    res.status(201).json({
      id: docRef.id,
      ...messageData,
      createdAt: now.toISOString(),
    });
  } catch (err) {
    console.error('ERROR IN sendMessage:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

//Get messages by chat ID
 async function getMessagesByChat(req, res) {
  try{
    let {chatId} = req.query;
    //  childId is required
    if (!chatId){
      return res.status(400).json({error: 'chatId is required'});
    }
    // Trim chatId
    chatId = chatId.trim(); 

    //Fetch messages from Firestore
    const snapshot = await db
      .collection('messages')
      .where('chatId', '==', chatId)
      .orderBy('createdAt', 'asc')
      .get();

    
    // Map documents to message objects
     const messages = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.() || doc.data().createdAt,

    }));
    console.log('Fetched messages:', messages); // 👈 debug line
    res.json(messages);
  } catch (err){
    console.error('ERROR IN getMessagesByChat:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  
  }
 }


export { sendMessage, getMessagesByChat };
