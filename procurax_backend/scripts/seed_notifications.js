/**
 * Seed Test Notifications
 * 
 * This script creates sample notifications for all users in the database.
 * Run with: node scripts/seed_notifications.js
 */

import mongoose from 'mongoose';
import '../config/env.js';
import Notification from '../notifications/notification.model.js';
import User from '../models/User.js';

const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/procurax';

const sampleNotifications = [
  {
    title: 'New Project Assigned',
    message: 'You have been assigned to the "City Mall Construction" project. Please review the project details and timeline.',
    type: 'projects',
    priority: 'high',
    projectName: 'City Mall Construction',
    projectStatus: 'active'
  },
  {
    title: 'Task Due Tomorrow',
    message: 'The task "Submit Foundation Report" is due tomorrow. Please ensure completion.',
    type: 'tasks',
    priority: 'critical'
  },
  {
    title: 'Meeting Scheduled',
    message: 'A project kickoff meeting has been scheduled for March 10, 2026 at 10:00 AM.',
    type: 'meetings',
    priority: 'medium'
  },
  {
    title: 'Procurement Order Delivered',
    message: 'Your order for steel reinforcement bars has been delivered to the construction site.',
    type: 'procurement',
    priority: 'low'
  },
  {
    title: 'Project Status Updated',
    message: 'The "Highway Extension" project status has been changed from "On Hold" to "Active".',
    type: 'projects',
    priority: 'medium',
    projectName: 'Highway Extension',
    projectStatus: 'active'
  },
  {
    title: 'System Maintenance',
    message: 'Scheduled maintenance will occur on March 15, 2026 from 2:00 AM to 4:00 AM.',
    type: 'general',
    priority: 'low'
  },
  {
    title: 'Task Completed',
    message: 'The task "Site Inspection" has been marked as completed by your team member.',
    type: 'tasks',
    priority: 'low'
  },
  {
    title: 'Urgent: Material Shortage',
    message: 'Critical shortage of cement detected. Immediate procurement action required.',
    type: 'procurement',
    priority: 'critical'
  }
];

async function seedNotifications() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('Connected to MongoDB');

    // Find all users
    const users = await User.find({}).select('_id email name');
    
    if (users.length === 0) {
      console.log('No users found in the database. Please create a user first.');
      process.exit(1);
    }

    console.log(`Found ${users.length} user(s). Creating notifications...`);

    for (const user of users) {
      console.log(`\nCreating notifications for user: ${user.email || user._id}`);
      
      // Check existing notifications count
      const existingCount = await Notification.countDocuments({ owner: user._id });
      console.log(`  Existing notifications: ${existingCount}`);

      // Create new notifications
      for (const notif of sampleNotifications) {
        const notification = new Notification({
          owner: user._id,
          ...notif,
          isRead: Math.random() > 0.7 // 30% chance of being read
        });
        await notification.save();
      }
      
      console.log(`  Created ${sampleNotifications.length} new notifications`);
    }

    const totalCount = await Notification.countDocuments();
    console.log(`\n✅ Done! Total notifications in database: ${totalCount}`);
    
    process.exit(0);
  } catch (error) {
    console.error('Error seeding notifications:', error);
    process.exit(1);
  }
}

seedNotifications();
