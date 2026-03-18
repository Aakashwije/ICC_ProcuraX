// backend/src/controllers/userController.js

import { db } from '../config/firebase.js';

// Get all project managers only
async function getProjectManagers(req, res) {
  try {
    if (!db) {
      return res.status(503).json({ 
        error: 'Firebase is not initialized. Please check server configuration.' 
      });
    }

    const usersSnapshot = await db
      .collection('users')
      .where('role', '==', 'project_manager')
      .get();

    if (usersSnapshot.empty) {
      return res.status(404).json({ message: 'No project managers found' });
    }

    const managers = usersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.json(managers);

  } catch (error) {
    console.error('Error fetching project managers:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}


// Get all users
async function getAllUsers(req, res) {
  try {
    if (!db) {
      return res.status(503).json({ 
        error: 'Firebase is not initialized. Please check server configuration.' 
      });
    }

    const usersSnapshot = await db.collection('users').get();

    if (usersSnapshot.empty) {
      return res.status(404).json({ message: 'No users found' });
    }

    const users = usersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.json(users);

  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

export { getProjectManagers, getAllUsers };