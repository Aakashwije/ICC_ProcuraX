// src/controllers/settings.controller.js - SIMPLIFIED
import Setting from '../models/setting.js';

// Get all settings (for current user or default)
export const getSettings = async (req, res) => {
  try {
    // For now, get first settings or create default
    let settings = await Setting.findOne();
    
    if (!settings) {
      // Create default settings
      settings = new Setting({
        key: 'default_settings',
        value: {
          theme: 'Light',
          timezone: 'UTC',
          notifications_email: true,
          notifications_alerts: true
        },
        category: 'app'
      });
      await settings.save();
    }
    
    res.json({
      success: true,
      data: settings.value
    });
  } catch (err) {
    console.error('Error fetching settings:', err);
    res.status(500).json({ 
      success: false,
      message: 'Failed to load settings',
      error: err.message 
    });
  }
};

// Update settings
export const updateMultipleSettings = async (req, res) => {
  try {
    const updates = req.body;
    
    // Find or create settings
    let settings = await Setting.findOne({ key: 'default_settings' });
    
    if (!settings) {
      settings = new Setting({
        key: 'default_settings',
        value: updates,
        category: 'app'
      });
    } else {
      settings.value = { ...settings.value, ...updates };
    }
    
    await settings.save();
    
    res.json({
      success: true,
      message: 'Settings updated successfully',
      data: settings.value
    });
  } catch (err) {
    console.error('Error updating settings:', err);
    res.status(400).json({ 
      success: false,
      message: 'Failed to update settings',
      error: err.message 
    });
  }
};

// Other functions simplified similarly...
export const updateSettings = async (req, res) => {
  // Simplified version
  res.json({ success: true, message: 'Update endpoint (simplified)' });
};

export const getSettingByKey = async (req, res) => {
  // Simplified version
  res.json({ success: true, message: 'Get by key endpoint (simplified)' });
};