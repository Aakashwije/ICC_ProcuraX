import "./config/env.js";
import { fetchProcurementData } from "./procument/lib/googleSheets.js";

console.log("Starting...");
try {
  const data = await fetchProcurementData("https://docs.google.com/spreadsheets/d/1dKWPVZELlI6nRZF9IOLQSUMOnYw_99dG-9CEDM4RSew/edit?gid=0#gid=0");
  console.log("Success! Extracted rows:", data.length);
} catch (err) {
  console.error("Failed to fetch sheet from Google API:", err.message);
}
console.log("Done.");
