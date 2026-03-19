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

    let raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (!raw) {
        console.warn("[Firebase] FIREBASE_SERVICE_ACCOUNT_JSON not set. Firebase disabled.");
        return null;
    }

    try {
        // Strip wrapping quotes or stray characters some env var UIs add
        raw = raw.trim();

        // Railway sometimes prepends " =" when importing from .env files
        // e.g. the value becomes " ={...}" instead of "{...}"
        const jsonStart = raw.indexOf('{');
        if (jsonStart > 0) {
            console.warn(`[Firebase] Stripping ${jsonStart} unexpected leading chars from env var`);
            raw = raw.substring(jsonStart);
        }

        if ((raw.startsWith("'") && raw.endsWith("'")) ||
            (raw.startsWith('"') && raw.endsWith('"') && !raw.startsWith('{"'))) {
            raw = raw.slice(1, -1);
        }

        let serviceAccount;
        try {
            serviceAccount = JSON.parse(raw);
        } catch (parseErr) {
            // If JSON.parse fails, it might be because the raw string has
            // literal \\n that confuses the parser. Replace them first.
            console.warn("[Firebase] Initial JSON.parse failed, trying with newline fix...");
            const fixed = raw.replace(/\\\\n/g, '\\n');
            serviceAccount = JSON.parse(fixed);
        }

        console.log(`[Firebase] Parsed OK – project_id=${serviceAccount.project_id}, type=${serviceAccount.type}`);

        // Fix escaped newlines in the private key.
        // After JSON.parse, the private_key may contain literal "\n" text
        // (two chars: backslash + n) instead of actual newline characters.
        // This happens when env vars store \\n which JSON decodes to \n text.
        if (serviceAccount.private_key) {
            serviceAccount.private_key = serviceAccount.private_key
                .replace(/\\n/g, '\n')   // literal \n text → real newline
                .replace(/\\\\n/g, '\n'); // double-escaped → real newline
        }

        if (!serviceAccount.project_id || !serviceAccount.client_email || !serviceAccount.private_key) {
            console.error("[Firebase] Service account JSON is missing required fields (project_id, client_email, or private_key).");
            return null;
        }

        const app = admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            storageBucket: `${serviceAccount.project_id}.appspot.com`,
        });
        console.log("[Firebase] Admin SDK initialised successfully.");
        return app;
    } catch (err) {
        console.error("[Firebase] Failed to initialise Admin SDK:", err.message);
        // Log the first 80 chars of the raw value for debugging (no secrets leaked)
        console.error(`[Firebase] Raw env var (first 80 chars): ${raw.substring(0, 80)}`);
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
