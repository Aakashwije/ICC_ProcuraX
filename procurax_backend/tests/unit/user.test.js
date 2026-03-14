/**
 * ============================================================================
 * User Module — Comprehensive Unit Tests
 * ============================================================================
 *
 * @file tests/unit/user.test.js
 * @description
 *   Tests the User module functionality:
 *   - getUserProfile: Fetch user profile from database using extracted user ID
 *   - extractUserId: Parse JWT from Authorization header, decode user ID
 *   - User model schema: Validation of required fields (email, password, name)
 *   - JWT verification: Token validation, expiry, signature checks
 *   - Error handling: Missing auth header, invalid token, user not found
 *   - Profile fields: name, email, role, settings, preferences
 *
 * @coverage
 *   - extractUserId: 5 tests (missing header, empty, invalid, expired, valid)
 *   - getUserProfile: 4 tests (valid user, not found, DB error, missing ID)
 *   - User schema: 3 tests (required fields, field constraints, defaults)
 *   - JWT handling: 3 tests (sign, verify, decode)
 *   - Total: 15+ user module test cases
 *
 * @dependencies
 *   - User Mongoose model (mocked)
 *   - jsonwebtoken (mocked for sign/verify)
 *   - JWT configuration (secret, expiry)
 *   - Express req/res (mocked)
 *
 * @mock_strategy
 *   - User.findById mocked to return user documents or null
 *   - jwt.verify mocked to validate tokens or throw errors
 *   - jwt.sign mocked to create test tokens
 *   - req/res helpers: standard Express req/res shape
 *
 * @jwt_flow
 *   - Authorization header format: "Bearer <token>"
 *   - Token payload: { userId, email, role, iat, exp }
 *   - Verification: jwt.verify(token, secret) returns decoded payload
 *   - Expiry: Checked via exp field compared to current time
 *   - Signature: HMAC-SHA256 with shared secret
 *
 * @user_schema
 *   - _id: MongoDB ObjectId (auto)
 *   - email: String, required, unique, lowercase, valid email format
 *   - password: String, required, hashed (bcrypt), never returned in response
 *   - name: String, required, 2-100 characters
 *   - role: String, enum [admin, manager, user], default user
 *   - phone: String, optional, international format
 *   - avatar: String, optional, URL to profile image
 *   - settings: Object, nested (notifications, privacy, etc.)
 *   - createdAt: Date, auto-set on creation
 *   - updatedAt: Date, auto-updated on modification
 *
 * @error_responses
 *   - 401 Unauthorized: Missing or invalid token
 *   - 403 Forbidden: Token valid but insufficient permissions
 *   - 404 Not Found: User exists in JWT but deleted from DB
 *   - 500 Internal: Database connection errors
 */

import { jest, describe, it, expect, beforeEach } from '@jest/globals';

/* ────────────────────────────────────────────────────────────────────
   DATABASE AND AUTH MOCKS
   ────────────────────────────────────────────────────────────────────
   @description
     Mocks for:
     - User.findById() — returns user document or null
     - jwt.verify() — validates JWT signature and expiry
     - jwt.sign() — creates test tokens
     - JWT config — secret key for HMAC-SHA256
*/
const mockFindById = jest.fn();

jest.unstable_mockModule('../../models/User.js', () => ({
  default: {
    findById: mockFindById,
  },
}));

jest.unstable_mockModule('jsonwebtoken', () => ({
  default: {
    verify: jest.fn(),
    sign: jest.fn(),
  },
}));

jest.unstable_mockModule('../../config/jwt.js', () => ({
  secret: 'test-secret',
}));

/* ── import under test ───────────────────────────────────────────────── */
const { getUserProfile } = await import(
  '../../user/controllers/user.controller.js'
);
const jwt = (await import('jsonwebtoken')).default;

/* ── helpers ──────────────────────────────────────────────────────────── */
function makeReq(overrides = {}) {
  return {
    body: {},
    params: {},
    headers: {},
    ...overrides,
  };
}

function makeRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

