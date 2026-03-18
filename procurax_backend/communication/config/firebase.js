import "../../config/env.js";
import admin from "firebase-admin";
import getFirebaseApp from "../../config/firebase.js";

let db = null;
let bucket = null;
let isInitialized = false;

// Lazy initialization - reuse the main Firebase app singleton
function initializeFirebase() {
  if (isInitialized) return;

  try {
    // Use the main config's getFirebaseApp() which handles initialization
    const app = getFirebaseApp();
    if (!app) {
      console.warn("  Firebase app not available. Communication Firebase features will be disabled.");
      return;
    }

    db = admin.firestore();
    bucket = admin.storage().bucket(`${app.options.projectId || 'default'}.appspot.com`);
    isInitialized = true;
  } catch (error) {
    console.error(" Failed to initialize Firebase for communication:", error.message);
  }
}

// Initialize on first import
initializeFirebase();

//Export the admin, db, and bucket instances
export { admin, db, bucket };
