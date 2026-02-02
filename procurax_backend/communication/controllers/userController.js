// backend/src/controllers/userController.js

import { db } from '../config/firebase.js';

// Get all project managers only
async function getProjectManagers(req, res) {
  try {
    //Query users with role 'project_manager'
    const usersSnapshot = await db
      .collection('users')
      .where('role', '==', 'project_manager')
      .get();

    //Check if any managers found
    if (usersSnapshot.empty) {
      return res.status(404).json({ message: 'No project managers found' });
    }

    //Map documents to array
    const managers = usersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    //Return the list of project managers
    res.json(managers);
  } catch (error) {
    console.error('Error fetching project managers:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
}

// Get all users
async function getAllUsers(req, res) {
  try {
    //Fetch all users
    const usersSnapshot = await db.collection('users').get();

    //Check if any users found
    if (usersSnapshot.empty) {
      return res.status(404).json({ message: 'No users found' });
    }

    //Map documents to array
    const users = usersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    //Return the list of users
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Internal Server Error' }); 
  }
}

// Export functions
export { getProjectManagers, getAllUsers };
