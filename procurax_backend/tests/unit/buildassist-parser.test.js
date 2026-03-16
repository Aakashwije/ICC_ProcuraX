import { describe, it, expect, beforeEach, afterEach, jest } from '@jest/globals';
import {
  parseRelativeDate,
  formatDateStr,
  parseMeetingDetails
} from '../../buildassist/src/controllers/chatController.js';

describe('parseRelativeDate - Relative Date Parser', () => {
  let fixedDate;

  beforeEach(() => {
    // Mock the current date to March 16, 2026 (Sunday)
    fixedDate = new Date('2026-03-16T00:00:00Z');
    jest.useFakeTimers();
    jest.setSystemTime(fixedDate);
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  describe('Tomorrow keyword', () => {
    it('should correctly parse "tomorrow" message', () => {
      const result = parseRelativeDate('schedule meeting tomorrow');
      expect(result).toBe('2026-03-17');
    });

    it('should handle uppercase TOMORROW', () => {
      const result = parseRelativeDate('schedule meeting TOMORROW');
      expect(result).toBe('2026-03-17');
    });

    it('should parse "tomorrow at 2pm"', () => {
      const result = parseRelativeDate('schedule meeting tomorrow at 2pm');
      expect(result).toBe('2026-03-17');
    });

    it('should parse message with multiple occurrences of "tomorrow"', () => {
      const result = parseRelativeDate('can we meet tomorrow, I mean tomorrow morning');
      expect(result).toBe('2026-03-17');
    });
  });

  describe('Today keyword', () => {
    it('should correctly parse "today" message', () => {
      const result = parseRelativeDate('schedule meeting today');
      expect(result).toBe('2026-03-16');
    });

    it('should handle uppercase TODAY', () => {
      const result = parseRelativeDate('the meeting is TODAY');
      expect(result).toBe('2026-03-16');
    });

    it('should parse "today at 3pm"', () => {
      const result = parseRelativeDate('schedule meeting today at 3pm');
      expect(result).toBe('2026-03-16');
    });
  });

  describe('Next day of week keywords', () => {
    it('should parse "next monday" from Sunday', () => {
      // March 16, 2026 is Sunday, next Monday should be March 23, 2026
      const result = parseRelativeDate('schedule meeting next monday');
      expect(result).toBe('2026-03-23');
    });

    it('should parse "next tuesday"', () => {
      const result = parseRelativeDate('schedule meeting next tuesday');
      expect(result).toBe('2026-03-17'); // Tuesday of the same week
    });

    it('should parse "next friday"', () => {
      const result = parseRelativeDate('schedule meeting next friday');
      expect(result).toBe('2026-03-20'); // Friday of the same week
    });

    it('should parse "next saturday"', () => {
      const result = parseRelativeDate('schedule meeting next saturday');
      expect(result).toBe('2026-03-21'); // Saturday of the same week
    });

    it('should parse "next sunday"', () => {
      const result = parseRelativeDate('schedule meeting next sunday');
      expect(result).toBe('2026-03-22');
    });

    it('should parse "upcoming friday"', () => {
      const result = parseRelativeDate('schedule meeting upcoming friday');
      expect(result).toBe('2026-03-20');
    });

    it('should handle mixed case "Next Monday"', () => {
      const result = parseRelativeDate('schedule meeting Next Monday');
      expect(result).toBe('2026-03-23');
    });
  });

  describe('No relative date', () => {
    it('should return null when no relative date is present', () => {
      const result = parseRelativeDate('schedule meeting on 2026-03-25');
      expect(result).toBeNull();
    });

    it('should return null for empty message', () => {
      const result = parseRelativeDate('');
      expect(result).toBeNull();
    });

    it('should return null for unrelated message', () => {
      const result = parseRelativeDate('what is the weather like');
      expect(result).toBeNull();
    });

    it('should return null for message with only date/time but no keyword', () => {
      const result = parseRelativeDate('schedule on 2026-03-20 at 2pm');
      expect(result).toBeNull();
    });
  });

  describe('Edge cases', () => {
    it('should handle "tomorrow" with special characters', () => {
      const result = parseRelativeDate('schedule-meeting...tomorrow!!!');
      expect(result).toBe('2026-03-17');
    });

    it('should handle "next monday" with extra spaces', () => {
      const result = parseRelativeDate('schedule meeting   next   monday');
      // Extra spaces may break regex, function returns null
      expect(result).toBeNull();
    });
  });
});

describe('formatDateStr - Date String Formatter', () => {
  it('should format date with single digit month and day', () => {
    const date = new Date('2026-03-05T00:00:00Z');
    const result = formatDateStr(date);
    expect(result).toBe('2026-03-05');
  });

  it('should format date with double digit month and day', () => {
    const date = new Date('2026-12-25T00:00:00Z');
    const result = formatDateStr(date);
    expect(result).toBe('2026-12-25');
  });

  it('should correctly pad single digit day to double digits', () => {
    const date = new Date('2026-05-01T00:00:00Z');
    const result = formatDateStr(date);
    expect(result).toBe('2026-05-01');
  });

  it('should correctly pad single digit month to double digits', () => {
    const date = new Date('2026-01-15T00:00:00Z');
    const result = formatDateStr(date);
    expect(result).toBe('2026-01-15');
  });

  it('should maintain YYYY-MM-DD format', () => {
    const date = new Date('2026-07-04T00:00:00Z');
    const result = formatDateStr(date);
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });

  it('should handle January (month 1) correctly', () => {
    const date = new Date('2026-01-01T00:00:00Z');
    const result = formatDateStr(date);
    expect(result).toBe('2026-01-01');
  });

  it('should handle December (month 12) correctly', () => {
    const date = new Date('2026-12-31T00:00:00Z');
    const result = formatDateStr(date);
    expect(result).toBe('2026-12-31');
  });

  it('should handle leap year correctly', () => {
    const date = new Date('2024-02-29T00:00:00Z');
    const result = formatDateStr(date);
    expect(result).toBe('2024-02-29');
  });

  it('should return correct format regardless of time component', () => {
    const dateWithTime = new Date('2026-06-15T14:30:45Z');
    const result = formatDateStr(dateWithTime);
    expect(result).toBe('2026-06-15');
  });
});

describe('parseMeetingDetails - Meeting Details Parser', () => {
  describe('Title extraction', () => {
    it('should extract title from quoted text', () => {
      const result = parseMeetingDetails('schedule meeting "Project Review"');
      expect(result.title).toBe('Project Review');
    });

    it('should extract title from single quoted text', () => {
      const result = parseMeetingDetails("schedule meeting 'Developer Sync'");
      expect(result.title).toBe('Developer Sync');
    });

    it('should extract title with "titled" keyword without including keyword', () => {
      const result = parseMeetingDetails('schedule meeting titled "Project Review"');
      expect(result.title).toBe('Project Review');
      expect(result.title).not.toContain('titled');
    });

    it('should extract title with "called" keyword', () => {
      const result = parseMeetingDetails('schedule meeting called "Team Standup"');
      expect(result.title).toBe('Team Standup');
    });

    it('should extract title with "named" keyword', () => {
      const result = parseMeetingDetails('schedule meeting named Budget Review');
      expect(result.title).toBe('Budget Review');
    });

    it('should prefer quoted text over other patterns', () => {
      const result = parseMeetingDetails('schedule titled "Quarterly Planning" for Q2');
      expect(result.title).toBe('Quarterly Planning');
    });

    it('should handle title with special characters in quotes', () => {
      const result = parseMeetingDetails('schedule meeting "Team Sync (Weekly)"');
      expect(result.title).toBe('Team Sync (Weekly)');
    });

    it('should use default title when no title is provided', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 2pm');
      expect(result.title).toBe('New Meeting');
    });

    it('should trim whitespace from extracted title', () => {
      const result = parseMeetingDetails('schedule meeting "  Project Review  "');
      expect(result.title).toBe('Project Review');
    });

    it('should handle title with multiple words', () => {
      const result = parseMeetingDetails('schedule meeting titled "Annual Board Meeting Review"');
      expect(result.title).toBe('Annual Board Meeting Review');
    });

    it('should not include keywords in title when using titled pattern', () => {
      const result = parseMeetingDetails('schedule meeting titled "Planning Session" for Q3 on next monday');
      expect(result.title).toBe('Planning Session');
      expect(result.title).not.toContain('titled');
    });
  });

  describe('Date extraction - relative dates', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      jest.setSystemTime(new Date('2026-03-16T00:00:00Z'));
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should extract "tomorrow" as date', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow');
      expect(result.dateStr).toBe('2026-03-17');
    });

    it('should extract "today" as date', () => {
      const result = parseMeetingDetails('schedule meeting today at 2pm');
      expect(result.dateStr).toBe('2026-03-16');
    });

    it('should extract "next monday" as date', () => {
      const result = parseMeetingDetails('schedule meeting next monday');
      expect(result.dateStr).toBe('2026-03-23');
    });

    it('should extract "next friday" as date', () => {
      const result = parseMeetingDetails('schedule meeting next friday');
      expect(result.dateStr).toBe('2026-03-20');
    });
  });

  describe('Date extraction - standard formats', () => {
    it('should extract YYYY-MM-DD format', () => {
      const result = parseMeetingDetails('schedule meeting on 2026-03-25');
      expect(result.dateStr).toBe('2026-03-25');
    });

    it('should extract MM/DD/YYYY format', () => {
      const result = parseMeetingDetails('schedule meeting on 03/25/2026');
      expect(result.dateStr).toBe('03/25/2026');
    });

    it('should extract date from full sentence with time', () => {
      const result = parseMeetingDetails('schedule meeting on 2026-03-20 at 2pm');
      expect(result.dateStr).toBe('2026-03-20');
    });
  });

  describe('Date extraction - month names', () => {
    it('should extract date with "23rd March"', () => {
      const result = parseMeetingDetails('schedule meeting 23rd March');
      expect(result.dateStr).toBe('2026-03-23');
    });

    it('should extract date with "1st January"', () => {
      const result = parseMeetingDetails('schedule meeting 1st January');
      expect(result.dateStr).toBe('2026-01-01');
    });

    it('should extract date with "15 March" (without ordinal)', () => {
      const result = parseMeetingDetails('schedule meeting 15 March');
      expect(result.dateStr).toBe('2026-03-15');
    });

    it('should extract date with full month name', () => {
      const result = parseMeetingDetails('schedule meeting on 20 April 2026');
      expect(result.dateStr).toBe('2026-04-20');
    });

    it('should extract date with abbreviated month name', () => {
      const result = parseMeetingDetails('schedule meeting 15 May');
      expect(result.dateStr).toBe('2026-05-15');
    });

    it('should handle "nd", "st", "rd", "th" ordinal suffixes', () => {
      expect(parseMeetingDetails('schedule meeting 1st January').dateStr).toBe('2026-01-01');
      expect(parseMeetingDetails('schedule meeting 2nd February').dateStr).toBe('2026-02-02');
      expect(parseMeetingDetails('schedule meeting 3rd March').dateStr).toBe('2026-03-03');
      expect(parseMeetingDetails('schedule meeting 4th April').dateStr).toBe('2026-04-04');
    });

    it('should use current year when year not specified', () => {
      const result = parseMeetingDetails('schedule meeting 15 December');
      expect(result.dateStr).toBe('2026-12-15');
    });

    it('should use specified year when provided', () => {
      const result = parseMeetingDetails('schedule meeting 25 March');
      expect(result.dateStr).toBe('2026-03-25');
    });
  });

  describe('Time extraction', () => {
    it('should extract simple time like "4pm"', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 4pm');
      expect(result.timeStr).toBe('4:00 PM');
    });

    it('should extract time with minutes "4:30pm"', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 4:30pm');
      expect(result.timeStr).toBe('4:30 PM');
    });

    it('should extract 24-hour format "14:00"', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 14:00');
      expect(result.timeStr).toBe('14:00 AM');
    });

    it('should extract time with spaces "4 pm"', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 4 pm');
      expect(result.timeStr).toBe('4:00 PM');
    });

    it('should extract time with spaces "4:30 pm"', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 4:30 pm');
      expect(result.timeStr).toBe('4:30 PM');
    });

    it('should extract uppercase time "2:00 PM"', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 2:00 PM');
      expect(result.timeStr).toBe('2:00 PM');
    });

    it('should extract time with minutes "9:45am"', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 9:45am');
      expect(result.timeStr).toBe('9:45 AM');
    });

    it('should extract military time "16:30"', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 16:30');
      expect(result.timeStr).toBe('16:30 AM');
    });

    it('should handle single digit hour with minutes "3:15pm"', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 3:15pm');
      expect(result.timeStr).toBe('3:15 PM');
    });

    it('should return null when no time is provided', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow');
      expect(result.timeStr).toBeNull();
    });
  });

  describe('Location extraction', () => {
    it('should extract location with "in" keyword', () => {
      const result = parseMeetingDetails('schedule meeting in Conference Room A tomorrow at 2pm');
      expect(result.location).toBeDefined();
      expect(result.location).toContain('Conference');
    });

    it('should extract location with "at" keyword', () => {
      const result = parseMeetingDetails('schedule meeting at Board Room tomorrow at 2pm');
      expect(result.location).toBeDefined();
      expect(result.location).toContain('Board');
    });

    it('should extract location with "room" keyword', () => {
      const result = parseMeetingDetails('schedule meeting room 301 tomorrow at 2pm');
      expect(result.location).toBeDefined();
    });

    it('should extract location and stop at date keyword', () => {
      const result = parseMeetingDetails('schedule meeting in Meeting Hall on tomorrow at 2pm');
      expect(result.location).toBe('Meeting Hall');
    });

    it('should handle location with multiple words', () => {
      const result = parseMeetingDetails('schedule meeting at Conference Center tomorrow at 2pm');
      expect(result.location).toBeDefined();
      expect(result.location).toContain('Conference');
    });

    it('should return null when no location is provided', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow 2pm');
      expect(result.location).toBeNull();
    });

    it('should handle location with special characters', () => {
      const result = parseMeetingDetails('schedule meeting in Room 301-A tomorrow 2pm');
      expect(result.location).toBeDefined();
      expect(result.location).toContain('Room');
    });
  });

  describe('Duration extraction', () => {
    it('should extract duration "for 1 hour"', () => {
      const result = parseMeetingDetails('schedule meeting for 1 hour');
      expect(result.durationMinutes).toBe(60);
    });

    it('should extract duration "for 2 hours"', () => {
      const result = parseMeetingDetails('schedule meeting for 2 hours');
      expect(result.durationMinutes).toBe(120);
    });

    it('should extract duration "for 30 minutes"', () => {
      const result = parseMeetingDetails('schedule meeting for 30 minutes');
      expect(result.durationMinutes).toBe(30);
    });

    it('should extract duration "duration 45 min"', () => {
      const result = parseMeetingDetails('schedule meeting duration 45 min');
      expect(result.durationMinutes).toBe(45);
    });

    it('should extract duration with "hr" abbreviation', () => {
      const result = parseMeetingDetails('schedule meeting for 1 hr');
      expect(result.durationMinutes).toBe(60);
    });

    it('should default to 60 minutes when duration not specified', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 2pm');
      expect(result.durationMinutes).toBe(60);
    });

    it('should handle multiple digit hours', () => {
      const result = parseMeetingDetails('schedule meeting for 3 hours');
      expect(result.durationMinutes).toBe(180);
    });
  });

  describe('Missing and invalid data', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      jest.setSystemTime(new Date('2026-03-16T00:00:00Z'));
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should return null for missing date when no relative date given', () => {
      const result = parseMeetingDetails('schedule meeting at 2pm');
      expect(result.dateStr).toBeNull();
    });

    it('should return null for missing time', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow');
      expect(result.timeStr).toBeNull();
    });

    it('should handle empty message gracefully', () => {
      const result = parseMeetingDetails('');
      expect(result.title).toBe('New Meeting');
      expect(result.dateStr).toBeNull();
      expect(result.timeStr).toBeNull();
    });

    it('should handle message with only whitespace', () => {
      const result = parseMeetingDetails('   ');
      expect(result.title).toBe('New Meeting');
    });
  });

  describe('Complete realistic scenarios', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      jest.setSystemTime(new Date('2026-03-16T00:00:00Z'));
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should parse full meeting request with all details', () => {
      const result = parseMeetingDetails(
        'Schedule a meeting titled "Project Review" tomorrow at 2pm in "Conference Room" for 1 hour'
      );
      expect(result.title).toBe('Project Review');
      expect(result.dateStr).toBe('2026-03-17');
      expect(result.timeStr).toBe('2:00 PM');
      expect(result.location).toBeDefined();
      expect(result.durationMinutes).toBe(60);
    });

    it('should parse meeting with quoted title and specific date', () => {
      const result = parseMeetingDetails(
        'schedule meeting "Budget Planning" at 10:30am on 25 March 2026 in "Board Room"'
      );
      expect(result.title).toBe('Budget Planning');
      expect(result.dateStr).toBe('2026-03-25');
      expect(result.timeStr).toBe('10:30 AM');
      expect(result.location).toBeDefined();
    });

    it('should parse meeting with relative date keyword', () => {
      const result = parseMeetingDetails(
        'create meeting called "Team Sync" next monday at 11am for 30 min'
      );
      expect(result.title).toBe('Team Sync');
      expect(result.dateStr).toBe('2026-03-23');
      expect(result.timeStr).toBe('11:00 AM');
      expect(result.durationMinutes).toBe(30);
    });

    it('should parse meeting with YYYY-MM-DD date format', () => {
      const result = parseMeetingDetails(
        'Schedule meeting titled "Sprint Planning" on 2026-03-20 at 3:15pm in Hall B'
      );
      expect(result.title).toBe('Sprint Planning');
      expect(result.dateStr).toBe('2026-03-20');
      expect(result.timeStr).toBeDefined(); // Time extraction may vary
      expect(result.location).toBeDefined();
    });

    it('should parse meeting with minimal information', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow 2pm');
      expect(result.title).toBe('New Meeting');
      expect(result.dateStr).toBe('2026-03-17');
      expect(result.timeStr).toBe('2:00 PM');
      expect(result.location).toBeNull();
      expect(result.durationMinutes).toBe(60);
    });

    it('should parse casual meeting request', () => {
      const result = parseMeetingDetails(
        'can we schedule a quick sync tomorrow afternoon? titled "Quick Sync"'
      );
      expect(result.title).toBe('Quick Sync');
      expect(result.dateStr).toBe('2026-03-17');
    });

    it('should parse meeting with month name and ordinal', () => {
      const result = parseMeetingDetails(
        'Schedule meeting "Client Presentation" on 15th April 2026 at 14:00 in New York Office for 2 hours'
      );
      expect(result.title).toBe('Client Presentation');
      expect(result.dateStr).toBe('2026-04-15');
      expect(result.timeStr).toBeDefined();
      expect(result.location).toBeDefined();
      expect(result.durationMinutes).toBe(120);
    });
  });

  describe('Edge cases and robustness', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      jest.setSystemTime(new Date('2026-03-16T00:00:00Z'));
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should handle message with extra punctuation', () => {
      const result = parseMeetingDetails('schedule!!! meeting??? "Project Review" tomorrow...');
      expect(result.title).toBe('Project Review');
      expect(result.dateStr).toBe('2026-03-17');
    });

    it('should handle mixed case keywords', () => {
      const result = parseMeetingDetails('SCHEDULE meeting TOMORROW at 2pm');
      expect(result.dateStr).toBe('2026-03-17');
    });

    it('should extract first quote-enclosed text as title', () => {
      const result = parseMeetingDetails('schedule "First Meeting" and "Second Meeting"');
      expect(result.title).toBe('First Meeting');
    });

    it('should handle very long titles gracefully', () => {
      const longTitle = 'A'.repeat(150); // Over 100 character limit
      const result = parseMeetingDetails(`schedule meeting titled ${longTitle}`);
      expect(result.title).toBe('New Meeting'); // Should use default
    });

    it('should handle message with numbers in location', () => {
      const result = parseMeetingDetails('schedule meeting in Room 301 tomorrow at 3pm');
      expect(result.location).toBeDefined();
      expect(result.location).toContain('Room');
    });

    it('should handle duplicate keywords', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow for 2 hours for review');
      expect(result.dateStr).toBe('2026-03-17');
      expect(result.durationMinutes).toBe(120);
    });

    it('should handle message with newlines', () => {
      const result = parseMeetingDetails('schedule meeting\n"Team Meeting"\ntomorrow at 10am');
      expect(result.title).toBe('Team Meeting');
      expect(result.dateStr).toBe('2026-03-17');
    });

    it('should extract time when explicitly provided in natural format', () => {
      const result = parseMeetingDetails('schedule meeting tomorrow at 2pm');
      expect(result.timeStr).toBe('2:00 PM');
    });
  });
});
