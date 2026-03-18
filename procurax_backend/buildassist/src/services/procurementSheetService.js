/**
 * Compute delivery status using required date vs actual delivery date.
 * Mirrors procurement.service.js logic exactly.
 */
const calculateStatus = (requiredDate, deliveryDate) => {
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
};

/**
 * Parse procurement sheet rows using the EXACT same column mapping
 * as the procurement page's procument/lib/googleSheets.js:
 *   B(1)  = materialList       D(3)  = responsibility
 *   J(9)  = openingLC          K(10) = etd
 *   L(11) = eta                M(12) = boiApproval
 *   O(14) = revisedDeliveryToSite    P(15) = requiredDateCMS
 */
export const parseProcurementSheet = (rows) => {
  if (!rows || rows.length === 0) return [];

  const procurementItems = [];

  console.log(`Processing ${rows.length} rows from sheet`);

  // Debug: log first 3 rows to see actual data structure
  for (let d = 0; d < Math.min(3, rows.length); d++) {
    console.log(`  Row ${d}: [${rows[d].map((c, idx) => idx + ':"' + c + '"').join(', ')}]`);
  }

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];

    // Skip empty rows
    if (!row || row.length === 0) continue;

    // Column B (index 1) is materialList — the primary identifier
    const materialList = row[1] ? row[1].toString().trim() : '';

    // Skip rows with no material name
    if (!materialList) continue;

    const responsibility        = (row[3]  ?? '').toString().trim();
    const openingLC             = (row[9]  ?? '').toString().trim();
    const etd                   = (row[10] ?? '').toString().trim();
    const eta                   = (row[11] ?? '').toString().trim();
    const boiApproval           = (row[12] ?? '').toString().trim();
    const revisedDeliveryToSite = (row[14] ?? '').toString().trim();
    const requiredDateCMS       = (row[15] ?? '').toString().trim();

    const item = {
      id: `item-${i + 1}`,
      // Primary fields — identical to procurement page data model
      materialList,
      responsibility,
      openingLC,
      etd,
      eta,
      boiApproval,
      revisedDeliveryToSite,
      requiredDateCMS,
      // Computed status — same logic as procurement.service.js
      status: calculateStatus(requiredDateCMS, revisedDeliveryToSite),
      // Extra fields for BuildAssist search/filtering
      category: detectCategory(materialList),
      parentCategory: '',
      // Legacy alias so enrichProcurementItems search still works
      material: materialList,
    };

    console.log(`  Parsed item: material="${item.materialList}", resp="${item.responsibility}", etd="${item.etd}", eta="${item.eta}"`);
    procurementItems.push(item);
  }

  console.log(`Parsed ${procurementItems.length} procurement items`);
  return procurementItems;
};const detectCategory = (materialName) => {
  if (!materialName) return 'General';
  const name = materialName.toLowerCase();
  if (name.includes('steel') || name.includes('reinforcement') || name.includes('bar')) return 'Steel & Reinforcement';
  if (name.includes('cement') || name.includes('concrete')) return 'Cement & Concrete';
  if (name.includes('sand') || name.includes('gravel') || name.includes('aggregate')) return 'Aggregates';
  if (name.includes('brick') || name.includes('block')) return 'Masonry';
  if (name.includes('pipe') || name.includes('plumbing') || name.includes('pvc')) return 'Plumbing';
  if (name.includes('cable') || name.includes('electrical') || name.includes('wire')) return 'Electrical';
  if (name.includes('glass') || name.includes('window')) return 'Glass & Windows';
  if (name.includes('paint') || name.includes('finish')) return 'Finishes';
  if (name.includes('tile') || name.includes('floor')) return 'Flooring';
  return 'General';
};