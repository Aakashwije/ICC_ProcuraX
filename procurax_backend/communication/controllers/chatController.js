import { db } from '../config/firebase.js';

// Create a new chat (individual or group)
async function createChat(req, res) {
  try {
    // Trim the name if it exists
    const name = req.body.name ? req.body.name.trim() : null;

    //Validate members array
    let members = req.body.members;
    if (!Array.isArray(members) || members.length === 0) {
      return res.status(400).json({ error: 'Members array is required' });
    }
    // Trim each member ID string
    members = members.map(member => member.trim());

    const isGroup = Boolean(req.body.isGroup);

    // Prevent duplicate 1:1 chats
    if (!isGroup && members.length === 2) {
      const [firstMember, secondMember] = members;
      const existingSnapshot = await db
        .collection('chats')
        .where('members', 'array-contains', firstMember)
        .get();

      const existingChat = existingSnapshot.docs.find(doc => {
        const data = doc.data() || {};
        const chatMembers = Array.isArray(data.members)
          ? data.members
          : Array.isArray(data.userIds)
              ? data.userIds
              : [];

        if (data.isGroup === true) return false;
        if (chatMembers.length !== 2) return false;
        return chatMembers.includes(firstMember) && chatMembers.includes(secondMember);
      });

      if (existingChat) {
        return res.status(200).json({ id: existingChat.id, ...existingChat.data() });
      }
    }

    //Initialize unread counts for each member
    const unreadCounts = {};
    members.forEach(memberId => {
      unreadCounts[memberId] = 0;
    });

    //chat document data
    const chatData = {
      name,
      members,
      isGroup,
      createdAt: new Date(),
      updatedAt: new Date(),
      unreadCounts,
    };

    //Save chat to Firestore
    const chatRef = await db.collection('chats').add(chatData);
    const chatDoc = await chatRef.get();

    res.status(201).json({ id: chatDoc.id, ...chatDoc.data() });
  } catch (error) {
    console.error('Error creating chat:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// Get all chats for a user (where user is a member)
async function getUserChats(req, res) {
  try {
    let userId = req.params.userId;
    userId = userId.trim();

    let chatsSnapshot = null;
    let fallbackSnapshot = null;

    //Main query to get chats by members array
    try {
      chatsSnapshot = await db
        .collection('chats')
        .where('members', 'array-contains', userId)
        .orderBy('updatedAt', 'desc')
        .get();
    } catch (err) {
      //Fallback if Firestore index error occurs
      const message = String(err?.message || err);
      if (message.toLowerCase().includes('index')) {
        chatsSnapshot = await db
          .collection('chats')
          .where('members', 'array-contains', userId)
          .get();
      } else {
        throw err;
      }
    }

    // Fallback for old schema using userIds instead of members
    if (chatsSnapshot.empty) {
      fallbackSnapshot = await db
        .collection('chats')
        .where('userIds', 'array-contains', userId)
        .get();
    }

    //Combine results and remove duplicates
    const docs = [
      ...(chatsSnapshot ? chatsSnapshot.docs : []),
      ...(fallbackSnapshot ? fallbackSnapshot.docs : []),
    ];

    const seen = new Set();
    const uniqueDocs = docs.filter(doc => {
      if (seen.has(doc.id)) return false;
      seen.add(doc.id);
      return true;
    });

    //Build chat list with other user details
    let chats = await Promise.all(
      uniqueDocs.map(async doc => {
        const data = doc.data();
        //support both members and userIds fields
        const members = Array.isArray(data.members)
          ? data.members
          : Array.isArray(data.userIds)
              ? data.userIds
              : [];
        //Find the other user in the chat
        const otherUserId = members.find(m => m !== userId) || null;

        let otherUserName = data.name || otherUserId || 'Unknown';
        let otherUserRole = data.role || 'Member';

        if (otherUserId) {
          let userData = null;

          // First try to get by document ID
          const userDoc = await db.collection('users').doc(otherUserId).get();
          if (userDoc.exists) {
            userData = userDoc.data() || {};
          } else {
            // If not found, try querying by userId field
            const byUserId = await db
              .collection('users')
              .where('userId', '==', otherUserId)
              .limit(1)
              .get();
            if (!byUserId.empty) {
              userData = byUserId.docs[0].data() || {};
            } else {
              //Last trying to match by uid field 
              const byUid = await db
                .collection('users')
                .where('uid', '==', otherUserId)
                .limit(1)
                .get();
              if (!byUid.empty) {
                userData = byUid.docs[0].data() || {};
              }
            }
          }

          // if User name found
          if (userData) {
            otherUserName = userData.name || userData.displayName || otherUserName;
            otherUserRole = userData.role || otherUserRole;
          }
        }

        //return chat with other user details
        return {
          id: doc.id,
          ...data,
          otherUserId,
          otherUserName,
          otherUserRole,
        };
      })
    );

    // De-duplicate 1:1 chats by otherUserId (keep most recent)
    const toMillis = value => {
      if (!value) return 0;
      if (value instanceof Date) return value.getTime();
      if (typeof value === 'number') return value;
      if (typeof value?.toMillis === 'function') return value.toMillis();
      if (value?.seconds) return value.seconds * 1000;
      return 0;
    };

    const deduped = new Map();
    for (const chat of chats) {
      const isGroup = chat.isGroup === true;
      const otherId = chat.otherUserId || '';
      if (isGroup || !otherId) {
        deduped.set(chat.id, chat);
        continue;
      }

      const key = `dm:${otherId}`;
      const existing = deduped.get(key);
      if (!existing) {
        deduped.set(key, chat);
        continue;
      }

      const existingTime = toMillis(existing.updatedAt || existing.createdAt);
      const currentTime = toMillis(chat.updatedAt || chat.createdAt);
      if (currentTime >= existingTime) {
        deduped.set(key, chat);
      }
    }

    chats = Array.from(deduped.values());

    
    res.json(chats);
  } catch (error) {
    console.error('Error fetching user chats:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// Get chat details by chat ID
async function getChatById(req, res) {
  try {
    let chatId = req.params.id;
    chatId = chatId.trim();
  
    // Fetch chat document by ID
    const chatDoc = await db.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      return res.status(404).json({ error: 'Chat not found' });
    }

    res.json({ id: chatDoc.id, ...chatDoc.data() });
  } catch (error) {
    console.error('Error getting chat:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// Mark chat as read for a user
async function markChatRead(req, res) {
  try {
    let chatId = req.params.id;
    chatId = chatId.trim();

    let { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    userId = userId.trim();

    const chatRef = db.collection('chats').doc(chatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      return res.status(404).json({ error: 'Chat not found' });
    }

    //Update unread count for the user to zero
    const chatData = chatDoc.data() || {};
    const unreadCounts = { ...(chatData.unreadCounts || {}) };
    unreadCounts[userId] = 0;

    await chatRef.update({ unreadCounts });

    //Also mark related alerts as read
    const alertsSnapshot = await db
      .collection('alerts')
      .where('userId', '==', userId)
      .where('chatId', '==', chatId)
      .where('isRead', '==', false)
      .get();

    const batch = db.batch();
    alertsSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, { isRead: true });
    });
    await batch.commit();

    res.json({ ok: true });
  } catch (error) {
    console.error('Error marking chat read:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

export { createChat, getUserChats, getChatById, markChatRead };
