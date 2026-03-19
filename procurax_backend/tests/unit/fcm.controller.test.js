/**
 * ============================================================================
 * FCM Controller — Unit Tests
 * ============================================================================
 *
 * @file tests/unit/fcm.controller.test.js
 * @description
 *   Tests the FCM (Firebase Cloud Messaging) controller in isolation:
 *   - Register FCM token: Associates device with user
 *   - Unregister FCM token: Removes device from user's token list
 *   - Error handling: Missing token, invalid user, database failures
 *   - Token deduplication: Same token not added twice
 *   - Selective token removal: Remove specific token or all tokens
 *
 * @coverage
 *   - registerFcmToken: 4 test cases (success, missing token, DB error, duplicate)
 *   - unregisterFcmToken: 4 test cases (success, specific token, all tokens, not found)
 *   - Total: 8 test cases
 *
 * @dependencies
 *   - User model (mocked with findByIdAndUpdate)
 *   - Request/Response objects (mocked Express)
 *   - Auth middleware (pre-authentication, mocked via req.user)
 *
 * @mock_strategy
 *   - Isolate controller logic from database layer
 *   - Mock User.findByIdAndUpdate to simulate database operations
 *   - Mock req.user (set by authMiddleware) to simulate authenticated user
 *   - Focus on request validation and response formatting
 */

import { jest, describe, it, expect, beforeEach } from '@jest/globals';

/**
 * ────────────────────────────────────────────────────────────────────────
 * MOCK SETUP
 * ────────────────────────────────────────────────────────────────────────
 */

const mockFindByIdAndUpdate = jest.fn();

/**
 * Mock User Model
 */
jest.unstable_mockModule('../../models/User.js', () => ({
  default: {
    findByIdAndUpdate: mockFindByIdAndUpdate,
  },
}));

/**
 * Import the controller under test
 */
const {
  registerFcmToken,
  unregisterFcmToken,
} = await import('../../auth/controllers/fcm.controller.js');

/**
 * ────────────────────────────────────────────────────────────────────────
 * TEST HELPERS
 * ────────────────────────────────────────────────────────────────────────
 */

/**
 * Create mock Express request with authenticated user
 */
function makeReq(userId, overrides = {}) {
  return {
    userId,
    body: {},
    ...overrides,
  };
}

/**
 * Create mock Express response with spy methods
 */
function makeRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

/**
 * ────────────────────────────────────────────────────────────────────────
 * TEST SUITE
 * ────────────────────────────────────────────────────────────────────────
 */

describe('FCM Controller', () => {
  const USER_ID = '507f1f77bcf86cd799439011';
  const TOKEN_1 = 'device_token_abc123';
  const TOKEN_2 = 'device_token_xyz789';

  beforeEach(() => {
    jest.clearAllMocks();
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  REGISTER FCM TOKEN ENDPOINT                                       */
  /* ═══════════════════════════════════════════════════════════════════ */

  describe('POST /auth/fcm-token - registerFcmToken', () => {
    it('should register a new FCM token successfully', async () => {
      const req = makeReq(USER_ID, {
        body: { fcmToken: TOKEN_1 },
      });
      const res = makeRes();

      const updatedUser = {
        _id: USER_ID,
        fcmTokens: [TOKEN_1],
      };

      mockFindByIdAndUpdate.mockResolvedValue(updatedUser);

      await registerFcmToken(req, res);

      expect(mockFindByIdAndUpdate).toHaveBeenCalledWith(USER_ID, {
        $addToSet: { fcmTokens: TOKEN_1 },
      });

      expect(res.json).toHaveBeenCalledWith({ success: true });
    });

    it('should not add duplicate tokens (idempotent with $addToSet)', async () => {
      const req = makeReq(USER_ID, {
        body: { fcmToken: TOKEN_1 },
      });
      const res = makeRes();

      const updatedUser = {
        _id: USER_ID,
        fcmTokens: [TOKEN_1],
      };

      mockFindByIdAndUpdate.mockResolvedValue(updatedUser);

      // First registration
      await registerFcmToken(req, res);
      // Second registration with same token
      await registerFcmToken(req, res);

      // $addToSet prevents duplicates - should be called twice
      expect(mockFindByIdAndUpdate).toHaveBeenCalledTimes(2);
      expect(mockFindByIdAndUpdate).toHaveBeenLastCalledWith(USER_ID, {
        $addToSet: { fcmTokens: TOKEN_1 },
      });
      expect(res.json).toHaveBeenCalledWith({ success: true });
    });

    it('should return 400 if fcmToken is missing', async () => {
      const req = makeReq(USER_ID, {
        body: {}, // No token provided
      });
      const res = makeRes();

      await registerFcmToken(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: 'fcmToken is required',
      });
      expect(mockFindByIdAndUpdate).not.toHaveBeenCalled();
    });

    it('should handle database errors gracefully', async () => {
      const req = makeReq(USER_ID, {
        body: { fcmToken: TOKEN_1 },
      });
      const res = makeRes();

      mockFindByIdAndUpdate.mockRejectedValue(
        new Error('Database connection failed')
      );

      await registerFcmToken(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Failed to register FCM token',
      });
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  UNREGISTER FCM TOKEN ENDPOINT                                     */
  /* ═══════════════════════════════════════════════════════════════════ */

  describe('DELETE /auth/fcm-token - unregisterFcmToken', () => {
    it('should unregister a specific FCM token', async () => {
      const req = makeReq(USER_ID, {
        body: { fcmToken: TOKEN_1 },
      });
      const res = makeRes();

      const updatedUser = {
        _id: USER_ID,
        fcmTokens: [TOKEN_2],
      };

      mockFindByIdAndUpdate.mockResolvedValue(updatedUser);

      await unregisterFcmToken(req, res);

      expect(mockFindByIdAndUpdate).toHaveBeenCalledWith(USER_ID, {
        $pull: { fcmTokens: TOKEN_1 },
      });

      expect(res.json).toHaveBeenCalledWith({ success: true });
    });

    it('should clear all tokens when no specific token provided', async () => {
      const req = makeReq(USER_ID, {
        body: {}, // No token provided
      });
      const res = makeRes();

      const updatedUser = {
        _id: USER_ID,
        fcmTokens: [],
      };

      mockFindByIdAndUpdate.mockResolvedValue(updatedUser);

      await unregisterFcmToken(req, res);

      expect(mockFindByIdAndUpdate).toHaveBeenCalledWith(USER_ID, {
        $set: { fcmTokens: [] },
      });

      expect(res.json).toHaveBeenCalledWith({ success: true });
    });

    it('should handle token not found in user list (no-op)', async () => {
      const req = makeReq(USER_ID, {
        body: { fcmToken: 'non_existent_token' },
      });
      const res = makeRes();

      const updatedUser = {
        _id: USER_ID,
        fcmTokens: [TOKEN_1], // Token not removed because it wasn't in list
      };

      mockFindByIdAndUpdate.mockResolvedValue(updatedUser);

      await unregisterFcmToken(req, res);

      // Should still succeed even if token wasn't in list
      expect(res.json).toHaveBeenCalledWith({ success: true });
      expect(mockFindByIdAndUpdate).toHaveBeenCalledWith(USER_ID, {
        $pull: { fcmTokens: 'non_existent_token' },
      });
    });

    it('should handle database errors during unregister', async () => {
      const req = makeReq(USER_ID, {
        body: { fcmToken: TOKEN_1 },
      });
      const res = makeRes();

      mockFindByIdAndUpdate.mockRejectedValue(
        new Error('Connection timeout')
      );

      await unregisterFcmToken(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Failed to unregister FCM token',
      });
    });
  });
});
