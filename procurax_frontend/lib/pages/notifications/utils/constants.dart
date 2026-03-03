import 'package:flutter/material.dart';

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
  static const unreadIndicator = Colors.blue;

  static Color getColorForType(type) {
    switch (type) {
      case 0:
        return Colors.blue; // projects
      case 1:
        return Colors.orange; // tasks
      case 2:
        return Colors.green; // procurement
      case 3:
        return Colors.purple; // meetings
      case 4:
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
        return Colors.yellow; // medium
      case 3:
        return Colors.green; // low
      default:
        return Colors.grey;
    }
  }
}

class AppIcons {
  static IconData getIconForType(type) => Icons.notifications;
  static IconData getIconForPriority(priority) => Icons.priority_high;
}
