
import { db, bucket } from '../config/firebase.js'; 
import User from '../../models/User.js';
import admin from 'firebase-admin';

/**
 * Send an FCM push notification for a chat message.
 * Looks up the recipient in MongoDB to get their FCM tokens,
 * then sends a high-priority notification.
 * Fire-and-forget — errors are logged but don't break the response.
 */
async function sendChatPushNotification(recipientMongoId, senderName, messagePreview, chatId) {
  try {
    const user = await User.findById(recipientMongoId).select('+fcmTokens').lean();
    if (!user?.fcmTokens?.length) return;

    const messaging = admin.messaging();
    const messages = user.fcmTokens.map((token) => ({
      token,
      notification: {
        title: `Message from ${senderName}`,
        body: messagePreview.length > 100 ? messagePreview.slice(0, 100) + '…' : messagePreview,
      },
      data: {
        type: 'chat_message',
        chatId: String(chatId),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'procurax_notifications',
          sound: 'default',
        },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    }));

    const response = await messaging.sendEach(messages);

    // Clean up stale tokens
    const tokensToRemove = [];
    response.responses.forEach((resp, idx) => {
      if (resp.error) {
        const code = resp.error.code;
        if (
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered'
        ) {
          tokensToRemove.push(user.fcmTokens[idx]);
        }
      }
    });
    if (tokensToRemove.length > 0) {
      await User.findByIdAndUpdate(recipientMongoId, {
        $pull: { fcmTokens: { $in: tokensToRemove } },
      });
    }

    console.log(`[FCM-Chat] Sent to user ${recipientMongoId}: ${response.successCount}/${messages.length}`);
  } catch (err) {
    console.error('[FCM-Chat] Push error:', err.message);
  }
}


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
      content: content ||  fileName  || fileUrl || '',
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
          message: content || fileName || 'File Attachment',
          isRead: false,
          createdAt: now,
        });
      }
    });

    //Update chat metadata
    await chatRef.update({
      lastMessage: content || fileName || 'File Attachment',
      lastMessageSenderId: trimmedSenderId,
      updatedAt: now,
      unreadCounts,
    });

    //Save all alerts at once to the firebase
    await alertsBatch.commit();

    // ── Send FCM push notifications to all recipients ──
    // Look up sender name for a friendly notification title
    let senderName = trimmedSenderId;
    try {
      const senderUser = await User.findById(trimmedSenderId).select('name firstName').lean();
      if (senderUser) {
        senderName = senderUser.name || senderUser.firstName || trimmedSenderId;
      }
    } catch (_) { /* use ID as fallback */ }

    const messagePreview = content || fileName || 'File Attachment';

    // Fire-and-forget: send push to each non-sender member
    members.forEach((memberId) => {
      if (memberId !== trimmedSenderId) {
        sendChatPushNotification(memberId, senderName, messagePreview, trimmedChatId);
      }
    });

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
  try {
    let { chatId } = req.query;
    //  childId is required
    if (!chatId) {
      return res.status(400).json({ error: 'chatId is required' });
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
  } catch (err) {
    console.error('ERROR IN getMessagesByChat:', err);
    res.status(500).json({ error: 'Internal Server Error' });

  }
}
//Delete  a meesage by ID 
async function deleteMessage(req, res) {
  try {
    const { id } = req.params; // message ID is required
    const { userId } = req.body; // userId is required to check if the sender is deleting their own message

    if (!id) return res.status(400).json({ error: 'Message ID is required' });
    if (!userId) return res.status(400).json({ error: 'User ID is required' });

    // Fetch the message to check if it exists and if the user is the sender
    const msgRef = db.collection('messages').doc(id);
    const msgDoc = await msgRef.get();

    if (!msgDoc.exists) {
      return res.status(404).json({ error: 'Message not found' });
    }

    const msgData = msgDoc.data() || {};

    //only the sender can delete their message
    if ((msgData.senderId || '').trim() !== userId.trim()) {
      return res.status(403).json({ error: 'You can only delete your own messages' });
    }


    // Delete file from Storage if it's a file message
if (msgData.type === 'file' && msgData.fileUrl && bucket) {
  try {
    const filePath = msgData.fileUrl.split(`${bucket.name}/`)[1]; // ← backticks, not quotes
    if (filePath) {
      await bucket.file(filePath).delete();
      console.log(`File ${filePath} deleted successfully.`);
    } else {
      console.warn('Could not extract file path from URL:', msgData.fileUrl);
    }
  } catch (e) {
    console.warn('Storage file delete failed (non-critical):', e.message);
  }
}

// Delete the message
// Delete the message
await msgRef.delete();

// Update lastMessage on the chat
const chatId = msgData.chatId;
if (chatId) {
  const chatRef = db.collection('chats').doc(chatId);
  const remaining = await db
    .collection('messages')
    .where('chatId', '==', chatId)
    .get();

  const sorted = remaining.docs.sort((a, b) => {
    const aTime = a.data().createdAt?.toMillis?.() || 0;
    const bTime = b.data().createdAt?.toMillis?.() || 0;
    return bTime - aTime;
  });

  if (sorted.length > 0) {
    const newLast = sorted[0].data();
    await chatRef.update({
      lastMessage: newLast.content || '',
      lastMessageSenderId: newLast.senderId || '',
      updatedAt: new Date(),
    });
  } else {
    await chatRef.update({
      lastMessage: '',
      lastMessageSenderId: '',
      updatedAt: new Date(),
    });
  }
}

return res.status(200).json({ success: true, id });
  } catch (err) {
    console.error('ERROR IN deleteMessage:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}
    


export { sendMessage, getMessagesByChat, deleteMessage };