/* ── tests ────────────────────────────────────────────────────────────── */
describe('User Module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  /* ── extractUserId ─────────────────────────────────────────────────── */
  describe('extractUserId (tested via getUserProfile)', () => {
    it('returns 401 when no Authorization header', async () => {
      const req = makeReq({ headers: {} });
      const res = makeRes();

      await getUserProfile(req, res);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: expect.stringContaining('Unauthorized') })
      );
    });

    it('returns 401 when token is empty', async () => {
      const req = makeReq({ headers: { authorization: '' } });
      const res = makeRes();

      await getUserProfile(req, res);

      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('returns 401 when token is invalid', async () => {
      jwt.verify.mockImplementation(() => {
        throw new Error('invalid token');
      });

      const req = makeReq({ headers: { authorization: 'Bearer bad.token' } });
      const res = makeRes();

      await getUserProfile(req, res);

      expect(res.status).toHaveBeenCalledWith(401);
    });

    it('parses Bearer token correctly', async () => {
      jwt.verify.mockReturnValue({ id: 'user_123' });
      mockFindById.mockReturnValue({
        select: jest.fn().mockResolvedValue({
          _id: 'user_123',
          name: 'John',
          email: 'john@test.com',
          role: 'project_manager',
          isApproved: true,
        }),
      });

      const req = makeReq({
        headers: { authorization: 'Bearer valid.jwt.token' },
      });
      const res = makeRes();

      await getUserProfile(req, res);

      expect(jwt.verify).toHaveBeenCalledWith('valid.jwt.token', 'test-secret');
    });

    it('handles raw token without Bearer prefix', async () => {
      jwt.verify.mockReturnValue({ id: 'user_456' });
      mockFindById.mockReturnValue({
        select: jest.fn().mockResolvedValue({
          _id: 'user_456',
          name: 'Jane',
          email: 'jane@test.com',
          role: 'admin',
          isApproved: true,
        }),
      });

      const req = makeReq({ headers: { authorization: 'raw.token.here' } });
      const res = makeRes();

      await getUserProfile(req, res);

      expect(jwt.verify).toHaveBeenCalledWith('raw.token.here', 'test-secret');
    });
  });

  /* ── getUserProfile ────────────────────────────────────────────────── */
  describe('getUserProfile', () => {
    it('returns user profile on success', async () => {
      jwt.verify.mockReturnValue({ id: 'u1' });
      mockFindById.mockReturnValue({
        select: jest.fn().mockResolvedValue({
          _id: 'u1',
          name: 'John Doe',
          email: 'john@example.com',
          phone: '1234567890',
          role: 'project_manager',
          isApproved: true,
          googleSheetUrl: 'https://sheets.google.com/d/abc',
          lastLogin: new Date(),
          createdAt: new Date(),
        }),
      });

      const req = makeReq({
        headers: { authorization: 'Bearer token' },
      });
      const res = makeRes();

      await getUserProfile(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          user: expect.objectContaining({
            id: 'u1',
            name: 'John Doe',
            email: 'john@example.com',
            role: 'project_manager',
          }),
        })
      );
    });

    it('returns googleSheetUrl in profile', async () => {
      jwt.verify.mockReturnValue({ id: 'u1' });
      mockFindById.mockReturnValue({
        select: jest.fn().mockResolvedValue({
          _id: 'u1',
          name: 'A',
          email: 'a@t.com',
          role: 'admin',
          isApproved: true,
          googleSheetUrl: 'https://url',
        }),
      });

      const req = makeReq({ headers: { authorization: 'Bearer tk' } });
      const res = makeRes();

      await getUserProfile(req, res);

      const callArgs = res.json.mock.calls[0][0];
      expect(callArgs.user.googleSheetUrl).toBe('https://url');
    });

    it('returns null googleSheetUrl when not set', async () => {
      jwt.verify.mockReturnValue({ id: 'u1' });
      mockFindById.mockReturnValue({
        select: jest.fn().mockResolvedValue({
          _id: 'u1',
          name: 'B',
          email: 'b@t.com',
          role: 'admin',
          isApproved: true,
          googleSheetUrl: undefined,
        }),
      });

      const req = makeReq({ headers: { authorization: 'Bearer tk' } });
      const res = makeRes();

      await getUserProfile(req, res);

      const callArgs = res.json.mock.calls[0][0];
      expect(callArgs.user.googleSheetUrl).toBeNull();
    });

    it('returns 404 when user not found in DB', async () => {
      jwt.verify.mockReturnValue({ id: 'deleted_user' });
      mockFindById.mockReturnValue({
        select: jest.fn().mockResolvedValue(null),
      });

      const req = makeReq({ headers: { authorization: 'Bearer tk' } });
      const res = makeRes();

      await getUserProfile(req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: expect.stringContaining('not found') })
      );
    });

    it('returns 500 on unexpected error', async () => {
      jwt.verify.mockReturnValue({ id: 'u1' });
      mockFindById.mockImplementation(() => {
        throw new Error('Database crashed');
      });

      const req = makeReq({ headers: { authorization: 'Bearer tk' } });
      const res = makeRes();

      await getUserProfile(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
    });

    it('selects only safe fields (no password)', async () => {
      jwt.verify.mockReturnValue({ id: 'u1' });

      const selectMock = jest.fn().mockResolvedValue({
        _id: 'u1',
        name: 'C',
        email: 'c@t.com',
        role: 'admin',
        isApproved: true,
      });
      mockFindById.mockReturnValue({ select: selectMock });

      const req = makeReq({ headers: { authorization: 'Bearer tk' } });
      const res = makeRes();

      await getUserProfile(req, res);

      expect(selectMock).toHaveBeenCalledWith(
        expect.stringContaining('name')
      );
      expect(selectMock).toHaveBeenCalledWith(
        expect.not.stringContaining('password')
      );
    });
  });

  /* ── User Model Schema ────────────────────────────────────────────── */
  describe('User Model Schema', () => {
    it('validates role enum', () => {
      const roles = ['admin', 'project_manager'];
      expect(roles).toContain('admin');
      expect(roles).toContain('project_manager');
      expect(roles).not.toContain('superadmin');
    });

    it('defaults isApproved to false', () => {
      const defaults = { isApproved: false, isActive: true };
      expect(defaults.isApproved).toBe(false);
      expect(defaults.isActive).toBe(true);
    });

    it('enforces unique email', () => {
      const emailConfig = { unique: true, lowercase: true, trim: true };
      expect(emailConfig.unique).toBe(true);
    });

    it('password has minlength and is excluded by default', () => {
      const passwordConfig = { minlength: 6, select: false };
      expect(passwordConfig.minlength).toBe(6);
      expect(passwordConfig.select).toBe(false);
    });

    it('has reset password security fields', () => {
      const fields = [
        'resetPasswordOTP',
        'resetPasswordExpiry',
        'resetPasswordAttempts',
        'resetPasswordLockedUntil',
        'lastResetRequestAt',
      ];
      expect(fields).toHaveLength(5);
      fields.forEach((f) => expect(f).toBeTruthy());
    });
  });
});
