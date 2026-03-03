# Notifications Module

## Overview
Comprehensive notification system for ProcuraX application supporting multiple notification types with user-scoped access control.

## Features
- ✅ **User Authentication**: All endpoints protected with JWT
- ✅ **User Scoping**: Users only see their own notifications
- ✅ **Multiple Types**: Projects, Tasks, Procurement, Meetings, General
- ✅ **Priority Levels**: Critical, High, Medium, Low
- ✅ **Read/Unread Status**: Track notification states
- ✅ **Filtering**: By type, priority, read status
- ✅ **Bulk Operations**: Update/delete multiple notifications
- ✅ **Statistics**: Get notification counts by type and priority
- ✅ **Pagination**: Limit and skip for large datasets

## API Endpoints

### Base URL
```
/api/notifications
```

All endpoints require JWT authentication via `Authorization: Bearer <token>` header.

### Get All Notifications
```
GET /api/notifications
Query Parameters:
  - type: projects|tasks|procurement|meetings|general
  - priority: critical|high|medium|low
  - isRead: true|false
  - limit: number (default: 50)
  - skip: number (default: 0)

Response:
{
  "notifications": [...],
  "total": 100,
  "unreadCount": 15,
  "hasMore": true
}
```

### Get Single Notification
```
GET /api/notifications/:id
```

### Create Notification
```
POST /api/notifications
Body:
{
  "title": "New Task Assigned",
  "message": "You have been assigned a new task",
  "type": "tasks",
  "priority": "high",
  "taskId": "...",
  "metadata": { ... }
}
```

### Mark as Read
```
PATCH /api/notifications/:id/read
```

### Mark All as Read
```
PATCH /api/notifications/mark-all/read
Query Parameters:
  - type: optional, filter by type
```

### Delete Notification
```
DELETE /api/notifications/:id
```

### Delete All Notifications
```
DELETE /api/notifications/bulk/all
Query Parameters:
  - type: optional, filter by type
  - isRead: optional, filter by read status
```

### Get Statistics
```
GET /api/notifications/stats
Response:
{
  "byType": [
    { "_id": "tasks", "total": 10, "unread": 5 }
  ],
  "byPriority": [
    { "_id": "high", "count": 3 }
  ],
  "totalUnread": 15
}
```

### Bulk Update
```
PATCH /api/notifications/bulk/update
Body:
{
  "ids": ["id1", "id2", ...],
  "isRead": true
}
```

### Bulk Delete
```
DELETE /api/notifications/bulk/delete
Body:
{
  "ids": ["id1", "id2", ...]
}
```

## Notification Types

### 1. Projects
For project-related notifications (creation, updates, assignments, status changes)
```javascript
{
  type: 'projects',
  projectName: 'Project Alpha',
  projectStatus: 'active',
  projectId: ObjectId
}
```

### 2. Tasks
For task-related notifications (assignments, due dates, completions)
```javascript
{
  type: 'tasks',
  taskId: ObjectId
}
```

### 3. Procurement
For procurement-related notifications (orders, shipments, deliveries)
```javascript
{
  type: 'procurement',
  procurementId: String
}
```

### 4. Meetings
For meeting-related notifications (scheduling, reminders, cancellations)
```javascript
{
  type: 'meetings',
  meetingId: ObjectId
}
```

### 5. General
For general system notifications
```javascript
{
  type: 'general'
}
```

## Priority Levels
- **critical**: Urgent notifications requiring immediate attention
- **high**: Important notifications
- **medium**: Normal notifications (default)
- **low**: Low-priority notifications

## Using the Notification Service

The `NotificationService` provides helper methods to create notifications from other modules:

### Project Notifications
```javascript
import NotificationService from '../notifications/notification.service.js';

await NotificationService.createProjectNotification(userId, {
  projectName: 'Project Alpha',
  projectStatus: 'active',
  projectId: project._id,
  action: 'assigned', // created|updated|completed|assigned|statusChanged
  details: 'Additional information'
});
```

### Task Notifications
```javascript
await NotificationService.createTaskNotification(userId, {
  taskTitle: 'Complete documentation',
  taskId: task._id,
  action: 'assigned', // created|assigned|updated|completed|dueToday|overdue
  dueDate: '2026-03-10',
  assignedBy: 'John Doe'
});
```

### Procurement Notifications
```javascript
await NotificationService.createProcurementNotification(userId, {
  itemName: 'Construction Materials',
  procurementId: procurement._id,
  action: 'shipped', // ordered|shipped|delivered|delayed|cancelled
  deliveryDate: '2026-03-15',
  supplier: 'ABC Suppliers'
});
```

