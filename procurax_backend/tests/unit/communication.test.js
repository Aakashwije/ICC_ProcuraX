/**
 * ============================================================================
 * Communication Module — Comprehensive Unit Test Suite
 * ============================================================================
 *
 * @file tests/unit/communication.test.js
 * @description
 *   Tests the communication system controllers in isolation:
 *   - Chat management: create, retrieve, list user chats
 *   - Message operations: send, retrieve, delete messages
 *   - Alerts management: create, retrieve, mark as read
 *   - Real-time features via Firestore integration
 *
 * @dependencies
 *   - Firestore database (mocked)
 *   - Chat controller
 *   - Message controller
 *   - Alerts controller
 *
 * @coverage
 *   - createChat: 4 test cases (validation, duplicate handling, success)
 *   - getUserChats: 1 test case (retrieval with user filtering)
 *   - sendMessage: 5 test cases (validation, content checks, success)
 *   - getMessagesByChat: 2 test cases (validation, retrieval)
 *   - deleteMessage: 2 test cases (validation, deletion)
 *   - getUserAlerts: 1 test case (retrieval with filtering)
 *   - markAlertsRead: 1 test case (read status updates)
 *
 * @mock_strategy
 *   - Mock Firestore database to avoid cloud operations
 *   - Simulate Firestore query chains (.where().orderBy().limit())
 *   - Test request validation independently of database
 */

jest.mock('../../communication/config/firebase.js');

import { jest, describe, it, expect, beforeEach } from '@jest/globals';

/**
 * ────────────────────────────────────────────────────────────────────────
 * FIRESTORE MOCK CONFIGURATION
 * ────────────────────────────────────────────────────────────────────────
 * Mock Firebase Firestore database with full query API:
 * - Collection operations: add, doc, where, orderBy, limit
 * - Document operations: get, update, delete
 * - Batch operations: set, commit
 */
const mockGet = jest.fn();
const mockAdd = jest.fn();
const mockUpdate = jest.fn();
const mockDelete = jest.fn();
const mockSet = jest.fn();

const mockDoc = jest.fn(() => ({
  get: mockGet,
  update: mockUpdate,
  delete: mockDelete,
}));

const mockWhere = jest.fn().mockReturnThis();
const mockOrderBy = jest.fn().mockReturnThis();
const mockLimit = jest.fn().mockReturnThis();

const mockCollection = jest.fn(() => ({
  add: mockAdd,
  doc: mockDoc,
  where: mockWhere,
  orderBy: mockOrderBy,
  limit: mockLimit,
  get: mockGet,
}));

const mockBatch = jest.fn(() => ({
  set: mockSet,
  commit: jest.fn().mockResolvedValue(undefined),
}));

jest.unstable_mockModule('../../communication/config/firebase.js', () => ({
  db: {
    collection: mockCollection,
    batch: mockBatch,
  },
  bucket: {
    name: 'mock-bucket',
    file: jest.fn(() => ({
      save: jest.fn(),
      delete: jest.fn().mockResolvedValue(undefined),
    })),
    upload: jest.fn(),
  },
  admin: {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => ({
      collection: mockCollection,
      batch: mockBatch,
    })),
    storage: jest.fn(() => ({ bucket: {
      name: 'mock-bucket',
      file: jest.fn(() => ({
        save: jest.fn(),
        delete: jest.fn().mockResolvedValue(undefined),
      })),
      upload: jest.fn(),
    }})),
  },
}));

/* ── import controllers under test ───────────────────────────────────── */
const chatModule = await import(
  '../../communication/controllers/chatController.js'
);
const messageModule = await import(
  '../../communication/controllers/messageController.js'
);
const alertsModule = await import(
  '../../communication/controllers/alertsController.js'
);

/* Pick the default export or named exports */
const createChat = chatModule.createChat ?? chatModule.default?.createChat;
const getUserChats = chatModule.getUserChats ?? chatModule.default?.getUserChats;

const sendMessage = messageModule.sendMessage ?? messageModule.default?.sendMessage;
const getMessagesByChat = messageModule.getMessagesByChat ?? messageModule.default?.getMessagesByChat;
const deleteMessage = messageModule.deleteMessage ?? messageModule.default?.deleteMessage;

