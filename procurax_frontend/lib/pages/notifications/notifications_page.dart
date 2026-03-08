import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/services/api_service.dart';
import 'providers/alert_provider.dart';
import 'services/notification_api_service.dart';
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
    const Color primaryBlue = Color(0xFF1F4CCF);

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
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error state
                  if (provider.error != null && provider.alerts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Error loading notifications",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No notifications yet",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Debug info
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Debug Info:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'API: ${ApiService.baseUrl}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'Token: ${ApiService.hasToken ? "Present" : "Missing"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ApiService.hasToken
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                  ),
                                ),
                                Text(
                                  'User ID: ${ApiService.currentUserId ?? "Not set"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (provider.error != null)
                                  Text(
                                    'Last Error: ${provider.error}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => provider.refresh(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                          const SizedBox(height: 8),
                          // Manual test button
                          OutlinedButton.icon(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Testing API...')),
                              );
                              try {
                                final alerts =
                                    await NotificationApiService.fetchNotifications();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Success! Got ${alerts.length} notifications',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                provider.refresh();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Test API'),
                          ),
                        ],
                      ),
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
