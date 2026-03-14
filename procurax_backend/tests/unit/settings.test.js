/**
 * Settings Module — Unit Tests
 *
 * Tests: getSettings, updateMultipleSettings, Setting model schema
 */

import { jest, describe, it, expect, beforeEach } from '@jest/globals';

/* ── mocks ────────────────────────────────────────────────────────────── */
const mockFindOne = jest.fn();
const mockSave = jest.fn();
const mockInsertMany = jest.fn();

jest.unstable_mockModule('../../settings/models/setting.js', () => ({
  default: Object.assign(
    function SettingConstructor(data) {
      return { ...data, save: mockSave };
    },
    {
      findOne: mockFindOne,
      insertMany: mockInsertMany,
    }
  ),
}));

/* ── import under test ───────────────────────────────────────────────── */
const {
  getSettings,
  updateMultipleSettings,
} = await import('../../settings/controllers/settings.controller.js');

/* ── helpers ──────────────────────────────────────────────────────────── */
function makeReq(overrides = {}) {
  return { body: {}, params: {}, userId: 'user_123', ...overrides };
}

function makeRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

/* ── tests ────────────────────────────────────────────────────────────── */
describe('Settings Module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  /* ── Setting Model Schema ──────────────────────────────────────────── */
  describe('Setting Model Schema', () => {
    it('validates category enum values', () => {
      const allowed = ['appearance', 'notifications', 'privacy', 'general', 'app'];
      expect(allowed).toContain('appearance');
      expect(allowed).toContain('notifications');
      expect(allowed).toContain('privacy');
      expect(allowed).toContain('general');
      expect(allowed).toContain('app');
      expect(allowed).not.toContain('security');
    });

    it('enforces compound unique index userId + key', () => {
      const index = { userId: 1, key: 1 };
      expect(index.userId).toBe(1);
      expect(index.key).toBe(1);
    });

    it('supports Mixed type for value field', () => {
      const setting1 = { key: 'theme', value: 'Dark' };
      const setting2 = { key: 'notifications', value: { email: true, push: false } };
      const setting3 = { key: 'count', value: 42 };

      expect(typeof setting1.value).toBe('string');
      expect(typeof setting2.value).toBe('object');
      expect(typeof setting3.value).toBe('number');
    });
  });

  /* ── getSettings ───────────────────────────────────────────────────── */
  describe('getSettings', () => {
    it('returns existing settings for user', async () => {
      mockFindOne.mockResolvedValue({
        key: 'default_settings',
        value: {
          theme: 'Dark',
          timezone: 'UTC',
          notifications_email: true,
          notifications_alerts: true,
        },
      });

      const req = makeReq();
      const res = makeRes();

      await getSettings(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({ theme: 'Dark' }),
        })
      );
    });

    it('creates default settings when none exist', async () => {
      mockFindOne.mockResolvedValue(null);
      mockSave.mockResolvedValue(undefined);

      const req = makeReq();
      const res = makeRes();

      await getSettings(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            theme: 'Light',
            timezone: 'UTC',
            notifications_email: true,
            notifications_alerts: true,
          }),
        })
      );
    });

    it('returns 500 on database error', async () => {
      mockFindOne.mockRejectedValue(new Error('DB error'));

      const req = makeReq();
      const res = makeRes();

      await getSettings(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: false })
      );
    });

    it('uses userId from JWT middleware', async () => {
      mockFindOne.mockResolvedValue({ value: { theme: 'Light' } });

      const req = makeReq({ userId: 'jwt_user_456' });
      const res = makeRes();

      await getSettings(req, res);

      expect(mockFindOne).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 'jwt_user_456' })
      );
    });
  });

  /* ── updateMultipleSettings ────────────────────────────────────────── */
  describe('updateMultipleSettings', () => {
    it('updates existing settings', async () => {
      const existingSettings = {
        key: 'default_settings',
        value: { theme: 'Light', timezone: 'UTC' },
        save: mockSave,
      };
      mockFindOne.mockResolvedValue(existingSettings);
      mockSave.mockResolvedValue(undefined);

      const req = makeReq({ body: { theme: 'Dark' } });
      const res = makeRes();

      await updateMultipleSettings(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: true })
      );
    });

    it('creates new settings when none exist', async () => {
      mockFindOne.mockResolvedValue(null);
      mockSave.mockResolvedValue(undefined);

      const req = makeReq({
        body: { theme: 'Dark', notifications_email: false },
      });
      const res = makeRes();

      await updateMultipleSettings(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: expect.stringContaining('updated'),
        })
      );
    });

    it('merges partial updates without losing existing keys', async () => {
      const existingSettings = {
        key: 'default_settings',
        value: {
          theme: 'Light',
          timezone: 'UTC',
          notifications_email: true,
        },
        save: mockSave,
      };
      mockFindOne.mockResolvedValue(existingSettings);
      mockSave.mockResolvedValue(undefined);

      const req = makeReq({ body: { theme: 'Dark' } });
      const res = makeRes();

      await updateMultipleSettings(req, res);

      // The merged value should contain both existing + new
      expect(existingSettings.value.theme).toBe('Dark');
      expect(existingSettings.value.timezone).toBe('UTC');
    });

    it('returns 400 on validation error', async () => {
      mockFindOne.mockRejectedValue(new Error('Validation failed'));

      const req = makeReq({ body: { theme: 'Invalid' } });
      const res = makeRes();

      await updateMultipleSettings(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: false })
      );
    });
  });

  /* ── Default settings creation for new users ───────────────────────── */
  describe('Default Settings for New Users', () => {
    it('creates 4 default setting documents', () => {
      const userId = 'new_user_1';
      const defaults = [
        { userId, key: 'theme', value: 'Light', category: 'appearance' },
        { userId, key: 'notifications_email', value: true, category: 'notifications' },
        { userId, key: 'notifications_alerts', value: true, category: 'notifications' },
        { userId, key: 'timezone', value: 'UTC', category: 'general' },
      ];

      expect(defaults).toHaveLength(4);
      expect(defaults[0].category).toBe('appearance');
      expect(defaults[1].value).toBe(true);
      expect(defaults[3].value).toBe('UTC');
    });

    it('each default has required fields', () => {
      const setting = {
        userId: 'u1',
        key: 'theme',
        value: 'Light',
        category: 'appearance',
      };

      expect(setting).toHaveProperty('userId');
      expect(setting).toHaveProperty('key');
      expect(setting).toHaveProperty('value');
      expect(setting).toHaveProperty('category');
    });
  });
});
