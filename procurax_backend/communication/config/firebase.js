import "../../config/env.js";
import admin from "firebase-admin";

let db = null;
let bucket = null;
let isInitialized = false;

// Lazy initialization - reuse existing Firebase app or create new one
function initializeFirebase() {
  if (isInitialized) return;

  try {
    // Check if Firebase is already initialized by another module
    if (admin.apps.length > 0) {
      db = admin.firestore();
      bucket = admin.storage().bucket();
      isInitialized = true;
      return;
    }

    if (!process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      console.warn("  FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set. Firebase features will be disabled.");
      return;
    }

    // convert the JSON string back to an object
    const serviceAccount = JSON.parse(
      process.env.FIREBASE_SERVICE_ACCOUNT_JSON
    );

    // Fix for escaped new lines in the private key
    serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');

    // Initialize Firebase admin
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      storageBucket: `${serviceAccount.project_id}.appspot.com`,
    });

    // Firebase instances
    db = admin.firestore();
    bucket = admin.storage().bucket();
    isInitialized = true;
  } catch (error) {
    console.error(" Failed to initialize Firebase:", error.message);
  }
}

// Initialize on first import
initializeFirebase();

//Export the admin, db, and bucket instances
export { admin, db, bucket };
