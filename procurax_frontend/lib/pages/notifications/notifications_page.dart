import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/theme/app_theme.dart' as theme;
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/services/api_service.dart';
import 'package:procurax_frontend/components/loading_state.dart';
import 'package:procurax_frontend/components/error_state.dart';
import 'package:procurax_frontend/components/empty_state.dart';
import 'providers/alert_provider.dart';
import 'models/alert_model.dart';
import 'utils/constants.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  AlertType? selectedType;

  @override
  void initState() {
    super.initState();
    if (ApiService.hasToken) {
      Future.microtask(
        () => context.read<AlertProvider>().fetchNotifications(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.notifications),
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Type filter chips
            _buildTypeFilter(),

            const SizedBox(height: 8),

            // Notifications list
            Expanded(
              child: Consumer<AlertProvider>(
                builder: (context, provider, _) {
                  // Loading state
                  if (provider.isLoading && provider.alerts.isEmpty) {
                    return const LoadingState(
                      message: 'Loading notifications...',
                    );
                  }

                  // Error state
                  if (provider.error != null && provider.alerts.isEmpty) {
                    return ErrorState(
                      message: 'Error loading notifications',
                      details: provider.error,
                      onRetry: () => provider.refresh(),
                    );
                  }

                  final alerts = provider.alerts
                      .where(
                        (a) => selectedType == null || a.type == selectedType,
                      )
                      .toList();

                  if (alerts.isEmpty) {
                    return EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: selectedType != null
                          ? 'No ${AlertConstants.getTypeLabel(selectedType!).toLowerCase()} notifications'
                          : 'No notifications yet',
                      subtitle: selectedType != null
                          ? 'Notifications for ${AlertConstants.getTypeLabel(selectedType!).toLowerCase()} will appear here'
                          : 'Create tasks, meetings, or notes to see notifications here',
                      actionLabel: 'Refresh',
                      onAction: () => provider.refresh(),
                    );
                  }

                  // Group alerts by date
                  final grouped = _groupAlertsByDate(alerts);

                  return RefreshIndicator(
                    color: theme.AppColors.primary,
                    onRefresh: () => provider.refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final group = grouped[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                              child: Text(
                                group.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            // Notifications in this group
                            ...group.alerts.map(
                              (alert) => _NotificationTile(
                                alert: alert,
                                onTap: () => provider.markAsRead(alert),
                                onDelete: () => provider.deleteAlert(alert),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final horizontal = theme.AppResponsive.pagePadding(context).horizontal / 2;
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Menu button on the left
          Align(
            alignment: Alignment.centerLeft,
            child: Builder(
              builder: (ctx) => IconButton(
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                icon: const Icon(
                  Icons.menu_rounded,
                  size: 28,
                  color: theme.AppColors.primary,
                ),
                tooltip: 'Open menu',
              ),
            ),
          ),
          // Centered title
          const Text(
            "Notifications",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.AppColors.primary,
              fontFamily: 'Poppins',
            ),
          ),
          // Unread count badge and mark-all-read button on the right
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<AlertProvider>(
                  builder: (context, provider, _) {
                    final unreadCount = provider.alerts
                        .where((a) => !a.isRead)
                        .length;
                    if (unreadCount == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount new',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.AppColors.primary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                // Mark all read button
                Consumer<AlertProvider>(
                  builder: (context, provider, _) {
                    final hasUnread = provider.alerts.any((a) => !a.isRead);
                    return IconButton(
                      onPressed: hasUnread
                          ? () =>
                                provider.markAllAsRead(type: selectedType?.name)
                          : null,
                      icon: Icon(
                        Icons.done_all_rounded,
                        color: hasUnread
                            ? theme.AppColors.primary
                            : Colors.grey.shade300,
                      ),
                      tooltip: 'Mark all as read',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            icon: Icons.all_inbox_rounded,
            isSelected: selectedType == null,
            color: theme.AppColors.primary,
            onTap: () => setState(() => selectedType = null),
          ),
          for (final type in AlertType.values)
            if (type != AlertType.general) // Hide general from filters
              _FilterChip(
                label: AlertConstants.getTypeLabel(type),
                icon: AppIcons.getIconForType(type),
                isSelected: selectedType == type,
                color: AlertConstants.getTypeColor(type),
                onTap: () => setState(() => selectedType = type),
              ),
        ],
      ),
    );
  }

  List<_DateGroup> _groupAlertsByDate(List<AlertModel> alerts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(Duration(days: today.weekday - 1));

    final todayAlerts = <AlertModel>[];
    final yesterdayAlerts = <AlertModel>[];
    final thisWeekAlerts = <AlertModel>[];
    final olderAlerts = <AlertModel>[];

    for (final alert in alerts) {
      final alertDate = DateTime(
        alert.timestamp.year,
        alert.timestamp.month,
        alert.timestamp.day,
      );

      if (alertDate == today) {
        todayAlerts.add(alert);
      } else if (alertDate == yesterday) {
        yesterdayAlerts.add(alert);
      } else if (alertDate.isAfter(thisWeek) || alertDate == thisWeek) {
        thisWeekAlerts.add(alert);
      } else {
        olderAlerts.add(alert);
      }
    }

    return [
      if (todayAlerts.isNotEmpty) _DateGroup('Today', todayAlerts),
      if (yesterdayAlerts.isNotEmpty) _DateGroup('Yesterday', yesterdayAlerts),
      if (thisWeekAlerts.isNotEmpty) _DateGroup('This Week', thisWeekAlerts),
      if (olderAlerts.isNotEmpty) _DateGroup('Earlier', olderAlerts),
    ];
  }
}

class _DateGroup {
  final String label;
  final List<AlertModel> alerts;
  _DateGroup(this.label, this.alerts);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isSelected ? Colors.white : color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : color,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _NotificationTile({required this.alert, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final typeColor = AlertConstants.getTypeColor(alert.type);
    final priorityColor = AlertConstants.getPriorityColor(alert.priority);

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) => _showDeleteConfirmation(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: alert.isRead ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: alert.isRead
                ? Colors.grey.shade200
                : typeColor.withOpacity(0.3),
            width: alert.isRead ? 1 : 1.5,
          ),
          boxShadow: alert.isRead
              ? []
              : [
                  BoxShadow(
                    color: typeColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AppIcons.getIconForType(alert.type),
                      color: typeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: alert.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: Colors.grey.shade900,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              alert.timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Bottom row: type badge + priority
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AlertConstants.getTypeLabel(alert.type),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: typeColor,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            if (alert.priority == AlertPriority.critical ||
                                alert.priority == AlertPriority.high) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      AppIcons.getIconForPriority(
                                        alert.priority,
                                      ),
                                      size: 10,
                                      color: priorityColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      alert.priority.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: priorityColor,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Unread indicator
                  if (!alert.isRead)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: typeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              onDelete?.call();
              Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
