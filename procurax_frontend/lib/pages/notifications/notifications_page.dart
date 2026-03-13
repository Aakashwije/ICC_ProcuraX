import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/theme/app_theme.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/services/api_service.dart';
import 'package:procurax_frontend/components/loading_state.dart';
import 'package:procurax_frontend/components/error_state.dart';
import 'package:procurax_frontend/components/empty_state.dart';
import 'providers/alert_provider.dart';
import 'widgets/alert_card.dart';
import 'widgets/alert_filter_chip.dart';
import 'models/alert_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  AlertType? selectedType;
  AlertPriority? selectedPriority;

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
    const Color primaryBlue = AppColors.primary;

    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.notifications),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        size: 30,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Filters
            AlertTypeFilter(
              selectedType: selectedType,
              onTypeSelected: (type) => setState(() => selectedType = type),
            ),
            AlertPriorityFilter(
              selectedPriority: selectedPriority,
              onPrioritySelected: (priority) =>
                  setState(() => selectedPriority = priority),
            ),

            // Alerts List
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
                        (a) =>
                            (selectedType == null || a.type == selectedType) &&
                            (selectedPriority == null ||
                                a.priority == selectedPriority),
                      )
                      .toList();

                  if (alerts.isEmpty) {
                    return EmptyState(
                      icon: Icons.notifications_none,
                      title: 'No notifications yet',
                      subtitle: 'New notifications will appear here',
                      actionLabel: 'Refresh',
                      onAction: () => provider.refresh(),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.refresh(),
                    child: ListView.builder(
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return AlertCard(
                          alert: alert,
                          onTap: () {
                            // Navigate to detail or mark as read
                            provider.markAsRead(alert);
                          },
                          onMarkRead: () => provider.markAsRead(alert),
                          onDelete: () => provider.deleteAlert(alert),
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
}
