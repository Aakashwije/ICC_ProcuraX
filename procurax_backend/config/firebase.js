/**
 * firebase.js
 * 
 * Firebase Admin SDK singleton for the ProcuraX backend.
 * Provides user-defined helper functions to sync user data
 * to Firestore so it is always persisted in the cloud.
 */

import admin from "firebase-admin";

/* ─────────────────────────────────────────────────────────────────────────
   getFirebaseApp
   Initialises the Admin SDK once and returns the same app on repeat calls.
────────────────────────────────────────────────────────────────────────── */
function getFirebaseApp() {
    if (admin.apps.length > 0) {
        return admin.apps[0];
    }

    const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (!raw) {
        console.warn("[Firebase] FIREBASE_SERVICE_ACCOUNT_JSON not set. Firebase disabled.");
        return null;
    }

    console.log(`[Firebase] Env var length: ${raw.length}, starts with: "${raw.substring(0, 30)}..."`);

    try {
        const serviceAccount = JSON.parse(raw);

        console.log(`[Firebase] Parsed OK. project_id=${serviceAccount.project_id}, has private_key=${!!serviceAccount.private_key}, type=${serviceAccount.type}`);

        // Fix for escaped new lines in the private key
        if (serviceAccount.private_key) {
            serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
        }

        const app = admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            storageBucket: `${serviceAccount.project_id}.appspot.com`,
        });
        console.log("[Firebase] Admin SDK initialised successfully.");
        return app;
    } catch (err) {
        console.error("[Firebase] Failed to initialise Admin SDK:", err.message);
        console.error("[Firebase] Stack:", err.stack);
        return null;
    }
}

/* ─────────────────────────────────────────────────────────────────────────
   getFirestore
   Returns the Firestore instance (or null if SDK failed to init).
────────────────────────────────────────────────────────────────────────── */
function getFirestore() {
    const app = getFirebaseApp();
    if (!app) return null;
    return admin.firestore();
}

/* ─────────────────────────────────────────────────────────────────────────
   syncUserToFirestore
   Writes (merge) a user document to the `users/{uid}` path.
   Called on login and on admin approval so data is always fresh.
────────────────────────────────────────────────────────────────────────── */
export async function syncUserToFirestore(uid, userData) {
    try {
        const db = getFirestore();
        if (!db) return;

        await db.collection("users").doc(uid).set(
            {
                ...userData,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            },
            { merge: true }
        );
    } catch (err) {
        // Non-fatal — log but don't break the main request
        console.error("[Firebase] syncUserToFirestore error:", err.message);
    }
}

/* ─────────────────────────────────────────────────────────────────────────
   updateUserSheetUrlInFirestore
   Updates only the googleSheetUrl field for a given user.
   Called when admin assigns a sheet URL via the dashboard.
────────────────────────────────────────────────────────────────────────── */
export async function updateUserSheetUrlInFirestore(uid, googleSheetUrl) {
    try {
        const db = getFirestore();
        if (!db) return;

        await db.collection("users").doc(uid).set(
            {
                googleSheetUrl,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            },
            { merge: true }
        );
    } catch (err) {
        console.error("[Firebase] updateUserSheetUrlInFirestore error:", err.message);
    }
}

export default getFirebaseApp;
