import User from '../models/user.js';
import Setting from '../models/setting.js';
import { generateToken } from '../authMiddleware.js';

// Get all users
export const getAllUsers = async (req, res) => {
  try {
    const users = await User.find().select('-password').sort({ createdAt: -1 });
    
    res.json({
      success: true,
      count: users.length,
      data: users
    });
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ 
      success: false,
      message: 'Server error',
      error: err.message 
    });
  }
};

// Register new user
export const addUser = async (req, res) => {
  try {
    const { email, password, firstName, lastName, ...otherData } = req.body;
    
    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered'
      });
    }
    
    // Create user
    const user = new User({
      email,
      password,
      firstName: firstName || '',
      lastName: lastName || '',
      ...otherData
    });
    
    await user.save();
    
    // Create default settings for user
    const defaultSettings = [
      { userId: user._id, key: 'theme', value: 'Light', category: 'appearance' },
      { userId: user._id, key: 'notifications_email', value: true, category: 'notifications' },
      { userId: user._id, key: 'notifications_alerts', value: true, category: 'notifications' },
      { userId: user._id, key: 'timezone', value: 'UTC', category: 'general' }
    ];
    
    await Setting.insertMany(defaultSettings);
    
    // Generate token
    const token = generateToken(user._id);
    
    // Get user without password
    const userResponse = await User.findById(user._id).select('-password');
    
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: userResponse,
      token
    });
  } catch (err) {
    console.error('Error creating user:', err);
    res.status(400).json({ 
      success: false,
      message: 'Error creating user',
      error: err.message 
    });
  }
};

// User login
export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }
    
    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }
    
    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }
    
    // Update last login
    user.lastLogin = new Date();
    await user.save();
    
    // Generate token
    const token = generateToken(user._id);
    
    // Get user without password
    const userResponse = await User.findById(user._id).select('-password');
    
    res.json({
      success: true,
      message: 'Login successful',
      data: userResponse,
      token
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: err.message
    });
  }
};

// Update user profile
export const updateUserProfile = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    // Remove password from update data (use separate endpoint for password change)
    if (updateData.password) {
      delete updateData.password;
    }
    
    // Find and update user
    const user = await User.findByIdAndUpdate(
      id,
      { ...updateData, updatedAt: new Date() },
      { new: true, runValidators: true }
    ).select('-password');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // If theme is updated, also update settings
    if (updateData.theme) {
      await Setting.findOneAndUpdate(
        { userId: id, key: 'theme' },
        { value: updateData.theme, updatedAt: new Date() },
        { upsert: true }
      );
    }
    
    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: user
    });
  } catch (err) {
    console.error('Update error:', err);
    res.status(400).json({
      success: false,
      message: 'Error updating profile',
      error: err.message
    });
  }
};

// Get current user
export const getCurrentUser = async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('-password');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    res.json({
      success: true,
      data: user
    });
  } catch (err) {
    console.error('Get user error:', err);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: err.message
    });
  }
};