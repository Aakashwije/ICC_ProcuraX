import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const UserSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true
    },

    firstName: {
      type: String,
      trim: true,
      default: ""
    },

    lastName: {
      type: String,
      trim: true,
      default: ""
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },

    phone: {
      type: String,
      default: ""
    },

    profileImage: {
      type: String,
      default: ""
    },

    password: {
      type: String,
      required: true,
      minlength: 6,
      select: false
    },

    role: {
      type: String,
      enum: ["admin", "project_manager"],
      default: "project_manager"
    },

    isApproved: {
      type: Boolean,
      default: false
    },

    isActive: {
      type: Boolean,
      default: true
    },

    googleSheetUrl: {
      type: String,
      default: null
    },

    lastLogin: {
      type: Date,
      default: null
    },

    resetPasswordOTP: {
      type: String,
      default: null,
      select: false
    },

    resetPasswordExpiry: {
      type: Date,
      default: null,
      select: false
    },

    // ── Production security fields ──
    resetPasswordAttempts: {
      type: Number,
      default: 0,
      select: false
    },

    resetPasswordLockedUntil: {
      type: Date,
      default: null,
      select: false
    },

    lastResetRequestAt: {
      type: Date,
      default: null,
      select: false
    },

    resetRequestCount: {
      type: Number,
      default: 0,
      select: false
    },

    // ── FCM push notification tokens (one per device) ──
    fcmTokens: {
      type: [String],
      default: [],
      select: false
    }
  },
  {
    timestamps: true
  }
);


// 🔐 Normalize name (from first/last) and hash password
UserSchema.pre("save", async function (next) {
  // If first/last name are provided, keep the full name field in sync.
  if (this.firstName || this.lastName) {
    this.name = `${this.firstName || ""} ${this.lastName || ""}`.trim();
  }

  if (!this.isModified("password")) return next();

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// 🔑 Compare password
UserSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

export default mongoose.model("User", UserSchema);
