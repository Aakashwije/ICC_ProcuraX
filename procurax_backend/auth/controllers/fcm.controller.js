import User from "../../models/User.js";

/**
 * POST /auth/fcm-token
 * Body: { fcmToken: string }
 *
 * Stores the device FCM token for the authenticated user.
 * Supports multiple devices — each token is stored once.
 */
export const registerFcmToken = async (req, res) => {
  try {
    const userId = req.userId;
    const { fcmToken } = req.body;

    if (!fcmToken || typeof fcmToken !== "string") {
      return res.status(400).json({ error: "fcmToken is required" });
    }

    // Add the token if it doesn't already exist (avoids duplicates)
    await User.findByIdAndUpdate(userId, {
      $addToSet: { fcmTokens: fcmToken },
    });

    console.log(`[FCM] Token registered for user ${userId}`);
    res.json({ success: true });
  } catch (error) {
    console.error("[FCM] Error registering token:", error);
    res.status(500).json({ error: "Failed to register FCM token" });
  }
};

/**
 * DELETE /auth/fcm-token
 * Body: { fcmToken: string } (optional — if omitted, removes all tokens)
 *
 * Removes a specific FCM token (on logout) or all tokens.
 */
export const unregisterFcmToken = async (req, res) => {
  try {
    const userId = req.userId;
    const { fcmToken } = req.body;

    if (fcmToken) {
      // Remove specific token (single device logout)
      await User.findByIdAndUpdate(userId, {
        $pull: { fcmTokens: fcmToken },
      });
    } else {
      // Remove all tokens (full logout)
      await User.findByIdAndUpdate(userId, {
        $set: { fcmTokens: [] },
      });
    }

    console.log(`[FCM] Token unregistered for user ${userId}`);
    res.json({ success: true });
  } catch (error) {
    console.error("[FCM] Error unregistering token:", error);
    res.status(500).json({ error: "Failed to unregister FCM token" });
  }
};
