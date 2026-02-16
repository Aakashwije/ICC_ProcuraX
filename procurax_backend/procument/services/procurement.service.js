/*
  Procurement service: this file is the middle layer between the controller
  and the Google Sheets data source. It fetches raw rows, adds some helpful
  fields (like status), and returns a smaller, cleaner view for the API.
*/
import { fetchProcurementData } from "../lib/googleSheets.js";

/*
  Simple in-memory cache so we do not call Google Sheets on every request.
  - cachedData holds the last computed response.
  - lastFetch tracks when we last updated the cache.
*/
let cachedData = null;
let lastFetch = 0;
const CACHE_TTL = Number(process.env.CACHE_TTL_MS || 60000);

/*
  Compute delivery status using required date vs actual goods arrival date.
  Possible outputs: "Delayed", "Early", "On Time", "Unknown".
*/
function calculateStatus(cmsDate, goodsDate) {
  try {
    const cms = new Date(cmsDate);
    const goods = new Date(goodsDate);
    if (!Number.isFinite(cms.getTime()) || !Number.isFinite(goods.getTime())) {
      return "Unknown";
    }
    if (goods > cms) return "Delayed";
    if (goods < cms) return "Early";
    return "On Time";
  } catch {
    return "Unknown";
  }
}

/*
  Returns a cached view of procurement items and upcoming deliveries.
  Flow:
  1) Check cache
  2) Fetch raw sheet rows
  3) Enrich each row with a status
  4) Filter invalid dates
  5) Sort by goods date
  6) Slice into main list + upcoming list
*/
export async function getProcurementView() {
  const now = Date.now();
  /*
    If we still have fresh data in memory (within CACHE_TTL),
    return it immediately to keep the API fast.
  */
  if (cachedData && now - lastFetch < CACHE_TTL) {
    return cachedData;
  }

  /*
    Fetch raw data from Google Sheets.
    Each row is a procurement record coming from the spreadsheet.
  */
  const raw = await fetchProcurementData();

  /*
    Add a computed status field to each row, but keep
    the original date strings (we only parse for comparison).
  */
  const parsed = raw.map((r) => ({
    ...r,
    /*
      Keep original strings but use them to compute status.
      This makes the API response easy for the frontend to show.
    */
    cmsRequiredDate: r.cmsRequiredDate,
    goodsAtLocationDate: r.goodsAtLocationDate,
    status: calculateStatus(r.cmsRequiredDate, r.goodsAtLocationDate),
  }));

  /*
    Filter out entries without a valid goodsAtLocationDate.
    We need a real date to sort and to show upcoming deliveries.
  */
  const withDates = parsed.filter((p) => {
    if (!p.goodsAtLocationDate) return false;
    const time = new Date(p.goodsAtLocationDate).getTime();
    return Number.isFinite(time);
  });

  /*
    Sort by goodsAtLocationDate ascending (earliest first).
    This helps us show the soonest deliveries at the top.
  */
  withDates.sort(
    (a, b) =>
      new Date(a.goodsAtLocationDate).getTime() -
      new Date(b.goodsAtLocationDate).getTime()
  );

  /*
    Main list: first 5 upcoming deliveries.
    Note: This is "earliest upcoming" not "latest".
  */
  const procurementItems = withDates.slice(0, 5);

  /*
    Upcoming list: next 2 deliveries after the main list.
    Only return the small summary fields required by the UI.
  */
  const upcomingDeliveries = withDates.slice(5, 7).map((d) => ({
    materialDescription: d.materialDescription,
    goodsAtLocationDate: d.goodsAtLocationDate,
    status: d.status,
  }));

  /*
    Save results to cache so we can reuse for the next request.
  */
  cachedData = { procurementItems, upcomingDeliveries };
  lastFetch = Date.now();
  return cachedData;
}
