
export const parseProcurementSheet = (rows) => {
  if (!rows || rows.length < 4) return [];
  
  const procurementItems = [];
  let currentCategory = '';
  
  // Skip header rows (first 3 rows are headers)
  for (let i = 3; i < rows.length; i++) {
    const row = rows[i];
    if (!row || row.length < 2) continue;
    
    // Check if this is a category header (like "Electrical", "PLUMBING", etc.)
    if (row[1] && row[1].trim() !== '' && !row[1].match(/^\d+$/)) {
      currentCategory = row[1].trim();
      continue;
    }
    
    // Check if this is a material row (has a number in first column)
    const itemNumber = row[0] ? row[0].toString().trim() : '';
    if (itemNumber.match(/^\d+$/)) {
      const item = {
        id: itemNumber,
        category: currentCategory,
        material: row[1] || '',
        source: row[2] || '',
        responsibility: row[3] || '',
        
        // Dates
        initialSubmission: row[4] || '',
        materialApplication: row[5] || '',
        approvedByConsultant: row[6] || '',
        shopDrawingSubmission: row[7] || '',
        proFormaInvoice: row[8] || '',
        openingLC: row[9] || '',
        etd: row[10] || '',
        eta: row[11] || '',
        boiApproval: row[12] || '',
        clearingPort: row[13] || '',
        revisedDelivery: row[14] || '',
        requiredDate: row[15] || '',
        
        remarks: row[16] || '',
        draftLCAmount: row[17] || '',
        
        // Parse status from remarks
        status: parseStatus(row[16] || ''),
        
        // Check if import or local
        type: row[2] === 'I' ? 'Import' : row[2] === 'L' ? 'Local' : 'Unknown'
      };
      
      procurementItems.push(item);
    }
  }
  
  return procurementItems;
};

const parseStatus = (remarks) => {
  const remarks_lower = remarks.toLowerCase();
  if (remarks_lower.includes('c drawing pending')) return 'Drawing Pending';
  if (remarks_lower.includes('completed') || remarks_lower.includes('c')) return 'Completed';
  if (remarks_lower.includes('pending')) return 'Pending';
  if (remarks_lower.includes('not confirmed')) return 'Not Confirmed';
  return 'In Progress';
};