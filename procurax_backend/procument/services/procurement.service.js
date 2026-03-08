/*
  Procurement service: this file is the middle layer between the controller
  and the Google Sheets data source. It fetches raw rows, adds some helpful
  fields (like status), and returns a smaller, cleaner view for the API.
*/
import { fetchProcurementData } from "../lib/googleSheets.js";

/*
  Simple in-memory cache so we do not call Google Sheets on every request.
  - cache holds objects with { data, lastFetch } keyed by sheetUrl/ID.
*/
const cache = new Map();
const CACHE_TTL = Number(process.env.CACHE_TTL_MS || 60000);

/*
  Compute delivery status using required date vs actual goods arrival date.
  Possible outputs: "Delayed", "Early", "On Time", "Unknown".
*/
function calculateStatus(requiredDate, deliveryDate) {
  try {
    const required = new Date(requiredDate);
    const delivery = new Date(deliveryDate);

    if (!Number.isFinite(required.getTime()) || !Number.isFinite(delivery.getTime())) {
      return "Unknown";
    }

    if (delivery > required) return "Delayed";
    if (delivery < required) return "Early";

    return "On Time";
  } catch {
    return "Unknown";
  }
}

/*
  Returns a cached view of procurement items and upcoming deliveries.
  Flow:
  1) Check cache specific to the sheetUrl AND userId
  2) Fetch raw sheet rows based on sheetUrl
  3) Enrich each row with a status
  4) Filter invalid dates
  5) Sort by goods date
  6) Slice into main list + upcoming list
*/
export async function getProcurementView(sheetUrl, userId) {
  const now = Date.now();
  // Create a unique cache key that includes both sheetUrl and userId
  // This ensures each user gets their own cached data
  const cacheKey = `${userId || 'anon'}:${sheetUrl || 'default'}`;

  /*
    If we still have fresh data in memory (within CACHE_TTL),
    return it immediately to keep the API fast.
  */
  const cached = cache.get(cacheKey);
  if (cached && now - cached.lastFetch < CACHE_TTL) {
    return cached.data;
  }

  /*
    Fetch raw data from Google Sheets using the user's specific URL.
    Each row is a procurement record coming from the spreadsheet.
  */
  const raw = await fetchProcurementData(sheetUrl);

  /*
    Add a computed status field to each row, but keep
    the original date strings (we only parse for comparison).
  */
  const parsed = raw.map((r) => ({
  ...r,
  status: calculateStatus(
    r.requiredDateCMS,
    r.revisedDeliveryToSite
  ),
}));

  /*
    Filter out entries without a valid revisedDeliveryToSite date.
    We need a real date to sort and to show upcoming deliveries.
    Also filter out past dates - only show today and future deliveries.
  */
  const today = new Date();
  today.setHours(0, 0, 0, 0); // Reset to start of day for accurate comparison

  const withDates = parsed.filter((p) => {
    if (!p.revisedDeliveryToSite) return false;
    const deliveryDate = new Date(p.revisedDeliveryToSite);
    const time = deliveryDate.getTime();
    if (!Number.isFinite(time)) return false;
    
    // Only include deliveries that are today or in the future
    deliveryDate.setHours(0, 0, 0, 0);
    return deliveryDate >= today;
  });

  /*
    Sort by revisedDeliveryToSite ascending (earliest first).
    This helps us show the soonest deliveries at the top.
  */
  withDates.sort(
    (a, b) =>
      new Date(a.revisedDeliveryToSite).getTime() -
      new Date(b.revisedDeliveryToSite).getTime()
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
    materialList: d.materialList,
    revisedDeliveryToSite: d.revisedDeliveryToSite,
    status: d.status,
  }));

  /*
    Save results to cache so we can reuse for the next request from this user.
  */
  const viewData = { procurementItems, upcomingDeliveries };
  cache.set(cacheKey, { data: viewData, lastFetch: Date.now() });

  return viewData;
}
