import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  message: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['projects', 'tasks', 'procurement', 'meetings', 'notes', 'communication', 'general'],
    required: true,
    index: true
  },
  priority: {
    type: String,
    enum: ['critical', 'high', 'medium', 'low'],
    default: 'medium',
    index: true
  },
  isRead: {
    type: Boolean,
    default: false,
    index: true
  },
  // Optional project-related fields
  projectName: {
    type: String,
    trim: true
  },
  projectStatus: {
    type: String,
    enum: ['active', 'completed', 'assigned', 'onHold', 'cancelled']
  },
  projectId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Project'
  },
  // Optional reference IDs for different types
  taskId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Task'
  },
  meetingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Meeting'
  },
  noteId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Note'
  },
  procurementId: {
    type: String
  },
  // Optional metadata for additional context
  metadata: {
    type: mongoose.Schema.Types.Mixed
  },
  // Optional action URL
  actionUrl: {
    type: String
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
notificationSchema.index({ owner: 1, createdAt: -1 });
notificationSchema.index({ owner: 1, type: 1 });
notificationSchema.index({ owner: 1, isRead: 1 });
notificationSchema.index({ owner: 1, priority: 1 });

const Notification = mongoose.model('Notification', notificationSchema);

export default Notification;
