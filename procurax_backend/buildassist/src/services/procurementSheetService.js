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
    
    const colA = row[0] ? row[0].toString().trim() : '';
    
    // Skip if column A is empty (no material name)
    if (!colA) continue;
    
    // Actual sheet structure:
    // Column A: Material Name
    // Column B: Quantity
    // Column C: Order Date / ETD
    // Column D: Delivery Date / ETA
    // (additional columns if present)
    const item = {
      id: `item-${i + 1}`,
      material: colA,                          // Column A: Material Name
      quantity: row[1] || '',                   // Column B: Quantity
      category: detectCategory(colA),           // Auto-detect category from material name
      parentCategory: '',
      source: '',
      responsibility: '',
      initialSubmission: '',
      materialApplication: '',
      approvedByConsultant: '',
      shopDrawingSubmission: '',
      proFormaInvoice: '',
      openingLC: '',
      etd: row[2] || '',                        // Column C: Order/ETD Date
      eta: row[3] || '',                        // Column D: Delivery/ETA Date
      boiApproval: '',
      clearingPort: '',
      revisedDelivery: row[3] || '',             // Use delivery date as revised delivery
      requiredDate: row[4] || '',                // Column E: Required Date (if exists)
      remarks: row[5] || '',                     // Column F: Remarks (if exists)
      draftLCAmount: row[6] || '',               // Column G: Amount (if exists)
      status: row[5] ? parseStatus(row[5]) : 'In Progress',
      type: 'Local'
    };
    
    console.log(`  Parsed item: material="${item.material}", qty=${item.quantity}, etd=${item.etd}, eta=${item.eta}`);
    procurementItems.push(item);
  }
  
  console.log(`Parsed ${procurementItems.length} procurement items`);
  return procurementItems;
};

const detectCategory = (materialName) => {
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

const parseStatus = (remarks) => {
  if (!remarks) return 'In Progress';
  const remarks_lower = remarks.toLowerCase();
  if (remarks_lower.includes('c drawing pending')) return 'Drawing Pending';
  if (remarks_lower.includes('completed') || remarks_lower === 'c') return 'Completed';
  if (remarks_lower.includes('pending')) return 'Pending';
  if (remarks_lower.includes('not confirmed')) return 'Not Confirmed';
  return 'In Progress';
};