export const parseProcurementSheet = (rows) => {
  if (!rows || rows.length === 0) return [];
  
  const procurementItems = [];
  let currentCategory = '';
  
  console.log(`Processing ${rows.length} rows from sheet`);
  
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    
    // Skip empty rows
    if (!row || row.length === 0 || row.every(cell => !cell)) {
      continue;
    }
    
    // Check if this is a category row (has category in column B, no number in column A)
    if ((!row[0] || row[0] === '') && row[1] && row[1].trim() !== '') {
      // This is a category (like "Electrical", "Low Voltage System")
      currentCategory = row[1].trim();
      console.log(`Found category: ${currentCategory} at row ${i}`);
      continue;
    }
    
    // Check if this is a material row (has a number in column A)
    const itemNumber = row[0] ? row[0].toString().trim() : '';
    if (itemNumber.match(/^\d+$/)) {
      const item = {
        id: itemNumber,
        category: currentCategory, // Uses the last seen category
        material: row[1] || '',          // Column B: Material
        source: row[2] || '',             // Column C: Source (I/L)
        responsibility: row[3] || '',      // Column D: Responsibility
        initialSubmission: row[4] || '',   // Column E: Initial Submission
        materialApplication: row[5] || '', // Column F: Submission of Material Application
        approvedByConsultant: row[6] || '', // Column G: Approved by Consultant
        shopDrawingSubmission: row[7] || '', // Column H: Shop drawing submission
        proFormaInvoice: row[8] || '',     // Column I: Pro-forma Invoice
        openingLC: row[9] || '',            // Column J: Opening L/C
        etd: row[10] || '',                 // Column K: ETD
        eta: row[11] || '',                  // Column L: ETA
        boiApproval: row[12] || '',          // Column M: BOI Approval
        clearingPort: row[13] || '',         // Column N: Clearing of Port
        revisedDelivery: row[14] || '',      // Column O: Revised Delivery to Site
        requiredDate: row[15] || '',         // Column P: Required Date
        remarks: row[16] || '',              // Column Q: Remarks
        draftLCAmount: row[17] || '',        // Column R: Draft LC amount
        
        status: parseStatus(row[16] || ''),  // Status from Remarks
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