import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
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
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => provider.refresh(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
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
