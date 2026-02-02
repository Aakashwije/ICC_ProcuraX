import "../../config/env.js";
import admin from "firebase-admin";

let db = null;
let bucket = null;
let isInitialized = false;

// Lazy initialization - only initialize when needed
function initializeFirebase() {
  if (isInitialized) return;

  if (!process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    console.warn("⚠️  FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set. Firebase features will be disabled.");
    return;
  }

  try {
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

    console.log("✅ Firebase connected to:", serviceAccount.project_id);

    // Firebase instances
    db = admin.firestore();
    bucket = admin.storage().bucket();
    isInitialized = true;
  } catch (error) {
    console.error("❌ Failed to initialize Firebase:", error.message);
  }
}

// Initialize on first import
initializeFirebase();

//Export the admin, db, and bucket instances
export { admin, db, bucket };
