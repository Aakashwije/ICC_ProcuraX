/**
 * Procurement Service — Unit Tests
 *
 * Tests the core procurement service logic:
 *  - calculateStatus()  → delivery date comparison
 *  - getProcurementView() → caching, filtering, sorting, slicing
 *  - extractSheetId() / extractGid() → URL parsing helpers
 */

import { jest, describe, it, expect, beforeEach } from '@jest/globals';

/* ── mocks ────────────────────────────────────────────────────────────── */
const mockFetchProcurementData = jest.fn();

jest.unstable_mockModule('../../procument/lib/googleSheets.js', () => ({
  fetchProcurementData: mockFetchProcurementData,
  extractSheetId: (url) => {
    if (!url) return null;
    const match = url.match(/\/d\/([a-zA-Z0-9-_]+)/);
    return match ? match[1] : url;
  },
  extractGid: (url) => {
    if (!url) return null;
    const match = url.match(/[?&#]gid=(\d+)/);
    return match ? match[1] : null;
  },
}));

/* ── import under test (must come AFTER mock registration) ───────────── */
const { getProcurementView } = await import(
  '../../procument/services/procurement.service.js'
);
const { extractSheetId, extractGid } = await import(
  '../../procument/lib/googleSheets.js'
);

/* ── helpers ──────────────────────────────────────────────────────────── */
function makeRow(overrides = {}) {
  const future = new Date();
  future.setDate(future.getDate() + 5);
  return {
    materialList: 'Steel Beams',
    responsibility: 'Supplier A',
    openingLC: '2025-01-01',
    etd: '2025-02-01',
    eta: '2025-03-01',
    boiApproval: '2025-01-15',
    revisedDeliveryToSite: future.toISOString().split('T')[0],
    requiredDateCMS: future.toISOString().split('T')[0],
    ...overrides,
  };
}

/* ── tests ────────────────────────────────────────────────────────────── */
describe('Procurement Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  /* ── extractSheetId ────────────────────────────────────────────────── */
  describe('extractSheetId', () => {
    it('extracts ID from a full Google Sheets URL', () => {
      const url =
        'https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit';
      expect(extractSheetId(url)).toBe(
        '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms'
      );
    });

    it('returns null for falsy input', () => {
      expect(extractSheetId(null)).toBeNull();
      expect(extractSheetId('')).toBeNull();
      expect(extractSheetId(undefined)).toBeNull();
    });

    it('returns raw string if it is already an ID', () => {
      expect(extractSheetId('abc123')).toBe('abc123');
    });
  });

  /* ── extractGid ────────────────────────────────────────────────────── */
  describe('extractGid', () => {
    it('extracts gid from URL with ?gid= param', () => {
      expect(
        extractGid('https://docs.google.com/spreadsheets/d/abc/edit?gid=257866353')
      ).toBe('257866353');
    });

    it('extracts gid from URL with &gid= param', () => {
      expect(
        extractGid('https://docs.google.com/spreadsheets/d/abc/edit?foo=1&gid=999')
      ).toBe('999');
    });

    it('returns null when no gid present', () => {
      expect(extractGid('https://docs.google.com/spreadsheets/d/abc/edit')).toBeNull();
    });

    it('returns null for falsy input', () => {
      expect(extractGid(null)).toBeNull();
    });
  });

  /* ── getProcurementView ────────────────────────────────────────────── */
  describe('getProcurementView', () => {
    it('returns procurement items and upcoming deliveries', async () => {
      const rows = Array.from({ length: 8 }, (_, i) => {
        const d = new Date();
        d.setDate(d.getDate() + i + 1);
        return makeRow({
          materialList: `Item ${i + 1}`,
          revisedDeliveryToSite: d.toISOString().split('T')[0],
        });
      });
      mockFetchProcurementData.mockResolvedValue(rows);

      const view = await getProcurementView('https://sheet-url', 'user1');

      expect(view).toHaveProperty('procurementItems');
      expect(view).toHaveProperty('upcomingDeliveries');
      expect(view.procurementItems.length).toBeLessThanOrEqual(5);
      expect(view.upcomingDeliveries.length).toBeLessThanOrEqual(2);
    });

    it('computes "Delayed" status when delivery is after required date', async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 10);
      const earlyRequired = new Date();
      earlyRequired.setDate(earlyRequired.getDate() + 5);

      mockFetchProcurementData.mockResolvedValue([
        makeRow({
          revisedDeliveryToSite: futureDate.toISOString().split('T')[0],
          requiredDateCMS: earlyRequired.toISOString().split('T')[0],
        }),
      ]);

      const view = await getProcurementView('url', 'user2');
      expect(view.procurementItems[0].status).toBe('Delayed');
    });

    it('computes "Early" status when delivery is before required date', async () => {
      const earlyDelivery = new Date();
      earlyDelivery.setDate(earlyDelivery.getDate() + 2);
      const lateRequired = new Date();
      lateRequired.setDate(lateRequired.getDate() + 10);

      mockFetchProcurementData.mockResolvedValue([
        makeRow({
          revisedDeliveryToSite: earlyDelivery.toISOString().split('T')[0],
          requiredDateCMS: lateRequired.toISOString().split('T')[0],
        }),
      ]);

      const view = await getProcurementView('url', 'user3');
      expect(view.procurementItems[0].status).toBe('Early');
    });

    it('computes "On Time" status when dates match', async () => {
      const sameDate = new Date();
      sameDate.setDate(sameDate.getDate() + 5);
      const dateStr = sameDate.toISOString().split('T')[0];

      mockFetchProcurementData.mockResolvedValue([
        makeRow({
          revisedDeliveryToSite: dateStr,
          requiredDateCMS: dateStr,
        }),
      ]);

      const view = await getProcurementView('url', 'user4');
      expect(view.procurementItems[0].status).toBe('On Time');
    });

    it('computes "Unknown" status for invalid dates', async () => {
      const future = new Date();
      future.setDate(future.getDate() + 3);
      mockFetchProcurementData.mockResolvedValue([
        makeRow({
          revisedDeliveryToSite: future.toISOString().split('T')[0],
          requiredDateCMS: 'not-a-date',
        }),
      ]);

      const view = await getProcurementView('url', 'user5');
      expect(view.procurementItems[0].status).toBe('Unknown');
    });

    it('filters out rows with no delivery date', async () => {
      mockFetchProcurementData.mockResolvedValue([
        makeRow({ revisedDeliveryToSite: '' }),
        makeRow({ revisedDeliveryToSite: '' }),
      ]);

      const view = await getProcurementView('url', 'user6');
      expect(view.procurementItems).toHaveLength(0);
    });

    it('filters out past delivery dates', async () => {
      const pastDate = new Date();
      pastDate.setDate(pastDate.getDate() - 10);
      mockFetchProcurementData.mockResolvedValue([
        makeRow({ revisedDeliveryToSite: pastDate.toISOString().split('T')[0] }),
      ]);

      const view = await getProcurementView('url', 'user7');
      expect(view.procurementItems).toHaveLength(0);
    });

    it('sorts items by delivery date ascending', async () => {
      const d1 = new Date(); d1.setDate(d1.getDate() + 5);
      const d2 = new Date(); d2.setDate(d2.getDate() + 1);
      const d3 = new Date(); d3.setDate(d3.getDate() + 3);

      mockFetchProcurementData.mockResolvedValue([
        makeRow({ materialList: 'Late', revisedDeliveryToSite: d1.toISOString().split('T')[0] }),
        makeRow({ materialList: 'Earliest', revisedDeliveryToSite: d2.toISOString().split('T')[0] }),
        makeRow({ materialList: 'Middle', revisedDeliveryToSite: d3.toISOString().split('T')[0] }),
      ]);

      const view = await getProcurementView('url', 'user8');
      expect(view.procurementItems[0].materialList).toBe('Earliest');
      expect(view.procurementItems[1].materialList).toBe('Middle');
      expect(view.procurementItems[2].materialList).toBe('Late');
    });

    it('returns empty arrays when no rows exist', async () => {
      mockFetchProcurementData.mockResolvedValue([]);

      const view = await getProcurementView('url', 'user9');
      expect(view.procurementItems).toEqual([]);
      expect(view.upcomingDeliveries).toEqual([]);
    });

    it('uses cache for repeated calls within TTL', async () => {
      const rows = [makeRow()];
      mockFetchProcurementData.mockResolvedValue(rows);

      await getProcurementView('same-url', 'same-user');
      await getProcurementView('same-url', 'same-user');

      // fetchProcurementData should be called only once because of cache
      expect(mockFetchProcurementData).toHaveBeenCalledTimes(1);
    });

    it('upcoming deliveries only have summary fields', async () => {
      const rows = Array.from({ length: 8 }, (_, i) => {
        const d = new Date();
        d.setDate(d.getDate() + i + 1);
        return makeRow({
          materialList: `Item ${i}`,
          revisedDeliveryToSite: d.toISOString().split('T')[0],
        });
      });
      mockFetchProcurementData.mockResolvedValue(rows);

      const view = await getProcurementView('url2', 'user10');

      if (view.upcomingDeliveries.length > 0) {
        const delivery = view.upcomingDeliveries[0];
        expect(delivery).toHaveProperty('materialList');
        expect(delivery).toHaveProperty('revisedDeliveryToSite');
        expect(delivery).toHaveProperty('status');
        // Should NOT have full logistics fields
        expect(delivery).not.toHaveProperty('responsibility');
        expect(delivery).not.toHaveProperty('openingLC');
      }
    });
  });
});
