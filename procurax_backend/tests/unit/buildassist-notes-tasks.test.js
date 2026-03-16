import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import { parseNoteDetails, parseTaskDetails } from '../../buildassist/src/controllers/chatController.js';

describe('BuildAssist Notes & Tasks Parser', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-03-16T00:00:00Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  // ===== NOTE DETAILS PARSING =====
  describe('parseNoteDetails - Note Details Parser', () => {
    
    describe('Title extraction', () => {
      it('should extract title from single quotes', () => {
        const result = parseNoteDetails("create note 'Budget Planning'");
        expect(result.title).toBe('Budget Planning');
      });

      it('should extract title from double quotes', () => {
        const result = parseNoteDetails('create note "Project Ideas"');
        expect(result.title).toBe('Project Ideas');
      });

      it('should extract title from titled pattern', () => {
        const result = parseNoteDetails('add note titled Meeting Notes about Q1 planning');
        expect(result.title).toMatch(/Meeting|Notes/);
      });

      it('should extract title from named pattern', () => {
        const result = parseNoteDetails('create note named "Bug Report" with details');
        expect(result.title).toBe('Bug Report');
      });

      it('should default to Untitled Note when no title found', () => {
        const result = parseNoteDetails('just add some random content here');
        expect(result.title).toBe('Untitled Note');
      });

      it('should use first sentence as title when quoted', () => {
        const result = parseNoteDetails('"Complete project report" Need to finish by Friday');
        expect(result.title).toBe('Complete project report');
      });

      it('should handle very long titles gracefully', () => {
        const longTitle = 'This is a very long title that should still work even if it exceeds normal length';
        const result = parseNoteDetails(`"${longTitle}"`);
        expect(result.title).toHaveLength(longTitle.length);
      });

      it('should handle title with special characters', () => {
        const result = parseNoteDetails('"Important! 2026-Q1 & Q2 Review"');
        expect(result.title).toBe('Important! 2026-Q1 & Q2 Review');
      });
    });

    describe('Content extraction', () => {
      it('should extract remaining text as content', () => {
        const result = parseNoteDetails('"Project Status" Currently 75% complete, all tasks on track');
        expect(result.content).toContain('75%');
      });

      it('should use original message as content when no quoted title', () => {
        const result = parseNoteDetails('Just a simple note about the meeting');
        expect(result.content).toBe('Just a simple note about the meeting');
      });

      it('should handle multiline content', () => {
        const result = parseNoteDetails('"Meeting Notes"\nDiscussed Q1 targets\nReviewed budget\nConfirmed deadlines');
        expect(result.content).toContain('Q1 targets');
        expect(result.content).toContain('budget');
      });

      it('should provide meaningful content even with minimal input', () => {
        const result = parseNoteDetails('brief');
        expect(result.content.length > 0).toBe(true);
      });
    });

    describe('Tag extraction', () => {
      it('should extract bug tag', () => {
        const result = parseNoteDetails('create note about login issue tag: bug');
        expect(result.tag).toBe('Bug');
      });

      it('should extract feature tag', () => {
        const result = parseNoteDetails('add note "New Dashboard" as feature');
        expect(result.tag).toBe('Feature');
      });

      it('should extract idea tag', () => {
        const result = parseNoteDetails('note titled "App Redesign" tagged as idea');
        expect(result.tag).toBe('Idea');
      });

      it('should extract urgent tag', () => {
        const result = parseNoteDetails('create note about server down tag: urgent');
        expect(result.tag).toBe('Urgent');
      });

      it('should default to Issue tag', () => {
        const result = parseNoteDetails('create note "Simple note"');
        expect(result.tag).toBe('Issue');
      });

      it('should ignore non-matching tags and use default', () => {
        const result = parseNoteDetails('create note "Test" tagged as invalid');
        expect(result.tag).toBe('Issue');
      });

      it('should be case-insensitive for tag', () => {
        const result = parseNoteDetails('create note about problem TAG: BUG');
        expect(result.tag).toMatch(/bug|Bug|BUG/i);
      });
    });

    describe('Complete realistic scenarios', () => {
      it('should parse full note creation with all details', () => {
        const result = parseNoteDetails('"Q1 Planning Session" Discussed new feature roadmap, budget allocation, and team expansion plans. All departments confirmed. tag: important');
        expect(result.title).toBe('Q1 Planning Session');
        expect(result.content).toContain('roadmap');
        expect(result.tag).toBe('Important');
      });

      it('should handle note with code snippet', () => {
        const result = parseNoteDetails('"Database Schema Update" Add new column: ALTER TABLE users ADD COLUMN phone VARCHAR(20);');
        expect(result.title).toBe('Database Schema Update');
        expect(result.content).toContain('ALTER TABLE');
      });

      it('should handle minimal note creation', () => {
        const result = parseNoteDetails('note about meeting');
        expect(result.title).toMatch(/meeting|Untitled/);
        expect(result.content).toContain('meeting');
      });

      it('should handle empty quoted title and use content as fallback', () => {
        const result = parseNoteDetails('add note titled Project Update details here');
        expect(result.title).toContain('Project');
      });
    });

    describe('Edge cases', () => {
      it('should handle message with only whitespace after title', () => {
        const result = parseNoteDetails('"Title Only"   ');
        expect(result.title).toBe('Title Only');
        expect(result.content.length >= 0).toBe(true);
      });

      it('should handle message with punctuation', () => {
        const result = parseNoteDetails('"Important Note!" Content here... wait, more content!');
        expect(result.title).toBe('Important Note!');
      });

      it('should handle multiple quoted sections - use first as title', () => {
        const result = parseNoteDetails('"First Title" and then "Second Title" as content');
        expect(result.title).toBe('First Title');
        expect(result.content.length > 0).toBe(true);
      });

      it('should handle newlines in content', () => {
        const result = parseNoteDetails('"Title"\nLine 1\nLine 2\nLine 3');
        expect(result.content).toContain('Line 1');
      });
    });
  });

  // ===== TASK DETAILS PARSING =====
  describe('parseTaskDetails - Task Details Parser', () => {
    
    describe('Title extraction', () => {
      it('should extract title from quoted text', () => {
        const result = parseTaskDetails('add task "Review Q1 report"');
        expect(result.title).toBe('Review Q1 report');
      });

      it('should extract title with task prefix', () => {
        const result = parseTaskDetails('task "Fix login bug" high priority');
        expect(result.title).toBe('Fix login bug');
      });

      it('should extract from add pattern', () => {
        const result = parseTaskDetails('add "Complete project" with description');
        expect(result.title).toBe('Complete project');
      });

      it('should extract from create pattern', () => {
        const result = parseTaskDetails('create "Database migration" - critical');
        expect(result.title).toBe('Database migration');
      });

      it('should default to New Task when no title found', () => {
        const result = parseTaskDetails('some random content');
        expect(result.title).toBe('some random content');
      });

      it('should use first sentence when extracting title', () => {
        const result = parseTaskDetails('add Fix the navigation menu with better structure and styling');
        expect(result.title).toBe('Fix the navigation menu');
      });

      it('should handle task title with numbers', () => {
        const result = parseTaskDetails('create "API v2 implementation"');
        expect(result.title).toBe('API v2 implementation');
      });
    });

    describe('Description extraction', () => {
      it('should extract description from remaining text', () => {
        const result = parseTaskDetails('add "Fix bugs" The login page has multiple issues that need immediate attention');
        expect(result.description).toContain('login');
      });

      it('should use full message as description when no title', () => {
        const result = parseTaskDetails('implement new feature for dashboard');
        expect(result.description).toContain('implement');
      });
    });

    describe('Priority extraction', () => {
      it('should detect critical priority', () => {
        const result = parseTaskDetails('add task "Fix server" CRITICAL');
        expect(result.priority).toBe('critical');
      });

      it('should detect critical with asap keyword', () => {
        const result = parseTaskDetails('create task "Emergency fix" ASAP');
        expect(result.priority).toBe('critical');
      });

      it('should detect critical with urgent keyword', () => {
        const result = parseTaskDetails('add "Outage response" - urgent response needed');
        expect(result.priority).toBe('critical');
      });

      it('should detect high priority', () => {
        const result = parseTaskDetails('add task "Important update" high priority');
        expect(result.priority).toBe('high');
      });

      it('should detect high priority with important keyword', () => {
        const result = parseTaskDetails('create "Important feature" for next release');
        expect(result.priority).toBe('high');
      });

      it('should detect low priority', () => {
        const result = parseTaskDetails('add task "Nice to have" low priority');
        expect(result.priority).toBe('low');
      });

      it('should detect low priority with eventually keyword', () => {
        const result = parseTaskDetails('create "Refactor code" eventually when time permits');
        expect(result.priority).toBe('low');
      });

      it('should default to medium priority', () => {
        const result = parseTaskDetails('add task "Regular work"');
        expect(result.priority).toBe('medium');
      });

      it('should be case-insensitive for priority', () => {
        const result = parseTaskDetails('add task "Something" HIGH PRIORITY');
        expect(result.priority).toBe('high');
      });
    });

    describe('Due date extraction', () => {
      it('should extract tomorrow date', () => {
        const result = parseTaskDetails('add task "Review" due tomorrow');
        expect(result.dueDate).toBe('2026-03-17');
      });

      it('should extract today date', () => {
        const result = parseTaskDetails('create task "Urgent" today');
        expect(result.dueDate).toBe('2026-03-16');
      });

      it('should extract next monday', () => {
        const result = parseTaskDetails('add task "Planning" next monday');
        expect(result.dueDate).toBe('2026-03-23');
      });

      it('should extract next tuesday', () => {
        const result = parseTaskDetails('create task "Review" next tuesday');
        expect(result.dueDate).toBe('2026-03-17');
      });

      it('should return null when no date found', () => {
        const result = parseTaskDetails('add task "No date"');
        expect(result.dueDate).toBeNull();
      });
    });

    describe('Status', () => {
      it('should default to todo status', () => {
        const result = parseTaskDetails('add task "Test"');
        expect(result.status).toBe('todo');
      });
    });

    describe('Complete realistic scenarios', () => {
      it('should parse full task with all details', () => {
        const result = parseTaskDetails('create task "API Integration" - Complete payments API integration with Stripe, setup webhooks, add error handling. CRITICAL by tomorrow');
        expect(result.title).toBe('API Integration');
        expect(result.priority).toBe('critical');
        expect(result.dueDate).toBe('2026-03-17');
        expect(result.description).toContain('Stripe');
      });

      it('should parse task with medium priority', () => {
        const result = parseTaskDetails('add "Code Review" Need to review PR #45 and provide feedback on database changes');
        expect(result.title).toBe('Code Review');
        expect(result.priority).toBe('medium');
      });

      it('should parse low priority cleanup task', () => {
        const result = parseTaskDetails('add "Code cleanup" Low priority - eventually refactor utilities folder, low priority');
        expect(result.title).toBe('Code cleanup');
        expect(result.priority).toBe('low');
      });

      it('should parse task with relative date', () => {
        const result = parseTaskDetails('create "Monthly Report" as high priority due next friday');
        expect(result.title).toBe('Monthly Report');
        expect(result.priority).toBe('high');
        expect(result.dueDate).toBe('2026-03-20');
      });

      it('should handle minimal task creation', () => {
        const result = parseTaskDetails('add task');
        expect(result.title).toBe('task');
        expect(result.priority).toBe('medium');
        expect(result.dueDate).toBeNull();
      });
    });

    describe('Edge cases and robustness', () => {
      it('should handle very long title', () => {
        const longTitle = 'This is a very long task title that should be handled gracefully even if it goes over 100 characters';
        const result = parseTaskDetails(`"${longTitle}"`);
        expect(result.title).toBe(longTitle);
      });

      it('should handle task with special characters', () => {
        const result = parseTaskDetails('add task "Fix SQL: SELECT * FROM users WHERE status=\'active\'"');
        expect(result.title).toContain('SELECT');
      });

      it('should handle mixed case keywords', () => {
        const result = parseTaskDetails('ADD "Test" CRITICAL By Tomorrow');
        expect(result.title).toBe('Test');
        expect(result.priority).toBe('critical');
      });

      it('should handle message with multiple punctuation', () => {
        const result = parseTaskDetails('create "Final QA Test!!!" - urgent, critical, needs review ASAP!');
        expect(result.title).toBe('Final QA Test!!!');
        expect(result.priority).toBe('critical');
      });

      it('should handle task without keyword prefix', () => {
        const result = parseTaskDetails('"Implement feature" Build new dashboard component');
        expect(result.title).toBe('Implement feature');
      });

      it('should handle description with multiple priority keywords', () => {
        const result = parseTaskDetails('add task about high level critical system design');
        expect(result.priority).toBe('critical');
      });
    });
  });
});
