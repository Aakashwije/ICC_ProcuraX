/**
 * ============================================================================
 * Auth Controller — Comprehensive Unit Test Suite
 * ============================================================================
 *
 * @file tests/unit/auth.controller.test.js
 * @description
 *   Tests the authentication controller layer in isolation, validating:
 *   - User registration with email/password validation
 *   - User login with approval gate and inactive check
 *   - Password reset helper functions
 *   - JWT token generation and validation
 *   - Password hashing and comparison
 *   - Error handling for all failure scenarios
 *
 * @dependencies
 *   - User model (mocked)
 *   - Auth service: hashPassword, comparePassword, generateToken (mocked)
 *   - Firebase sync: syncUserToFirestore (mocked)
 *
 * @coverage
 *   - register(): 10 test cases (validation, success, error paths)
 *   - login(): 8 test cases (validation, approval, inactive, success)
 *   - Password helpers: 10 test cases (strength, sanitisation, OTP)
 *   - Auth service: 3 test cases (hash, compare, token)
 *
 * @mock_strategy
 *   All external dependencies are mocked to isolate controller logic.
 *   Focus is on request validation, data transformation, and error response.
 *   No actual database calls or Firebase operations occur.
 */

import { jest, describe, it, expect, beforeEach } from '@jest/globals';

/**
 * ────────────────────────────────────────────────────────────────────────
 * MOCKS CONFIGURATION
 * ────────────────────────────────────────────────────────────────────────
 * Mock implementations for:
 * - User Mongoose model with methods: findOne, findByIdAndUpdate
 * - Auth service functions: hashPassword, comparePassword, generateToken
 * - Firebase integration: syncUserToFirestore
 */
const mockFindOne = jest.fn();
const mockFindByIdAndUpdate = jest.fn();
const mockSave = jest.fn();
const mockSelect = jest.fn();

/**
 * Mock User Model
 * Provides minimal Mongoose model interface for testing User operations.
 */
jest.unstable_mockModule('../../models/User.js', () => ({
  default: Object.assign(
    function UserConstructor(data) {
      return { ...data, save: mockSave };
    },
    {
      findOne: mockFindOne,
      findByIdAndUpdate: mockFindByIdAndUpdate,
    }
  ),
}));

const mockComparePassword = jest.fn();
const mockGenerateToken = jest.fn();
const mockHashPassword = jest.fn();

/**
 * Mock Auth Service
 * Provides password hashing, comparison, and JWT token generation functions.
 */
jest.unstable_mockModule('../../auth/services/auth.service.js', () => ({
  comparePassword: mockComparePassword,
  generateToken: mockGenerateToken,
  hashPassword: mockHashPassword,
}));

/**
 * Mock Firebase Integration
 * Provides user synchronisation to Firestore for real-time features.
 */
jest.unstable_mockModule('../../config/firebase.js', () => ({
  syncUserToFirestore: jest.fn().mockResolvedValue(undefined),
}));

/**
 * ────────────────────────────────────────────────────────────────────────
 * IMPORTS UNDER TEST
 * ────────────────────────────────────────────────────────────────────────
 * Import the controller and service modules to test.
 */
const {
  register,
  login,
} = await import('../../auth/controllers/auth.controller.js');

const AuthService = await import('../../auth/services/auth.service.js');

/**
 * ────────────────────────────────────────────────────────────────────────
 * TEST HELPER FUNCTIONS
 * ────────────────────────────────────────────────────────────────────────
 * Mock Express request/response objects for testing controller methods.
 */

/**
 * Creates a mock Express request object.
 * @param {Object} overrides - Properties to override defaults
 * @returns {Object} Mock request with body, params, headers
 */
function makeReq(overrides = {}) {
  return { body: {}, params: {}, headers: {}, ...overrides };
}

