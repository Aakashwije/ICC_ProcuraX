export const parseProcurementSheet = (rows) => {
  if (!rows || rows.length === 0) return [];
  
  const procurementItems = [];
  let currentCategory = '';
  
  console.log(`Processing ${rows.length} rows from sheet`);
  
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    
    // Skip completely empty rows
    if (!row || row.length === 0 || row.every(cell => !cell)) {
      continue;
    }
    
    // Check if this is a category header
    // Category rows usually have first column empty and second column with category name
    if ((!row[0] || row[0] === '') && row[1] && row[1].trim() !== '') {
      // Check if it's a category (like "Electrical", "PLUMBING", etc.)
      const possibleCategory = row[1].trim();
      // Make sure it's not a material name
      if (!possibleCategory.match(/^\d/) && possibleCategory.length < 30) {
        currentCategory = possibleCategory;
        console.log(`Found category: ${currentCategory} at row ${i}`);
      }
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
        
        // Handle formula cells - they come as strings
        initialSubmission: row[4] ? row[4].toString().replace('=O', '') : '',
        materialApplication: row[5] ? row[5].toString().replace('=O', '') : '',
        approvedByConsultant: row[6] ? row[6].toString().replace('=H', '') : '',
        shopDrawingSubmission: row[7] ? row[7].toString() : '',
        proFormaInvoice: row[8] ? row[8].toString() : '',
        openingLC: row[9] ? row[9].toString() : '',
        etd: row[10] ? row[10].toString() : '',
        eta: row[11] ? row[11].toString() : '',
        boiApproval: row[12] ? row[12].toString() : '',
        clearingPort: row[13] ? row[13].toString() : '',
        revisedDelivery: row[14] ? row[14].toString() : '',
        requiredDate: row[15] ? row[15].toString() : '',
        
        remarks: row[16] || '',
        draftLCAmount: row[17] || '',
        
        status: parseStatus(row[16] || ''),
        type: row[2] === 'I' ? 'Import' : row[2] === 'L' ? 'Local' : 'Unknown'
      };
      
      procurementItems.push(item);
    }
  }
  
  console.log(`Parsed ${procurementItems.length} procurement items`);
  return procurementItems;
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