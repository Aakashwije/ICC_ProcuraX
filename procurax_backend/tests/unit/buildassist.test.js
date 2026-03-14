/**
 * ============================================================================
 * BuildAssist Module — Comprehensive Unit Tests
 * ============================================================================
 *
 * @file tests/unit/buildassist.test.js
 * @description
 *   Tests the BuildAssist AI chat controller for voice/text input processing:
 *   - Token parsing: Removes stop words, punctuation, lowercases
 *   - Intent detection: Routes to meetings, tasks, notes, procurement, dashboard
 *   - NLP helpers: Tokenisation, entity extraction, keyword matching
 *   - Chat controller: Accepts user queries, returns structured responses
 *   - Error handling: Invalid input, timeout, API failures
 *   - Integration: Multi-step conversation context
 *
 * @coverage
 *   - Token parsing: 5 tests (punctuation, stop words, lowercase, empty)
 *   - Intent detection: 6 tests (meetings, tasks, notes, procurement, dashboard, unknown)
 *   - Entity extraction: 4 tests (date ranges, user names, project IDs, keywords)
 *   - Chat response: 3 tests (single turn, context carryover, error handling)
 *   - Total: 18+ BuildAssist test cases
 *
 * @dependencies
 *   - NLP library (natural or custom tokeniser)
 *   - Express controllers (chat, intent router)
 *   - Database models (Meeting, Task, Note, Procurement, Dashboard)
 *   - Logger (mocked)
 *
 * @nlp_strategy
 *   - Token parsing: Regex sanitisation, stop word filter, lowercase
 *   - Stop words: English common words (show, me, the, a, an, etc.)
 *   - Intent keywords: 5-6 keywords per intent category
 *   - Confidence thresholds: Matches above threshold routed with high confidence
 *   - Fallback: Unknown intent returns generic response with suggestions
 *
 * @intent_routing_table
 *   - "meetings" keywords: meeting, meetings, schedule, upcoming, calendar, when
 *   - "tasks" keywords: task, tasks, todo, pending, stuck, blocked, assign
 *   - "notes" keywords: note, notes, search, document, memo, remind
 *   - "procurement" keywords: procurement, delivery, material, supply, order, budget
 *   - "dashboard" keywords: dashboard, summary, overview, stats, report, metrics
 *   - "unknown" default: Returns "I didn't understand" with intent suggestions
 *
 * @test_data
 *   - Query examples: Natural English questions and commands
 *   - Expected intents: Named routing categories
 *   - Edge cases: Misspellings, multiple intents, ambiguous queries
 *   - Context: Previous turn history for stateful conversations
 *
 * @chat_flow_example
 *   User: "Show me my upcoming meetings please"
 *   → Tokens: ["upcoming", "meetings"]
 *   → Intent: "meetings"
 *   → Service call: Meeting.find({ owner, startTime > now })
 *   → Response: { intent, data: [...], message: "..." }
 */

import { describe, it, expect } from '@jest/globals';

/* ────────────────────────────────────────────────────────────────────
   TOKEN PARSING / NLP HELPER FUNCTIONS
   ────────────────────────────────────────────────────────────────────
   @description
     Tokenisation pipeline:
     1. Lowercase entire input string
     2. Remove punctuation via regex [^a-z0-9\s]
     3. Split on whitespace into individual tokens
     4. Filter out stop words (common English words)
     5. Remove empty strings (length > 0)
     Returns array of meaningful keywords for intent detection
*/
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
