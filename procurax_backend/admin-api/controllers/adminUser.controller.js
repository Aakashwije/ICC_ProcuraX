/**
 * adminUser.controller.js
 *
 * User-defined controller functions for admin management of mobile app users.
 * Handles listing, approving, rejecting, and assigning sheet URLs to users.
 * All mutations are synced to Firebase Firestore for cloud persistence.
 */

import User from "../../models/User.js";
import { syncUserToFirestore, updateUserSheetUrlInFirestore } from "../../config/firebase.js";

/* ─────────────────────────────────────────────────────────────────────────
   buildUserPayload
   Shapes a User document into the response object the admin dashboard needs.
────────────────────────────────────────────────────────────────────────── */
function buildUserPayload(user) {
  return {
    _id: user._id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    isApproved: user.isApproved,
    isActive: user.isActive,
    googleSheetUrl: user.googleSheetUrl ?? null,
    createdAt: user.createdAt
  };
}

/* ─────────────────────────────────────────────────────────────────────────
   getUsers
   GET /admin-users
   Returns all non-admin users, sorted newest first.
────────────────────────────────────────────────────────────────────────── */
export const getUsers = async (req, res) => {
  try {
    const { approved } = req.query;
    const filter = { role: { $ne: "admin" } };

    if (approved === "true") filter.isApproved = true;
    else if (approved === "false") filter.isApproved = false;

    const users = await User.find(filter)
      .select("-password")
      .sort({ createdAt: -1 });

    res.json({ success: true, users: users.map(buildUserPayload) });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ─────────────────────────────────────────────────────────────────────────
   approveUser
   PATCH /admin-users/:id/approve
   Approves a user so they can log into the mobile app.
   Syncs the updated status to Firestore.
────────────────────────────────────────────────────────────────────────── */
export const approveUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByIdAndUpdate(
      id,
      { isApproved: true, isActive: true },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    /* Sync to Firestore so the approval is visible in the cloud */
    await syncUserToFirestore(user._id.toString(), {
      name: user.name,
      email: user.email,
      role: user.role,
      isApproved: true,
      googleSheetUrl: user.googleSheetUrl ?? null
    });

    res.json({ success: true, user: buildUserPayload(user) });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ─────────────────────────────────────────────────────────────────────────
   rejectUser
   PATCH /admin-users/:id/reject
   Rejects a user, blocking them from logging in.
────────────────────────────────────────────────────────────────────────── */
export const rejectUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByIdAndUpdate(
      id,
      { isApproved: false, isActive: false },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    /* Sync rejection to Firestore */
    await syncUserToFirestore(user._id.toString(), {
      isApproved: false,
      isActive: false
    });

    res.json({ success: true, user: buildUserPayload(user) });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ─────────────────────────────────────────────────────────────────────────
   assignSheetUrl
   PATCH /admin-users/:id/sheet-url
   Sets the Google / Excel Sheet URL for a specific user.
   The mobile app reads this URL to show the user their procurement schedule.
────────────────────────────────────────────────────────────────────────── */
export const assignSheetUrl = async (req, res) => {
  try {
    const { id } = req.params;
    const { googleSheetUrl } = req.body;

    if (!googleSheetUrl || typeof googleSheetUrl !== "string") {
      return res.status(400).json({ message: "A valid googleSheetUrl string is required." });
    }

    const user = await User.findByIdAndUpdate(
      id,
      { googleSheetUrl: googleSheetUrl.trim() },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    /* Persist the sheet URL to Firestore so the mobile app can also read it */
    await updateUserSheetUrlInFirestore(user._id.toString(), googleSheetUrl.trim());

    res.json({ success: true, user: buildUserPayload(user) });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
