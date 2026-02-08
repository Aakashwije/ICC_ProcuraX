import mongoose from 'mongoose';

const settingSchema = new mongoose.Schema({
  key: { 
    type: String, 
    required: true 
  },
  value: { 
    type: mongoose.Schema.Types.Mixed, // Can store any type
    required: true 
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  category: {
    type: String,
    enum: ['appearance', 'notifications', 'privacy', 'general'],
    default: 'general'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Compound unique index - each user can have only one setting per key
settingSchema.index({ userId: 1, key: 1 }, { unique: true });

const Setting = mongoose.model('Setting', settingSchema);
export default Setting;