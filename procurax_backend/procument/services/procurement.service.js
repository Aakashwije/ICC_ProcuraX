// procurax_backend/procument/services/procurement.service.js
import { fetchProcurementData } from "../lib/googleSheets.js";

let cachedData = null;
let lastFetch = 0;
const CACHE_TTL = Number(process.env.CACHE_TTL_MS || 60000);

function calculateStatus(cmsDate, goodsDate) {
  try {
    const cms = new Date(cmsDate);
    const goods = new Date(goodsDate);
    if (isNaN(cms) || isNaN(goods)) return "Unknown";
    if (goods > cms) return "Delayed";
    if (goods < cms) return "Early";
    return "On Time";
  } catch (e) {
    return "Unknown";
  }
}

export async function getProcurementView() {
  const now = Date.now();
  if (cachedData && now - lastFetch < CACHE_TTL) {
    return cachedData;
  }

  const raw = await fetchProcurementData();

  // parse date strings into comparable dates and sort by goodsAtLocationDate ascending
  const parsed = raw.map((r) => ({
    ...r,
    // keep original strings but normalized
    cmsRequiredDate: r.cmsRequiredDate,
    goodsAtLocationDate: r.goodsAtLocationDate,
    status: calculateStatus(r.cmsRequiredDate, r.goodsAtLocationDate),
  }));

  // Filter out entries without a valid goodsAtLocationDate
  const withDates = parsed.filter((p) => {
    if (!p.goodsAtLocationDate) return false;
    const time = new Date(p.goodsAtLocationDate).getTime();
    return Number.isFinite(time);
  });

  withDates.sort(
    (a, b) =>
      new Date(a.goodsAtLocationDate).getTime() -
      new Date(b.goodsAtLocationDate).getTime()
  );

  // "Most recent 5" => here we return earliest upcoming 5 (adjust if you meant latest)
  const procurementItems = withDates.slice(0, 5);

  // next 2 after first 5
  const upcomingDeliveries = withDates.slice(5, 7).map((d) => ({
    materialDescription: d.materialDescription,
    goodsAtLocationDate: d.goodsAtLocationDate,
    status: d.status,
  }));

  cachedData = { procurementItems, upcomingDeliveries };
  lastFetch = Date.now();
  return cachedData;
}
