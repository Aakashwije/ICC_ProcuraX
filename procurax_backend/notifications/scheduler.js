/**
 * ============================================================================
 * Notification Scheduler
 * ============================================================================
 *
 * Runs periodic checks to send push-notification reminders for:
 *   1. Tasks due tomorrow
 *   2. Meetings starting tomorrow
 *
 * The scheduler uses setInterval (no cron dependency needed) and runs once
 * every hour.  A simple in-memory Set tracks which items have already been
 * notified today so users are not spammed.
 *
 * Call `startScheduler()` once from app.js after the DB is connected.
 */

import Task from "../tasks/tasks.model.js";
import Meeting from "../meetings/models/Meeting.js";
import User from "../models/User.js";
import admin from "firebase-admin";
import getFirebaseApp from "../config/firebase.js";

/* ─────────────────────────────────────────────────────────────────────
   State: track which reminders have been sent today to avoid duplicates
────────────────────────────────────────────────────────────────────── */
let notifiedTaskIds = new Set();
let notifiedMeetingIds = new Set();
let lastResetDate = new Date().toDateString();

/**
 * Reset the notified sets at midnight so reminders fire again the next day.
 */
function resetIfNewDay() {
  const today = new Date().toDateString();
  if (today !== lastResetDate) {
    notifiedTaskIds = new Set();
    notifiedMeetingIds = new Set();
    lastResetDate = today;
    console.log("[Scheduler] New day — reset reminder tracking");
  }
}

/* ─────────────────────────────────────────────────────────────────────
   Helper: send FCM push to a single user
────────────────────────────────────────────────────────────────────── */
async function sendReminderPush(userId, { title, body, data = {} }) {
  try {
    const app = getFirebaseApp();
    if (!app) return;

    const user = await User.findById(userId).select("+fcmTokens").lean();
    if (!user?.fcmTokens?.length) return;

    const messaging = admin.messaging();

    const messages = user.fcmTokens.map((token) => ({
      token,
      notification: { title, body },
      data: {
        ...Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "procurax_notifications",
          sound: "default",
        },
      },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
    }));

    const response = await messaging.sendEach(messages);

    // Remove stale tokens
    const tokensToRemove = [];
    response.responses.forEach((resp, idx) => {
      if (resp.error) {
        const code = resp.error.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          tokensToRemove.push(user.fcmTokens[idx]);
        }
      }
    });

    if (tokensToRemove.length > 0) {
      await User.findByIdAndUpdate(userId, {
        $pull: { fcmTokens: { $in: tokensToRemove } },
      });
    }

    console.log(
      `[Scheduler] Push sent to user ${userId}: ${response.successCount}/${messages.length}`
    );
  } catch (err) {
    console.error("[Scheduler] Push error:", err.message);
  }
}

/* ─────────────────────────────────────────────────────────────────────
   Check tasks due tomorrow and send reminders
────────────────────────────────────────────────────────────────────── */
async function checkTaskReminders() {
  try {
    // Tomorrow's date range: midnight → 23:59:59
    const now = new Date();
    const tomorrowStart = new Date(now);
    tomorrowStart.setDate(tomorrowStart.getDate() + 1);
    tomorrowStart.setHours(0, 0, 0, 0);

    const tomorrowEnd = new Date(tomorrowStart);
    tomorrowEnd.setHours(23, 59, 59, 999);

    const tasks = await Task.find({
      dueDate: { $gte: tomorrowStart, $lte: tomorrowEnd },
      isArchived: { $ne: true },
      status: { $ne: "done" },
    }).lean();

    for (const task of tasks) {
      const key = task._id.toString();
      if (notifiedTaskIds.has(key)) continue;

      notifiedTaskIds.add(key);

      const dueStr = new Date(task.dueDate).toLocaleDateString("en-GB", {
        weekday: "short",
        day: "numeric",
        month: "short",
      });

      await sendReminderPush(task.owner, {
        title: `⏰ Task Due Tomorrow`,
        body: `"${task.title}" is due ${dueStr}. Don't forget to complete it!`,
        data: { type: "task_reminder", taskId: key },
      });

      console.log(`[Scheduler] Task reminder sent: "${task.title}" → user ${task.owner}`);
    }
  } catch (err) {
    console.error("[Scheduler] Task reminder error:", err.message);
  }
}

/* ─────────────────────────────────────────────────────────────────────
   Check meetings starting tomorrow and send reminders
────────────────────────────────────────────────────────────────────── */
async function checkMeetingReminders() {
  try {
    const now = new Date();
    const tomorrowStart = new Date(now);
    tomorrowStart.setDate(tomorrowStart.getDate() + 1);
    tomorrowStart.setHours(0, 0, 0, 0);

    const tomorrowEnd = new Date(tomorrowStart);
    tomorrowEnd.setHours(23, 59, 59, 999);

    const meetings = await Meeting.find({
      startTime: { $gte: tomorrowStart, $lte: tomorrowEnd },
      done: { $ne: true },
    }).lean();

    for (const meeting of meetings) {
      const key = meeting._id.toString();
      if (notifiedMeetingIds.has(key)) continue;

      notifiedMeetingIds.add(key);

      const timeStr = new Date(meeting.startTime).toLocaleTimeString("en-GB", {
        hour: "2-digit",
        minute: "2-digit",
      });

      await sendReminderPush(meeting.owner, {
        title: `📅 Meeting Tomorrow`,
        body: `"${meeting.title}" starts at ${timeStr}${meeting.location ? ` at ${meeting.location}` : ""}. Be prepared!`,
        data: { type: "meeting_reminder", meetingId: key },
      });

      console.log(`[Scheduler] Meeting reminder sent: "${meeting.title}" → user ${meeting.owner}`);
    }
  } catch (err) {
    console.error("[Scheduler] Meeting reminder error:", err.message);
  }
}

/* ─────────────────────────────────────────────────────────────────────
   Main scheduler loop — called by app.js once
────────────────────────────────────────────────────────────────────── */
const ONE_HOUR = 60 * 60 * 1000;

export function startScheduler() {
  console.log("[Scheduler] Starting notification scheduler (runs every hour)");

  // Run immediately on startup, then every hour
  const runAll = async () => {
    resetIfNewDay();
    await checkTaskReminders();
    await checkMeetingReminders();
  };

  // Initial run after a short delay to let DB connections settle
  setTimeout(runAll, 10_000);

  // Then repeat every hour
  setInterval(runAll, ONE_HOUR);
}
