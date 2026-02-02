// In memory store to track typing status
// key is chatId
// value is a Map where
//    key is userId
//    value is { isTyping: boolean, updatedAt: Date }

const typingStore = new Map();

//Typing status expires after this time
// Prevents users getting stuck as "typing"
const TYPING_TTL_MS = 80000; // 8 seconds

//Update typing status for a user in a chat
function setTyping(req, res) {
  try {
    let { chatId, userId, isTyping } = req.body || {};

    // All fields are required
    if (!chatId || !userId || typeof isTyping !== 'boolean') {
      return res.status(400).json({ error: 'chatId, userId, isTyping are required' });
    }

    //Normalize Ids
    chatId = String(chatId).trim();
    userId = String(userId).trim();

    // Create chat map if it doesn't exist
    if (!typingStore.has(chatId)) {
      typingStore.set(chatId, new Map());
    }

    //Store typing status with timestamp
    const chatTyping = typingStore.get(chatId);
    chatTyping.set(userId, {
      isTyping,
      updatedAt: new Date(),
    });

    return res.json({ ok: true });
  } catch (error) {
    console.error('Error in setTyping:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}

//Get typing status for a user in a chat
function getTyping(req, res) {
  try {
    let { chatId, userId } = req.query || {};

    // chatId and userId are required
    if (!chatId || !userId) {
      return res.status(400).json({ error: 'chatId and userId are required' });
    }

    chatId = String(chatId).trim();
    userId = String(userId).trim();

    //Fetch typing record
    const chatTyping = typingStore.get(chatId);
    const record = chatTyping?.get(userId) || null;

    // Normalize updatedAt and determine isTyping
    const updatedAt = record?.updatedAt ? new Date(record.updatedAt) : null;

    // User is considered typing if isTyping is true and updatedAt is within TTL
    const isTyping =
      record?.isTyping === true &&
      updatedAt != null &&
      Date.now() - updatedAt.getTime() <= TYPING_TTL_MS;

    // Return typing status
    return res.json({
      chatId,
      userId,
      isTyping,
      updatedAt: updatedAt ? updatedAt.toISOString() : null,
    });
  } catch (error) {
    console.error('Error in getTyping:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}

export { setTyping, getTyping };
