import mongoose from "mongoose";

const documentSchema = new mongoose.Schema({
  filename: {
    type: String,
    required: true
  },
  originalName: {
    type: String,
    required: true
  },
  fileType: {
    type: String,
    required: true,
    enum: ['image', 'video', 'document', 'blueprint', 'report', 'other']
  },
  mimeType: {
    type: String,
    required: true
  },
  size: {
    type: Number,
    required: true
  },
  path: {
    type: String,
    required: true
  },
  category: {
    type: String,
    required: true,
    enum: ['Site Photos', 'Blueprints', 'Progress Reports', 'Videos', 'Other']
  },
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  description: {
    type: String,
    default: ''
  },
  tags: [{
    type: String
  }],
  isPublic: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update timestamp on save
documentSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Create indexes for better query performance
documentSchema.index({ uploadedBy: 1, category: 1 });
documentSchema.index({ createdAt: -1 });

const Document = mongoose.model('Document', documentSchema);
export default Document;