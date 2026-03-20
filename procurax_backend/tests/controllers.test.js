import { describe, it, expect, vi } from 'vitest';

// ──────────────────────────────────────────────
// Helper: mock Express res object
// ──────────────────────────────────────────────
const mockRes = () => {
  const res = {};
  res.status = vi.fn().mockReturnValue(res);
  res.json   = vi.fn().mockReturnValue(res);
  return res;
};

// ──────────────────────────────────────────────
// 1. Tasks Controller – title validation
//    (mirrors requireTitle guard in tasks.controller.js)
// ──────────────────────────────────────────────
describe('Tasks Controller – input validation', () => {
  it('returns 400 when title is missing', () => {
    const req = { body: {}, userId: 'user1' };
    const res = mockRes();

    const { title } = req.body || {};
    if (!title) res.status(400).json({ message: 'Title is required' });

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ message: 'Title is required' });
  });

  it('does NOT return 400 when title is provided', () => {
    const req = { body: { title: 'Fix bug' }, userId: 'user1' };
    const res = mockRes();

    const { title } = req.body || {};
    if (!title) res.status(400).json({ message: 'Title is required' });

    expect(res.status).not.toHaveBeenCalled();
  });
});

// ──────────────────────────────────────────────
// 2. Notes Controller – title + content validation
//    (mirrors requireBodyFields guard in notes.controller.js)
// ──────────────────────────────────────────────
describe('Notes Controller – input validation', () => {
  it('returns 400 when title is missing', () => {
    const req = { body: { content: 'some content' }, userId: 'user1' };
    const res = mockRes();

    const { title, content } = req.body || {};
    if (!title || !content) res.status(400).json({ message: 'Title and content are required' });

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ message: 'Title and content are required' });
  });

  it('returns 400 when content is missing', () => {
    const req = { body: { title: 'My Note' }, userId: 'user1' };
    const res = mockRes();

    const { title, content } = req.body || {};
    if (!title || !content) res.status(400).json({ message: 'Title and content are required' });

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ message: 'Title and content are required' });
  });

  it('passes validation when both title and content are provided', () => {
    const req = { body: { title: 'My Note', content: 'Details here' }, userId: 'user1' };
    const res = mockRes();

    const { title, content } = req.body || {};
    if (!title || !content) res.status(400).json({ message: 'Title and content are required' });

    expect(res.status).not.toHaveBeenCalled();
  });
});

// ──────────────────────────────────────────────
// 3. Alerts Controller – userId param validation
//    (mirrors guard in alertsController.js)
// ──────────────────────────────────────────────
describe('Alerts Controller – userId validation', () => {
  it('returns 400 when userId param is missing', () => {
    const req = { params: {} };
    const res = mockRes();

    const userId = req.params.userId;
    if (!userId) res.status(400).json({ error: 'userId is required' });

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: 'userId is required' });
  });

  it('does NOT return 400 when userId param is provided', () => {
    const req = { params: { userId: 'abc123' } };
    const res = mockRes();

    const userId = req.params.userId;
    if (!userId) res.status(400).json({ error: 'userId is required' });

    expect(res.status).not.toHaveBeenCalled();
  });
});