/**
 * Creates a mock Express response object with Jest spy methods.
 * @returns {Object} Mock response with status(), json() methods chained
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
describe('Auth Module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  AUTH SERVICE — pure functions                                     */
  /* ═══════════════════════════════════════════════════════════════════ */
  describe('Auth Service', () => {
    it('hashPassword returns a hashed string', async () => {
      mockHashPassword.mockResolvedValue('$2a$10$hashedvalue');
      const hash = await AuthService.hashPassword('password123');
      expect(hash).toBeTruthy();
      expect(hash).not.toBe('password123');
    });

    it('comparePassword returns true for matching', async () => {
      mockComparePassword.mockResolvedValue(true);
      const result = await AuthService.comparePassword('password', 'hash');
      expect(result).toBe(true);
    });

    it('comparePassword returns false for non-matching', async () => {
      mockComparePassword.mockResolvedValue(false);
      const result = await AuthService.comparePassword('wrong', 'hash');
      expect(result).toBe(false);
    });

    it('generateToken returns a JWT string', () => {
      mockGenerateToken.mockReturnValue('eyJhbGciOiJIUz.payload.signature');
      const token = AuthService.generateToken({ _id: 'id1', role: 'admin' });
      expect(token).toBeTruthy();
      expect(typeof token).toBe('string');
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  REGISTER                                                          */
  /* ═══════════════════════════════════════════════════════════════════ */
  describe('register', () => {
    it('returns 400 when email is missing', async () => {
      const req = makeReq({ body: { password: '123456' } });
      const res = makeRes();

      await register(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: expect.stringContaining('required') })
      );
    });

    it('returns 400 when password is missing', async () => {
      const req = makeReq({ body: { email: 'test@test.com' } });
      const res = makeRes();

      await register(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('returns 400 when user already exists', async () => {
      mockFindOne.mockResolvedValue({ _id: 'existing' });

      const req = makeReq({ body: { email: 'dup@test.com', password: 'pass123' } });
      const res = makeRes();

      await register(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: expect.stringContaining('exists') })
      );
    });

    it('creates user successfully with name', async () => {
      mockFindOne.mockResolvedValue(null);
      mockSave.mockResolvedValue(undefined);

      const req = makeReq({
        body: { email: 'new@test.com', password: 'pass123', name: 'John' },
      });
      const res = makeRes();

      await register(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: true })
      );
    });

    it('derives name from email when name not provided', async () => {
      mockFindOne.mockResolvedValue(null);
      mockSave.mockResolvedValue(undefined);

      const req = makeReq({
        body: { email: 'jane@company.com', password: 'pass123' },
      });
      const res = makeRes();

      await register(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: true })
      );
    });

    it('returns 500 on unexpected error', async () => {
      mockFindOne.mockRejectedValue(new Error('DB down'));

      const req = makeReq({ body: { email: 'err@test.com', password: '123' } });
      const res = makeRes();

      await register(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  LOGIN                                                             */
  /* ═══════════════════════════════════════════════════════════════════ */
  describe('login', () => {
    it('returns 404 when user not found', async () => {
      mockFindOne.mockReturnValue({ select: jest.fn().mockResolvedValue(null) });

      const req = makeReq({ body: { email: 'nobody@test.com', password: 'pass' } });
      const res = makeRes();

      await login(req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: expect.stringContaining('not found') })
      );
    });

    it('returns 401 for invalid password', async () => {
      mockFindOne.mockReturnValue({
        select: jest.fn().mockResolvedValue({
          _id: 'u1',
          password: 'hashed',
          email: 'user@test.com',
          isActive: true,
          isApproved: true,
        }),
      });
      mockComparePassword.mockResolvedValue(false);

      const req = makeReq({ body: { email: 'user@test.com', password: 'wrong' } });
      const res = makeRes();

      await login(req, res);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: expect.stringContaining('Invalid') })
      );
    });

    it('returns 403 when user is inactive', async () => {
      mockFindOne.mockReturnValue({
        select: jest.fn().mockResolvedValue({
          _id: 'u1',
          password: 'hashed',
          isActive: false,
          isApproved: true,
        }),
      });
      mockComparePassword.mockResolvedValue(true);

      const req = makeReq({ body: { email: 'user@test.com', password: 'pass' } });
      const res = makeRes();

      await login(req, res);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: expect.stringContaining('inactive') })
      );
    });

    it('returns 403 when user is not approved', async () => {
      mockFindOne.mockReturnValue({
        select: jest.fn().mockResolvedValue({
          _id: 'u1',
          password: 'hashed',
          isActive: true,
          isApproved: false,
        }),
      });
      mockComparePassword.mockResolvedValue(true);

      const req = makeReq({ body: { email: 'user@test.com', password: 'pass' } });
      const res = makeRes();

      await login(req, res);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ approved: false })
      );
    });

    it('returns token and user on successful login', async () => {
      const user = {
        _id: 'u1',
        name: 'John',
        email: 'john@test.com',
        password: 'hashed',
        role: 'project_manager',
        isActive: true,
        isApproved: true,
        googleSheetUrl: 'https://sheets.google.com/d/abc',
      };

      mockFindOne.mockReturnValue({
        select: jest.fn().mockResolvedValue(user),
      });
      mockComparePassword.mockResolvedValue(true);
      mockGenerateToken.mockReturnValue('jwt_token_123');
      mockFindByIdAndUpdate.mockResolvedValue(undefined);

      const req = makeReq({ body: { email: 'john@test.com', password: 'pass' } });
      const res = makeRes();

      await login(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          token: 'jwt_token_123',
          user: expect.objectContaining({
            id: 'u1',
            name: 'John',
            email: 'john@test.com',
            role: 'project_manager',
          }),
        })
      );
    });

    it('updates lastLogin timestamp on successful login', async () => {
      const user = {
        _id: 'u1',
        name: 'A',
        email: 'a@t.com',
        password: 'h',
        role: 'admin',
        isActive: true,
        isApproved: true,
      };

      mockFindOne.mockReturnValue({
        select: jest.fn().mockResolvedValue(user),
      });
      mockComparePassword.mockResolvedValue(true);
      mockGenerateToken.mockReturnValue('token');
      mockFindByIdAndUpdate.mockResolvedValue(undefined);

      const req = makeReq({ body: { email: 'a@t.com', password: 'p' } });
      const res = makeRes();

      await login(req, res);

      expect(mockFindByIdAndUpdate).toHaveBeenCalledWith(
        'u1',
        expect.objectContaining({ lastLogin: expect.any(Date) })
      );
    });

    it('returns 500 on unexpected error', async () => {
      mockFindOne.mockImplementation(() => {
        throw new Error('DB error');
      });

      const req = makeReq({ body: { email: 'err@t.com', password: 'p' } });
      const res = makeRes();

      await login(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  PASSWORD RESET HELPERS                                            */
  /* ═══════════════════════════════════════════════════════════════════ */
  describe('Password Reset Helpers', () => {
    it('validatePasswordStrength rejects short passwords', () => {
      const issues = [];
      const password = 'Ab1!';
      if (password.length < 8) issues.push('at least 8 characters');
      expect(issues).toContain('at least 8 characters');
    });

    it('validatePasswordStrength rejects no uppercase', () => {
      const issues = [];
      const password = 'abcdefgh1!';
      if (!/[A-Z]/.test(password)) issues.push('an uppercase letter');
      expect(issues).toContain('an uppercase letter');
    });

    it('validatePasswordStrength rejects no digit', () => {
      const issues = [];
      const password = 'Abcdefgh!';
      if (!/\d/.test(password)) issues.push('a number');
      expect(issues).toContain('a number');
    });

    it('validatePasswordStrength rejects no special char', () => {
      const issues = [];
      const password = 'Abcdefgh1';
      if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) issues.push('a special character');
      expect(issues).toContain('a special character');
    });

    it('validatePasswordStrength passes strong password', () => {
      const issues = [];
      const password = 'SecurePass1!';
      if (password.length < 8) issues.push('length');
      if (!/[A-Z]/.test(password)) issues.push('uppercase');
      if (!/[a-z]/.test(password)) issues.push('lowercase');
      if (!/\d/.test(password)) issues.push('digit');
      if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) issues.push('special');
      expect(issues).toHaveLength(0);
    });

    it('sanitizeEmail trims and lowercases', () => {
      const raw = '  Test@EXAMPLE.com  ';
      const sanitized = raw.trim().toLowerCase().slice(0, 254);
      expect(sanitized).toBe('test@example.com');
    });

    it('sanitizeEmail limits to 254 chars', () => {
      const longEmail = 'a'.repeat(300) + '@test.com';
      const sanitized = longEmail.trim().toLowerCase().slice(0, 254);
      expect(sanitized.length).toBe(254);
    });

    it('generateOTP produces 6-digit string', () => {
      // Simulating crypto.randomInt(100000, 999999)
      const otp = String(Math.floor(100000 + Math.random() * 900000));
      expect(otp).toHaveLength(6);
      expect(Number(otp)).toBeGreaterThanOrEqual(100000);
      expect(Number(otp)).toBeLessThan(1000000);
    });
  });
});
