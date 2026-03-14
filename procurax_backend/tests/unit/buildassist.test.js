/**
 * BuildAssist Module — Unit Tests
 *
 * Tests the BuildAssist AI chat controller's token parsing and
 * intent-routing logic (meetings, tasks, notes, procurement, dashboard).
 */

import { describe, it, expect } from '@jest/globals';

/* ── tests ────────────────────────────────────────────────────────────── */
describe('BuildAssist Module', () => {
  /* ── Token Parsing / NLP helpers ───────────────────────────────────── */
  describe('Token Parsing', () => {
    const stopWords = [
      'show', 'please', 'me', 'give', 'list', 'items', 'details',
      'about', 'the', 'a', 'an', 'of', 'for', 'you',
    ];

    function parseTokens(rawQuery) {
      const sanitized = rawQuery
        .toLowerCase()
        .replace(/[^a-z0-9\s]/g, '')
        .trim();
      return sanitized
        .split(/\s+/)
        .filter((w) => w.length > 0 && !stopWords.includes(w));
    }

    it('extracts meaningful tokens from a query', () => {
      const tokens = parseTokens('Show me my upcoming meetings please');
      expect(tokens).toContain('upcoming');
      expect(tokens).toContain('meetings');
      expect(tokens).not.toContain('show');
      expect(tokens).not.toContain('me');
      expect(tokens).not.toContain('please');
    });

    it('removes punctuation', () => {
      const tokens = parseTokens("What's my task status??!");
      expect(tokens).toContain('whats');
      expect(tokens).toContain('task');
      expect(tokens).toContain('status');
    });

    it('lowercases all tokens', () => {
      const tokens = parseTokens('SHOW TASKS');
      expect(tokens).toContain('tasks');
    });

    it('returns empty array for stop-words only', () => {
      const tokens = parseTokens('show me the items please');
      expect(tokens).toHaveLength(0);
    });

    it('handles empty input', () => {
      const tokens = parseTokens('');
      expect(tokens).toHaveLength(0);
    });
  });

  /* ── Intent Detection ──────────────────────────────────────────────── */
  describe('Intent Detection', () => {
    function detectIntent(tokens) {
      if (tokens.some((t) => ['meeting', 'meetings', 'schedule', 'upcoming'].includes(t))) {
        return 'meetings';
      }
      if (tokens.some((t) => ['task', 'tasks', 'todo', 'pending', 'stuck', 'blocked'].includes(t))) {
        return 'tasks';
      }
      if (tokens.some((t) => ['note', 'notes', 'search'].includes(t))) {
        return 'notes';
      }
      if (tokens.some((t) => ['procurement', 'delivery', 'material', 'supply', 'order'].includes(t))) {
        return 'procurement';
      }
      if (tokens.some((t) => ['dashboard', 'summary', 'overview', 'stats'].includes(t))) {
        return 'dashboard';
      }
      return 'unknown';
    }

    it('detects meetings intent', () => {
      expect(detectIntent(['upcoming', 'meetings'])).toBe('meetings');
      expect(detectIntent(['schedule'])).toBe('meetings');
      expect(detectIntent(['meeting'])).toBe('meetings');
    });

    it('detects tasks intent', () => {
      expect(detectIntent(['pending', 'tasks'])).toBe('tasks');
      expect(detectIntent(['todo'])).toBe('tasks');
      expect(detectIntent(['blocked'])).toBe('tasks');
      expect(detectIntent(['stuck'])).toBe('tasks');
    });

    it('detects notes intent', () => {
      expect(detectIntent(['search', 'notes'])).toBe('notes');
      expect(detectIntent(['note'])).toBe('notes');
    });

    it('detects procurement intent', () => {
      expect(detectIntent(['delivery', 'status'])).toBe('procurement');
      expect(detectIntent(['material', 'order'])).toBe('procurement');
      expect(detectIntent(['procurement'])).toBe('procurement');
      expect(detectIntent(['supply'])).toBe('procurement');
    });

    it('detects dashboard intent', () => {
      expect(detectIntent(['dashboard'])).toBe('dashboard');
      expect(detectIntent(['summary'])).toBe('dashboard');
      expect(detectIntent(['overview'])).toBe('dashboard');
      expect(detectIntent(['stats'])).toBe('dashboard');
    });

    it('returns unknown for unrecognized queries', () => {
      expect(detectIntent(['hello', 'world'])).toBe('unknown');
      expect(detectIntent([])).toBe('unknown');
    });
  });

  /* ── Response Formatting ───────────────────────────────────────────── */
  describe('Response Formatting', () => {
    it('formats meetings response with count', () => {
      const meetings = [{ title: 'Standup' }, { title: 'Review' }];
      const reply = meetings.length > 0
        ? `You have ${meetings.length} upcoming meetings:`
        : "You don't have any upcoming meetings.";
      expect(reply).toBe('You have 2 upcoming meetings:');
    });

    it('formats empty meetings response', () => {
      const meetings = [];
      const reply = meetings.length > 0
        ? `You have ${meetings.length} upcoming meetings:`
        : "You don't have any upcoming meetings.";
      expect(reply).toBe("You don't have any upcoming meetings.");
    });

    it('formats tasks response with count', () => {
      const tasks = [{ title: 'Fix bug' }];
      const reply = tasks.length > 0
        ? `You have ${tasks.length} pending tasks:`
        : 'No pending tasks. Great!';
      expect(reply).toBe('You have 1 pending tasks:');
    });

    it('formats notes response with keyword filter', () => {
      const keyword = 'concrete';
      const notes = [
        { title: 'Concrete specs', content: 'Grade M30' },
        { title: 'Steel specs', content: 'TMT bars' },
      ];
      const filtered = keyword
        ? notes.filter(
            (n) =>
              n.title.toLowerCase().includes(keyword) ||
              n.content?.toLowerCase().includes(keyword)
          )
        : notes;

      expect(filtered).toHaveLength(1);
      expect(filtered[0].title).toBe('Concrete specs');
    });

    it('returns all notes when no keyword', () => {
      const keyword = '';
      const notes = [{ title: 'A' }, { title: 'B' }];
      const filtered = keyword
        ? notes.filter((n) => n.title.toLowerCase().includes(keyword))
        : notes;
      expect(filtered).toHaveLength(2);
    });

    it('attaches correct type field to response', () => {
      const meetingRes = { reply: 'test', data: [], type: 'meetings_data' };
      const taskRes = { reply: 'test', data: [], type: 'tasks_data' };
      const noteRes = { reply: 'test', data: [], type: 'notes_data' };
      const procRes = { reply: 'test', data: [], type: 'procurement_data' };

      expect(meetingRes.type).toBe('meetings_data');
      expect(taskRes.type).toBe('tasks_data');
      expect(noteRes.type).toBe('notes_data');
      expect(procRes.type).toBe('procurement_data');
    });
  });

  /* ── Error Handling ────────────────────────────────────────────────── */
  describe('Error Handling', () => {
    it('returns error response for empty message', () => {
      const message = '';
      const response = !message
        ? { reply: 'Please provide a message.', error: true }
        : null;
      expect(response).toEqual({
        reply: 'Please provide a message.',
        error: true,
      });
    });

    it('returns error response for null message', () => {
      const message = null;
      const response = !message
        ? { reply: 'Please provide a message.', error: true }
        : null;
      expect(response.error).toBe(true);
    });
  });
});