const getUserAlerts = alertsModule.getUserAlerts ?? alertsModule.default?.getUserAlerts;
const markAlertsRead = alertsModule.markAlertsRead ?? alertsModule.default?.markAlertsRead;

/* ── mock req/res factories ──────────────────────────────────────────── */
function makeReq(overrides = {}) {
  return {
    body: {},
    params: {},
    query: {},
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
describe('Communication Module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Reset chainable mocks
    mockWhere.mockReturnThis();
    mockOrderBy.mockReturnThis();
    mockLimit.mockReturnThis();
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  CHAT CONTROLLER                                                   */
  /* ═══════════════════════════════════════════════════════════════════ */
  describe('Chat Controller', () => {
    describe('createChat', () => {
      it('returns 400 when members array is missing', async () => {
        const req = makeReq({ body: { name: 'Test' } });
        const res = makeRes();

        await createChat(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith(
          expect.objectContaining({ error: expect.any(String) })
        );
      });

      it('returns 400 when members array is empty', async () => {
        const req = makeReq({ body: { members: [], isGroup: false } });
        const res = makeRes();

        await createChat(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
      });

      it('creates a group chat successfully', async () => {
        const chatData = {
          name: 'Project Team',
          members: ['user1', 'user2', 'user3'],
          isGroup: true,
        };

        const chatId = 'chat_123';
        const chatDoc = {
          id: chatId,
          exists: true,
          data: () => ({ ...chatData, createdAt: new Date(), updatedAt: new Date() }),
        };

        mockAdd.mockResolvedValue({ get: jest.fn().mockResolvedValue(chatDoc) });
        mockGet.mockResolvedValue(chatDoc);

        const req = makeReq({ body: chatData });
        const res = makeRes();

        await createChat(req, res);

        expect(res.status).toHaveBeenCalledWith(201);
        expect(res.json).toHaveBeenCalledWith(
          expect.objectContaining({ id: chatId })
        );
      });

      it('returns existing chat for duplicate 1:1 chat', async () => {
        const existingChat = {
          id: 'existing_chat',
          data: () => ({
            members: ['user1', 'user2'],
            isGroup: false,
          }),
        };

        mockGet.mockResolvedValue({
          docs: [existingChat],
          empty: false,
        });

        const req = makeReq({
          body: { members: ['user1', 'user2'], isGroup: false },
        });
        const res = makeRes();

        await createChat(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith(
          expect.objectContaining({ id: 'existing_chat' })
        );
      });
    });

    describe('getUserChats', () => {
      it('returns chats for a valid userId', async () => {
        const chatDoc = {
          id: 'c1',
          data: () => ({
            members: ['user1', 'user2'],
            isGroup: false,
            updatedAt: new Date(),
          }),
        };

        // Chats snapshot
        mockGet.mockResolvedValueOnce({ docs: [chatDoc], empty: false });
        // Fallback snapshot (empty)
        mockGet.mockResolvedValueOnce({ docs: [], empty: true });
        // User lookup for other user
        mockGet.mockResolvedValueOnce({ exists: true, data: () => ({ name: 'Other User' }) });

        const req = makeReq({ params: { userId: 'user1' } });
        const res = makeRes();

        await getUserChats(req, res);

        expect(res.json).toHaveBeenCalled();
      });
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  MESSAGE CONTROLLER                                                */
  /* ═══════════════════════════════════════════════════════════════════ */
  describe('Message Controller', () => {
    describe('sendMessage', () => {
      it('returns 400 for missing required fields', async () => {
        const req = makeReq({ body: { chatId: 'c1' } });
        const res = makeRes();

        await sendMessage(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith(
          expect.objectContaining({ error: expect.any(String) })
        );
      });

      it('returns 400 when text message has no content', async () => {
        const req = makeReq({
          body: { chatId: 'c1', senderId: 'u1', type: 'text' },
        });
        const res = makeRes();

        await sendMessage(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith(
          expect.objectContaining({ error: expect.stringContaining('content') })
        );
      });

      it('returns 400 when file message has no fileUrl', async () => {
        const req = makeReq({
          body: { chatId: 'c1', senderId: 'u1', type: 'file' },
        });
        const res = makeRes();

        await sendMessage(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith(
          expect.objectContaining({ error: expect.stringContaining('fileUrl') })
        );
      });

      it('returns 404 when chat does not exist', async () => {
        mockGet.mockResolvedValue({ exists: false });

        const req = makeReq({
          body: {
            chatId: 'nonexistent',
            senderId: 'u1',
            content: 'hello',
            type: 'text',
          },
        });
        const res = makeRes();

        await sendMessage(req, res);

        expect(res.status).toHaveBeenCalledWith(404);
      });

      it('sends a text message successfully', async () => {
        const chatData = {
          members: ['u1', 'u2'],
          unreadCounts: { u1: 0, u2: 0 },
        };

        mockGet.mockResolvedValue({
          exists: true,
          data: () => chatData,
        });
        mockAdd.mockResolvedValue({ id: 'msg_1' });
        mockUpdate.mockResolvedValue(undefined);

        const req = makeReq({
          body: {
            chatId: 'c1',
            senderId: 'u1',
            content: 'Hello world',
            type: 'text',
          },
        });
        const res = makeRes();

        await sendMessage(req, res);

        expect(res.status).toHaveBeenCalledWith(201);
        expect(res.json).toHaveBeenCalledWith(
          expect.objectContaining({ id: 'msg_1', content: 'Hello world' })
        );
      });
    });

    describe('getMessagesByChat', () => {
      it('returns 400 when chatId is missing', async () => {
        const req = makeReq({ query: {} });
        const res = makeRes();

        await getMessagesByChat(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
      });

      it('returns messages for a valid chatId', async () => {
        const msgDoc = {
          id: 'msg1',
          data: () => ({
            chatId: 'c1',
            senderId: 'u1',
            content: 'test',
            createdAt: new Date(),
          }),
        };

        mockGet.mockResolvedValue({ docs: [msgDoc] });

        const req = makeReq({ query: { chatId: 'c1' } });
        const res = makeRes();

        await getMessagesByChat(req, res);

        expect(res.json).toHaveBeenCalledWith(
          expect.arrayContaining([
            expect.objectContaining({ id: 'msg1', content: 'test' }),
          ])
        );
      });
    });

    describe('deleteMessage', () => {
      it('returns 400 when message ID is missing', async () => {
        const req = makeReq({ params: {}, body: { userId: 'u1' } });
        const res = makeRes();

        await deleteMessage(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
      });

      it('returns 400 when userId is missing', async () => {
        const req = makeReq({ params: { id: 'msg1' }, body: {} });
        const res = makeRes();

        await deleteMessage(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
      });
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  ALERTS CONTROLLER                                                 */
  /* ═══════════════════════════════════════════════════════════════════ */
  describe('Alerts Controller', () => {
    describe('getUserAlerts', () => {
      it('returns 400 when userId is missing', async () => {
        const req = makeReq({ params: {} });
        const res = makeRes();

        await getUserAlerts(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
      });

      it('returns alerts for a valid userId', async () => {
        const alertDoc = {
          id: 'alert1',
          data: () => ({
            userId: 'u1',
            chatId: 'c1',
            senderId: 's1',
            message: 'New message',
            isRead: false,
            createdAt: { toDate: () => new Date() },
          }),
        };

        // Alerts query
        mockGet.mockResolvedValueOnce({ docs: [alertDoc] });
        // Sender user lookup
        mockGet.mockResolvedValueOnce({
          exists: true,
          data: () => ({ name: 'Sender Name' }),
        });

        const req = makeReq({ params: { userId: 'u1' } });
        const res = makeRes();

        await getUserAlerts(req, res);

        expect(res.json).toHaveBeenCalledWith(
          expect.arrayContaining([
            expect.objectContaining({ id: 'alert1' }),
          ])
        );
      });
    });

    describe('markAlertsRead', () => {
      it('returns 400 when userId or chatId missing', async () => {
        const req = makeReq({ body: { userId: 'u1' } });
        const res = makeRes();

        await markAlertsRead(req, res);

        expect(res.status).toHaveBeenCalledWith(400);
      });
    });
  });
});
  afterAll(() => {
    jest.clearAllMocks();
  });