### Meeting Notifications
```javascript
await NotificationService.createMeetingNotification(userId, {
  meetingTitle: 'Project Review',
  meetingId: meeting._id,
  action: 'reminder', // scheduled|updated|cancelled|reminder|started
  startTime: '2026-03-05 10:00',
  location: 'Conference Room A',
  organizer: 'Jane Smith'
});
```

### General Notifications
```javascript
await NotificationService.createGeneralNotification(userId, {
  title: 'System Update',
  message: 'The system will undergo maintenance tonight.',
  priority: 'high',
  metadata: { maintenanceTime: '22:00' }
});
```

### Bulk Notifications
```javascript
// Send notification to multiple users
await NotificationService.createBulkNotifications(
  [userId1, userId2, userId3],
  {
    title: 'Team Meeting',
    message: 'Mandatory team meeting tomorrow at 10 AM',
    type: 'meetings',
    priority: 'high'
  }
);
```

## Integration Examples

### From Task Controller
```javascript
// In tasks/tasks.controller.js
import NotificationService from '../notifications/notification.service.js';

export const createTask = async (req, res) => {
  // ... create task logic
  
  // Send notification to assigned user
  if (task.assignedTo) {
    await NotificationService.createTaskNotification(task.assignedTo, {
      taskTitle: task.title,
      taskId: task._id,
      action: 'assigned',
      dueDate: task.dueDate,
      assignedBy: req.user.name
    });
  }
  
  res.status(201).json(task);
};
```

### From Meeting Controller
```javascript
// In meetings/controllers/meetingController.js
import NotificationService from '../../notifications/notification.service.js';

export const createMeeting = async (req, res) => {
  // ... create meeting logic
  
  // Send notifications to all participants
  if (meeting.participants && meeting.participants.length > 0) {
    await NotificationService.createBulkNotifications(
      meeting.participants,
      {
        title: `Meeting Scheduled: ${meeting.title}`,
        message: `A meeting has been scheduled for ${meeting.startTime}`,
        type: 'meetings',
        priority: 'medium',
        meetingId: meeting._id
      }
    );
  }
  
  res.status(201).json(meeting);
};
```

## Database Schema

```javascript
{
  owner: ObjectId,              // User who owns the notification
  title: String,                // Notification title
  message: String,              // Notification message
  type: String,                 // projects|tasks|procurement|meetings|general
  priority: String,             // critical|high|medium|low
  isRead: Boolean,              // Read status
  projectName: String,          // Optional
  projectStatus: String,        // Optional
  projectId: ObjectId,          // Optional
  taskId: ObjectId,             // Optional
  meetingId: ObjectId,          // Optional
  procurementId: String,        // Optional
  metadata: Mixed,              // Optional additional data
  actionUrl: String,            // Optional action link
  createdAt: Date,              // Auto-generated
  updatedAt: Date               // Auto-generated
}
```

## Testing

Test all endpoints with curl:

```bash
# Get JWT token
TOKEN="your_jwt_token_here"

# Get all notifications
curl -H "Authorization: Bearer $TOKEN" http://localhost:5002/api/notifications

# Get unread notifications
curl -H "Authorization: Bearer $TOKEN" http://localhost:5002/api/notifications?isRead=false

# Get task notifications
curl -H "Authorization: Bearer $TOKEN" http://localhost:5002/api/notifications?type=tasks

# Create notification
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Test","message":"Test message","type":"general"}' \
  http://localhost:5002/api/notifications

# Mark as read
curl -X PATCH -H "Authorization: Bearer $TOKEN" \
  http://localhost:5002/api/notifications/NOTIFICATION_ID/read

# Get statistics
curl -H "Authorization: Bearer $TOKEN" http://localhost:5002/api/notifications/stats

# Delete notification
curl -X DELETE -H "Authorization: Bearer $TOKEN" \
  http://localhost:5002/api/notifications/NOTIFICATION_ID
```

## Cleanup

The service includes a cleanup function to delete old read notifications:

```javascript
import NotificationService from './notifications/notification.service.js';

// Delete read notifications older than 30 days
const deletedCount = await NotificationService.cleanupOldNotifications(30);
console.log(`Cleaned up ${deletedCount} old notifications`);
```

You can set up a cron job to run this periodically.

## Frontend Integration

Update your Flutter app's API service to match the new endpoint:

```dart
// In procurax_frontend/lib/services/api_service.dart
static const String notificationsEndpoint = '/api/notifications';

// Get notifications
Future<List<AlertModel>> getNotifications() async {
  final response = await get(notificationsEndpoint);
  // Parse response
}

// Mark as read
Future<void> markAsRead(String id) async {
  await patch('$notificationsEndpoint/$id/read');
}
```

## Notes

- All endpoints require JWT authentication
- Notifications are user-scoped (users only see their own)
- Supports filtering, pagination, and bulk operations
- Includes statistics endpoint for dashboard displays
- Extensible metadata field for custom data
- Indexed for efficient queries
