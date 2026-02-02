// In memory store to track presence
//key is userId
//value is { lastSeen: Date }

const presenceStore = new Map();

//User is considered online if last heartbeat was within this many milliseconds
const ONLINE_TTL_MS = 30000; //30 seconds

// Called when a user sends a heartbeat to indicate they are online
function heartbeat(req, res) {
  try {
    let { userId } = req.body || {};
    //UserId is mandatory
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    //Normalize userId to string and trim
    userId = String(userId).trim();

    //Update presence store
    presenceStore.set(userId, { lastSeen: new Date() });

    return res.json({ ok: true });
  } catch (error) {
    console.error('Error in heartbeat:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}

//Returns current presence status of a user
function getPresence(req, res) {
  try {
    let userId = req.params.userId;
    //userId is required
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    userId = String(userId).trim();

    //Fetch last known presence record
    const record = presenceStore.get(userId);

    //Normalize lastSeen and determine isOnline
    const lastSeen = record?.lastSeen ? new Date(record.lastSeen) : null;
    
    //User is online if lastSeen is within TTL Window
    const isOnline =
      lastSeen != null && Date.now() - lastSeen.getTime() <= ONLINE_TTL_MS;

    return res.json({
      userId,
      isOnline,
      lastSeen: lastSeen ? lastSeen.toISOString() : null,
    });
  } catch (error) {
    console.error('Error in getPresence:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
}

export { heartbeat, getPresence };
