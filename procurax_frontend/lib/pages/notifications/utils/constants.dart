import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;

  static const paddingMD = EdgeInsets.all(md);
}

class AppRadius {
  static final radiusSM = BorderRadius.circular(6);
  static final radiusMD = BorderRadius.circular(12);
}

class AppColors {
  static const unreadIndicator = Color(0xFF1F4DF0);

  static Color getColorForType(type) {
    switch (type) {
      case 0:
        return const Color(0xFF1F4DF0); // projects
      case 1:
        return Colors.orange; // tasks
      case 2:
        return Colors.green; // procurement
      case 3:
        return Colors.purple; // meetings
      case 4:
        return Colors.teal; // notes
      case 5:
        return const Color(0xFF00BCD4); // communication
      case 6:
        return Colors.grey; // general
      default:
        return Colors.black;
    }
  }

  static Color getColorForPriority(priority) {
    switch (priority) {
      case 0:
        return Colors.red; // critical
      case 1:
        return Colors.orange; // high
      case 2:
        return Colors.amber; // medium
      case 3:
        return Colors.green; // low
      default:
        return Colors.grey;
    }
  }
}

class AppIcons {
  static IconData getIconForType(AlertType type) {
    switch (type) {
      case AlertType.projects:
        return Icons.folder_rounded;
      case AlertType.tasks:
        return Icons.task_alt_rounded;
      case AlertType.procurement:
        return Icons.local_shipping_rounded;
      case AlertType.meetings:
        return Icons.event_rounded;
      case AlertType.notes:
        return Icons.note_alt_rounded;
      case AlertType.communication:
        return Icons.chat_bubble_rounded;
      case AlertType.general:
        return Icons.notifications_rounded;
    }
  }

  static IconData getIconForPriority(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.critical:
        return Icons.error_rounded;
      case AlertPriority.high:
        return Icons.warning_rounded;
      case AlertPriority.medium:
        return Icons.info_rounded;
      case AlertPriority.low:
        return Icons.arrow_downward_rounded;
    }
  }
}

class AlertConstants {
  static Color getTypeColor(AlertType type) {
    switch (type) {
      case AlertType.projects:
        return const Color(0xFF1F4DF0);
      case AlertType.tasks:
        return Colors.orange;
      case AlertType.procurement:
        return const Color(0xFF4CAF50);
      case AlertType.meetings:
        return const Color(0xFF9C27B0);
      case AlertType.notes:
        return const Color(0xFF009688);
      case AlertType.communication:
        return const Color(0xFF00BCD4);
      case AlertType.general:
        return Colors.grey;
    }
  }

  static Color getPriorityColor(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.critical:
        return const Color(0xFFF44336);
      case AlertPriority.high:
        return const Color(0xFFFF9800);
      case AlertPriority.medium:
        return const Color(0xFFFFC107);
      case AlertPriority.low:
        return const Color(0xFF4CAF50);
    }
  }

  static String getTypeLabel(AlertType type) {
    switch (type) {
      case AlertType.projects:
        return 'Projects';
      case AlertType.tasks:
        return 'Tasks';
      case AlertType.procurement:
        return 'Procurement';
      case AlertType.meetings:
        return 'Meetings';
      case AlertType.notes:
        return 'Notes';
      case AlertType.communication:
        return 'Messages';
      case AlertType.general:
        return 'General';
    }
  }
}
