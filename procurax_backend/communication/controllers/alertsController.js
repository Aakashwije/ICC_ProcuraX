import { db } from '../config/firebase.js';

// Get  all alerts for a user
async function getUserAlerts(req, res) {
  try {
    //Reading userId form request params
    let userId = req.params.userId;
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    userId = userId.trim();

    //Fetching alerts from Firestore (from latest to oldest)
    const alertsSnapshot = await db
      .collection('alerts')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .get();

    //Build alert list  with sender names
    const alerts = await Promise.all(
      alertsSnapshot.docs.map(async doc => {
        const data = doc.data();
        const senderId = data.senderId;
        let senderName = senderId;

        //Try to fetch sender name from users collection
        if (senderId) {
          let userData = null;

          // First try to get by document ID
          const userDoc = await db.collection('users').doc(senderId).get();
          if (userDoc.exists) {
            userData = userDoc.data() || {};
          } else {
            // If not found, try querying by userId field
            const byUserId = await db
              .collection('users')
              .where('userId', '==', senderId)
              .limit(1)
              .get();
            if (!byUserId.empty) {
              userData = byUserId.docs[0].data() || {};
            } else {
              //Last trying to match by uid field 
              const byUid = await db
                .collection('users')
                .where('uid', '==', senderId)
                .limit(1)
                .get();
              if (!byUid.empty) {
                userData = byUid.docs[0].data() || {};
              }
            }
          }

          // if User name found
          if (userData) {
            senderName =
              userData.name || userData.displayName || senderName;
          }
        }

        //return alert with sender name and formatted date
        return {
          id: doc.id,
          ...data,
          title: `New message from ${senderName}`,
          createdAt: data.createdAt?.toDate?.() || data.createdAt,
        };
      })
    );

    res.json(alerts);
  } catch (error) {
    console.error('Error fetching alerts:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// Mark alerts read for a user and chat
async function markAlertsRead(req, res) {
  try {
    //Reading userId and chatId form request body
    let { userId, chatId } = req.body;
    if (!userId || !chatId) {
      return res.status(400).json({ error: 'userId and chatId are required' });
    }
    userId = userId.trim();
    chatId = chatId.trim();

    //Find unread alerts for the user and chat
    const alertsSnapshot = await db
      .collection('alerts')
      .where('userId', '==', userId)
      .where('chatId', '==', chatId)
      .where('isRead', '==', false)
      .get();

    //Mark all matching alerts as read
    const batch = db.batch();
    alertsSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, { isRead: true });
    });

    await batch.commit();

    res.json({ ok: true });
  } catch (error) {
    console.error('Error marking alerts read:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

export { getUserAlerts, markAlertsRead };
